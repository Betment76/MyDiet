import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/screens/payment_screen.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/premium_purchase_service.dart';
import 'package:my_diet/services/purchase_record_service.dart';
import 'package:my_diet/services/stage_purchase_service.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/services/tbank_payment_service.dart';

/// Запуск оплаты и разблокировка после успешного платежа.
class PaymentFlowService {
  PaymentFlowService._();

  static Future<bool> payForStageUnlock({
    required BuildContext context,
    required String methodologyId,
    required int stageIndex,
  }) async {
    if (await StagePurchaseService.isPurchased(methodologyId, stageIndex)) {
      return true;
    }

    final config = MethodologyRegistry.get(methodologyId);
    final stageName = config.stageCardNames[stageIndex];
    final amountKopecks = StagePurchaseService.stagePriceRub * 100;
    final description =
        'Открытие всех дней этапа «$stageName» в приложении Моя диета';

    if (!context.mounted) return false;

    final payment = await _runPayment(
      context: context,
      amountKopecks: amountKopecks,
      description: description,
      receiptItemName: description,
      screenTitle: 'Оплата этапа',
      productId: 'stage_${methodologyId}_$stageIndex',
      purchaseKind: 'stage',
      methodologyId: methodologyId,
      stageIndex: stageIndex,
    );

    if (payment == null) return false;

    await PurchaseRecordService.add(
      PurchaseRecord(
        paymentId: payment.paymentId,
        orderId: payment.orderId,
        kind: PurchaseKind.stage,
        methodologyId: methodologyId,
        stageIndex: stageIndex,
        amountKopecks: amountKopecks,
      ),
    );
    await StagePurchaseService.completePurchase(methodologyId, stageIndex);
    return true;
  }

  static Future<bool> payForMethodologyPremium({
    required BuildContext context,
    required String methodologyId,
  }) async {
    if (await PremiumPurchaseService.isPurchased(methodologyId)) {
      return true;
    }

    final config = MethodologyRegistry.get(methodologyId);
    final amountKopecks = PremiumPurchaseService.methodologyPriceRub * 100;
    final description =
        'Открытие всех этапов «${config.title}» в приложении Моя диета';

    if (!context.mounted) return false;

    final payment = await _runPayment(
      context: context,
      amountKopecks: amountKopecks,
      description: description,
      receiptItemName: description,
      screenTitle: 'Оплата ПРЕМИУМ',
      productId: 'premium_$methodologyId',
      purchaseKind: 'premium',
      methodologyId: methodologyId,
    );

    if (payment == null) return false;

    await PurchaseRecordService.add(
      PurchaseRecord(
        paymentId: payment.paymentId,
        orderId: payment.orderId,
        kind: PurchaseKind.premium,
        methodologyId: methodologyId,
        amountKopecks: amountKopecks,
      ),
    );
    await PremiumPurchaseService.completePurchase(methodologyId);
    return true;
  }

  static Future<bool> payForAllMethodologiesPremium({
    required BuildContext context,
  }) async {
    if (await PremiumPurchaseService.isAllPurchased()) {
      return true;
    }

    final amountKopecks = PremiumPurchaseService.allMethodologiesPriceRub * 100;
    const description =
        'Открытие всех диет в приложении Моя диета';

    if (!context.mounted) return false;

    final payment = await _runPayment(
      context: context,
      amountKopecks: amountKopecks,
      description: description,
      receiptItemName: description,
      screenTitle: 'Оплата всех диет',
      productId: 'premium_all',
      purchaseKind: 'all_methodologies',
    );

    if (payment == null) return false;

    await PurchaseRecordService.add(
      PurchaseRecord(
        paymentId: payment.paymentId,
        orderId: payment.orderId,
        kind: PurchaseKind.allMethodologies,
        methodologyId: PremiumPurchaseService.allBundleId,
        amountKopecks: amountKopecks,
      ),
    );
    await PremiumPurchaseService.completeAllPurchases();
    return true;
  }

  static Future<({String paymentId, String orderId})?> _runPayment({
    required BuildContext context,
    required int amountKopecks,
    required String description,
    required String receiptItemName,
    required String screenTitle,
    required String productId,
    required String purchaseKind,
    String? methodologyId,
    int? stageIndex,
  }) async {
    if (!TBankPaymentService.isConfigured) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Оплата временно недоступна: терминал не настроен'),
          ),
        );
      }
      return null;
    }

    final receiptEmail = await ProfileService.getReceiptEmailForPayment();

    try {
      await AppMetricaService.reportPaymentStarted(
        productId: productId,
        purchaseKind: purchaseKind,
        amountKopecks: amountKopecks,
        methodologyId: methodologyId,
        stageIndex: stageIndex,
      );

      final paymentService = TBankPaymentService();
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      final paymentData = await paymentService.initiatePayment(
        amount: amountKopecks,
        orderId: orderId,
        description: description,
        receiptItemName: receiptItemName,
        email: receiptEmail,
      );

      final paymentId = paymentData['PaymentId'] as String;
      await paymentService.setLastPaymentId(paymentId);

      var urlToOpen = paymentData['PaymentURL'] as String;
      if (!kDebugMode) {
        try {
          final qrPayload = await paymentService.getQrPayload(paymentId);
          if (qrPayload != null && qrPayload.isNotEmpty) {
            urlToOpen = qrPayload;
          }
        } catch (_) {}
      }

      if (!context.mounted) return null;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/payment'),
          builder: (_) => PaymentScreen(
            paymentUrl: urlToOpen,
            paymentId: paymentId,
            orderId: orderId,
            amountKopecks: amountKopecks,
            title: screenTitle,
          ),
        ),
      );

      if (result == true) {
        await AppMetricaService.reportPaymentSuccess(
          productId: productId,
          purchaseKind: purchaseKind,
          amountKopecks: amountKopecks,
          orderId: orderId,
          paymentId: paymentId,
          methodologyId: methodologyId,
          stageIndex: stageIndex,
        );
        return (paymentId: paymentId, orderId: orderId);
      }

      final recovered = await _tryRecoverPaymentAfterClose(paymentService);
      if (recovered) {
        await AppMetricaService.reportPaymentSuccess(
          productId: productId,
          purchaseKind: purchaseKind,
          amountKopecks: amountKopecks,
          orderId: orderId,
          paymentId: paymentId,
          methodologyId: methodologyId,
          stageIndex: stageIndex,
        );
        return (paymentId: paymentId, orderId: orderId);
      }

      await AppMetricaService.reportPaymentCancelled(
        productId: productId,
        purchaseKind: purchaseKind,
      );
      return null;
    } catch (e) {
      await AppMetricaService.reportPaymentFailed(
        productId: productId,
        purchaseKind: purchaseKind,
        error: e,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка оплаты: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  static Future<bool> _tryRecoverPaymentAfterClose(
    TBankPaymentService paymentService,
  ) async {
    return paymentService.checkLastPaymentStatus();
  }
}
