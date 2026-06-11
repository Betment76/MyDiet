import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/premium_purchase_service.dart';
import 'package:my_diet/services/purchase_record_service.dart';
import 'package:my_diet/services/stage_purchase_service.dart';
import 'package:my_diet/services/stage_unlock_service.dart';
import 'package:my_diet/services/tbank_payment_service.dart';

class RestorePurchaseOutcome {
  final bool success;
  final String message;

  const RestorePurchaseOutcome({
    required this.success,
    required this.message,
  });
}

/// Проверка статусов оплат и откат разблокировок при возврате.
class PurchaseVerificationService {
  PurchaseVerificationService._();

  static const _successStatuses = {'CONFIRMED', 'AUTHORIZED'};
  static const _revokedStatuses = {
    'REFUNDED',
    'PARTIAL_REFUNDED',
    'REVERSED',
    'CANCELLED',
    'REJECTED',
    'AUTH_FAIL',
  };

  static bool isSuccessStatus(String? status) =>
      _successStatuses.contains(status?.toUpperCase());

  static bool isRevokedStatus(String? status) =>
      _revokedStatuses.contains(status?.toUpperCase());

  static final _recentVerify = <String, DateTime>{};
  static const _verifyCacheTtl = Duration(seconds: 45);

  /// Проверка перед открытием диеты или дня.
  /// Повторный вызов для той же методики в течение ~45 с не ходит в сеть.
  static Future<void> verifyBeforeAccess(String methodologyId) async {
    final last = _recentVerify[methodologyId];
    if (last != null &&
        DateTime.now().difference(last) < _verifyCacheTtl) {
      return;
    }
    await syncMethodologyAccess(methodologyId);
    _recentVerify[methodologyId] = DateTime.now();
  }

  /// Восстановить покупку по номеру заказа (Order ID).
  static Future<RestorePurchaseOutcome> restoreByOrderId(String rawOrderId) async {
    final orderId = rawOrderId.trim();
    if (orderId.isEmpty) {
      return const RestorePurchaseOutcome(
        success: false,
        message: 'Введите номер заказа',
      );
    }
    if (!TBankPaymentService.isConfigured) {
      return const RestorePurchaseOutcome(
        success: false,
        message: 'Восстановление недоступно: терминал не настроен',
      );
    }

    final paymentService = TBankPaymentService();
    final orderData = await paymentService.checkOrder(orderId);
    if (orderData['Success'] != true) {
      return RestorePurchaseOutcome(
        success: false,
        message: orderData['Message'] as String? ?? 'Заказ не найден',
      );
    }

    final status = (orderData['Status'] as String?)?.toUpperCase();
    if (isRevokedStatus(status)) {
      return const RestorePurchaseOutcome(
        success: false,
        message: 'Оплата по этому заказу отменена или возвращена',
      );
    }
    if (!isSuccessStatus(status)) {
      return const RestorePurchaseOutcome(
        success: false,
        message: 'Оплата по этому заказу ещё не подтверждена',
      );
    }

    final paymentId = orderData['PaymentId'] as String?;
    if (paymentId == null || paymentId.isEmpty) {
      return const RestorePurchaseOutcome(
        success: false,
        message: 'Не удалось получить данные платежа',
      );
    }

    var record = await PurchaseRecordService.findByOrderId(orderId);
    record ??= await _recordFromPaymentState(
      paymentService: paymentService,
      paymentId: paymentId,
      orderId: orderId,
    );

    if (record == null) {
      return const RestorePurchaseOutcome(
        success: false,
        message: 'Не удалось определить тип покупки по заказу',
      );
    }

    final resolvedPaymentId =
        record.paymentId.isNotEmpty ? record.paymentId : paymentId;
    var amountKopecks = record.amountKopecks;

    try {
      final state = await paymentService.getPaymentStatus(resolvedPaymentId);
      if (state['Success'] != true) {
        return const RestorePurchaseOutcome(
          success: false,
          message: 'Не удалось проверить статус платежа',
        );
      }
      final payStatus = (state['Status'] as String?)?.toUpperCase();
      if (isRevokedStatus(payStatus)) {
        return const RestorePurchaseOutcome(
          success: false,
          message: 'Оплата по этому заказу отменена или возвращена',
        );
      }
      if (!isSuccessStatus(payStatus)) {
        return const RestorePurchaseOutcome(
          success: false,
          message: 'Оплата по этому заказу ещё не подтверждена',
        );
      }
      final amount = state['Amount'];
      if (amount != null) {
        amountKopecks = (amount as num).toInt();
      }
    } catch (_) {
      return const RestorePurchaseOutcome(
        success: false,
        message: 'Ошибка связи с платёжным сервисом',
      );
    }

    final activeRecord = PurchaseRecord(
      paymentId: resolvedPaymentId,
      orderId: orderId,
      kind: record.kind,
      methodologyId: record.methodologyId,
      stageIndex: record.stageIndex,
      amountKopecks: amountKopecks,
    );
    await _applyPurchaseRecord(activeRecord);
    _recentVerify.clear();
    return const RestorePurchaseOutcome(
      success: true,
      message: 'Покупка восстановлена',
    );
  }

  static Future<PurchaseRecord?> _recordFromPaymentState({
    required TBankPaymentService paymentService,
    required String paymentId,
    required String orderId,
  }) async {
    try {
      final state = await paymentService.getPaymentStatus(paymentId);
      if (state['Success'] != true) return null;
      final amount = (state['Amount'] as num?)?.toInt();
      if (amount == null) return null;
      final description = state['Description'] as String? ?? '';

      if (amount == PremiumPurchaseService.allMethodologiesPriceRub * 100) {
        return PurchaseRecord(
          paymentId: paymentId,
          orderId: orderId,
          kind: PurchaseKind.allMethodologies,
          methodologyId: PremiumPurchaseService.allBundleId,
          amountKopecks: amount,
        );
      }

      if (amount == PremiumPurchaseService.methodologyPriceRub * 100) {
        final methodologyId = _methodologyIdFromDescription(description);
        if (methodologyId == null) return null;
        return PurchaseRecord(
          paymentId: paymentId,
          orderId: orderId,
          kind: PurchaseKind.premium,
          methodologyId: methodologyId,
          amountKopecks: amount,
        );
      }

      if (amount == StagePurchaseService.stagePriceRub * 100) {
        final parsed = _stageFromDescription(description);
        if (parsed == null) return null;
        return PurchaseRecord(
          paymentId: paymentId,
          orderId: orderId,
          kind: PurchaseKind.stage,
          methodologyId: parsed.$1,
          stageIndex: parsed.$2,
          amountKopecks: amount,
        );
      }
    } catch (_) {}
    return null;
  }

  static String? _methodologyIdFromDescription(String description) {
    for (final id in StageUnlockService.allMethodologyIds) {
      final config = MethodologyRegistry.get(id);
      if (description.contains(config.title)) return id;
    }
    return null;
  }

  static (String methodologyId, int stageIndex)? _stageFromDescription(
    String description,
  ) {
    for (final id in StageUnlockService.allMethodologyIds) {
      final config = MethodologyRegistry.get(id);
      for (var i = 0; i < config.stageCardNames.length; i++) {
        if (description.contains(config.stageCardNames[i])) {
          return (id, i);
        }
      }
    }
    return null;
  }

  static Future<void> _applyPurchaseRecord(PurchaseRecord record) async {
    await PurchaseRecordService.add(record);
    switch (record.kind) {
      case PurchaseKind.premium:
        await PremiumPurchaseService.completePurchase(record.methodologyId);
      case PurchaseKind.allMethodologies:
        await PremiumPurchaseService.completeAllPurchases();
      case PurchaseKind.stage:
        final stageIndex = record.stageIndex;
        if (stageIndex != null) {
          await StagePurchaseService.completePurchase(
            record.methodologyId,
            stageIndex,
          );
        }
    }
  }

  /// Проверить все методики. Возвращает число синхронизированных диет.
  static Future<int> verifyAndSyncPurchases() async {
    _recentVerify.clear();
    var count = 0;
    for (final id in StageUnlockService.allMethodologyIds) {
      final wasPremium = await StageUnlockService.isMethodologyFullyUnlocked(id);
      await syncMethodologyAccess(id);
      final isPremium = await StageUnlockService.isMethodologyFullyUnlocked(id);
      if (wasPremium != isPremium) count++;
    }
    return count;
  }

  /// Синхронизировать доступ с подтверждёнными платежами T‑Банка.
  /// Без успешной оплаты ПРЕМИУМ/этап закрываются; дни за рекламу не трогаем.
  static Future<void> syncMethodologyAccess(String methodologyId) async {
    var premiumConfirmed = false;
    final confirmedStages = <int>{};

    if (TBankPaymentService.isConfigured) {
      final paymentService = TBankPaymentService();
      final records = await PurchaseRecordService.loadAll();

      for (final record in records) {
        if (record.revoked) continue;

        final isBundle = record.kind == PurchaseKind.allMethodologies;
        final isForMethodology = record.methodologyId == methodologyId;
        if (!isBundle && !isForMethodology) continue;
        if (record.kind == PurchaseKind.stage && !isForMethodology) continue;

        try {
          final data = await paymentService.getPaymentStatus(record.paymentId);
          if (data['Success'] != true) continue;

          final status = data['Status'] as String?;
          final amount = data['Amount'];
          if (amount != null &&
              (amount as num).toInt() != record.amountKopecks) {
            continue;
          }

          if (isRevokedStatus(status)) {
            await PurchaseRecordService.markRevoked(record.paymentId);
            continue;
          }

          if (!isSuccessStatus(status)) continue;

          if (record.kind == PurchaseKind.premium && isForMethodology) {
            premiumConfirmed = true;
          }
          if (isBundle) premiumConfirmed = true;
          if (record.kind == PurchaseKind.stage && record.stageIndex != null) {
            confirmedStages.add(record.stageIndex!);
          }
        } catch (_) {}
      }
    } else {
      premiumConfirmed =
          await PurchaseRecordService.hasActivePremium(methodologyId) ||
              await PurchaseRecordService.hasActiveAllMethodologies();
      for (var i = 0; i < 3; i++) {
        if (await PurchaseRecordService.hasActiveStage(methodologyId, i)) {
          confirmedStages.add(i);
        }
      }
    }

    if (premiumConfirmed) {
      await PremiumPurchaseService.completePurchase(methodologyId);
      return;
    }

    await StageUnlockService.revokePremiumPurchase(methodologyId);

    for (var i = 0; i < 3; i++) {
      if (confirmedStages.contains(i)) {
        await StagePurchaseService.completePurchase(methodologyId, i);
      } else if (await StageUnlockService.hasStagePurchaseUnlock(
            methodologyId,
            i,
          )) {
        await StageUnlockService.revokeStagePurchase(methodologyId, i);
      }
    }
  }
}
