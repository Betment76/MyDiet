import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/stage_unlock_service.dart';

/// Покупка ПРЕМИУМ — полное открытие всех этапов и дней методики.
class PremiumPurchaseService {
  PremiumPurchaseService._();

  static const int methodologyPriceRub = 169;
  static const int allMethodologiesPriceRub = 569;
  static const allBundleId = 'all';

  static const _allMethodologyIds = [
    MethodologyIds.express,
    MethodologyIds.gourmets,
    MethodologyIds.fun,
    MethodologyIds.men,
    MethodologyIds.victory,
  ];

  static Future<bool> isPurchased(String methodologyId) =>
      StageUnlockService.isMethodologyFullyUnlocked(methodologyId);

  static Future<bool> isAllPurchased() async {
    for (final id in _allMethodologyIds) {
      if (!await isPurchased(id)) return false;
    }
    return true;
  }

  static Future<Set<String>> loadPurchasedIds() async {
    final purchased = <String>{};
    for (final id in _allMethodologyIds) {
      if (await isPurchased(id)) purchased.add(id);
    }
    return purchased;
  }

  /// Вызывать после успешной оплаты через T‑Банк.
  static Future<void> completePurchase(String methodologyId) async {
    await StageUnlockService.unlockFullMethodology(methodologyId);
  }

  static Future<void> completeAllPurchases() async {
    for (final id in _allMethodologyIds) {
      await completePurchase(id);
    }
  }
}
