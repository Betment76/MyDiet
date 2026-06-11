import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/stage_unlock_service.dart';

/// Покупка этапа — открытие всех дней одного этапа методики.
class StagePurchaseService {
  StagePurchaseService._();

  static const int stagePriceRub = 69;

  static Future<bool> isPurchased(
    String methodologyId,
    int stageIndex,
  ) async {
    final totalDays = MethodologyRegistry.dayCount(methodologyId, stageIndex);
    return StageUnlockService.isStageFullyUnlocked(
      methodologyId,
      stageIndex,
      totalDays,
    );
  }

  /// Вызывать после успешной оплаты через T‑Банк.
  static Future<void> completePurchase(
    String methodologyId,
    int stageIndex,
  ) async {
    final totalDays = MethodologyRegistry.dayCount(methodologyId, stageIndex);
    await StageUnlockService.unlockAllDaysInStage(
      methodologyId,
      stageIndex,
      totalDays,
    );
  }
}
