import 'package:my_diet/data/methodology_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранение и проверка открытых дней и этапов методики.
class StageUnlockService {
  StageUnlockService._();

  static String _maxDayKey(String methodologyId, int stageIndex) =>
      '${MethodologyRegistry.storagePrefix(methodologyId)}stage_${stageIndex}_max_unlocked_day';

  static String _adMaxDayKey(String methodologyId, int stageIndex) =>
      '${MethodologyRegistry.storagePrefix(methodologyId)}stage_${stageIndex}_ad_max_day';

  static String _stageAllKey(String methodologyId, int stageIndex) =>
      '${MethodologyRegistry.storagePrefix(methodologyId)}stage_${stageIndex}_all_unlocked';

  static String _methodologyPremiumKey(String methodologyId) =>
      '${MethodologyRegistry.storagePrefix(methodologyId)}premium_all_unlocked';

  static const allMethodologyIds = [
    MethodologyIds.express,
    MethodologyIds.gourmets,
    MethodologyIds.fun,
    MethodologyIds.men,
    MethodologyIds.victory,
  ];

  static Future<bool> isMethodologyFullyUnlocked(String methodologyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_methodologyPremiumKey(methodologyId)) ?? false;
  }

  static Future<bool> hasStagePurchaseUnlock(
    String methodologyId,
    int stageIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_stageAllKey(methodologyId, stageIndex)) ?? false;
  }

  static Future<void> unlockFullMethodology(String methodologyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_methodologyPremiumKey(methodologyId), true);
  }

  /// Отмена ПРЕМИУМ: снимаем флаг диеты и этапы без отдельной оплаты.
  /// Дни, открытые рекламой, не трогаем.
  static Future<void> revokePremiumPurchase(String methodologyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_methodologyPremiumKey(methodologyId), false);

    for (var i = 0; i < 3; i++) {
      await prefs.setBool(_stageAllKey(methodologyId, i), false);
      await prefs.remove(_maxDayKey(methodologyId, i));
    }
  }

  static Future<void> revokeStagePurchase(
    String methodologyId,
    int stageIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stageAllKey(methodologyId, stageIndex), false);
    await prefs.remove(_maxDayKey(methodologyId, stageIndex));
  }

  static Future<bool> isStageFullyUnlocked(
    String methodologyId,
    int stageIndex,
    int totalDays,
  ) async {
    if (await isMethodologyFullyUnlocked(methodologyId)) return true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_stageAllKey(methodologyId, stageIndex)) ?? false) {
      return true;
    }
    final adMax = await getAdMaxUnlockedDay(methodologyId, stageIndex);
    return adMax >= totalDays;
  }

  /// Этап 0 всегда доступен; следующие — когда открыты все дни предыдущего.
  static Future<bool> isStageUnlocked(
    String methodologyId,
    int stageIndex,
  ) async {
    if (stageIndex <= 0) return true;
    if (await isMethodologyFullyUnlocked(methodologyId)) return true;

    final prevIndex = stageIndex - 1;
    final prevDays = MethodologyRegistry.dayCount(methodologyId, prevIndex);
    return isStageFullyUnlocked(methodologyId, prevIndex, prevDays);
  }

  static Future<int> getAdMaxUnlockedDay(
    String methodologyId,
    int stageIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final adKey = _adMaxDayKey(methodologyId, stageIndex);
    if (prefs.containsKey(adKey)) {
      return prefs.getInt(adKey) ?? 1;
    }

    // Миграция: раньше реклама писала в max_unlocked_day.
    final premium = await isMethodologyFullyUnlocked(methodologyId);
    final stageAll = prefs.getBool(_stageAllKey(methodologyId, stageIndex)) ?? false;
    if (!premium && !stageAll) {
      final legacy = prefs.getInt(_maxDayKey(methodologyId, stageIndex)) ?? 1;
      await prefs.setInt(adKey, legacy);
      return legacy;
    }
    return 1;
  }

  static Future<int> getMaxUnlockedDay(
    String methodologyId,
    int stageIndex,
    int totalDays,
  ) async {
    if (await isMethodologyFullyUnlocked(methodologyId)) return totalDays;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_stageAllKey(methodologyId, stageIndex)) ?? false) {
      return totalDays;
    }
    final adMax = await getAdMaxUnlockedDay(methodologyId, stageIndex);
    return adMax.clamp(1, totalDays);
  }

  static Future<bool> isDayUnlocked(
    String methodologyId,
    int stageIndex,
    int dayNumber,
    int totalDays,
  ) async {
    if (!await isStageUnlocked(methodologyId, stageIndex)) return false;
    if (dayNumber <= 1) return true;
    final max = await getMaxUnlockedDay(methodologyId, stageIndex, totalDays);
    return dayNumber <= max;
  }

  /// Открыть один день после просмотра рекламы.
  static Future<void> unlockDay(
    String methodologyId,
    int stageIndex,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final adKey = _adMaxDayKey(methodologyId, stageIndex);
    final current = prefs.getInt(adKey) ?? 1;
    if (dayNumber > current) {
      await prefs.setInt(adKey, dayNumber);
    }
  }

  static Future<void> unlockAllDaysInStage(
    String methodologyId,
    int stageIndex,
    int totalDays,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stageAllKey(methodologyId, stageIndex), true);
    await prefs.setInt(_maxDayKey(methodologyId, stageIndex), totalDays);
  }

  static Future<List<bool>> loadStageUnlockStates(String methodologyId) async {
    final states = <bool>[];
    for (var i = 0; i < 3; i++) {
      states.add(await isStageUnlocked(methodologyId, i));
    }
    return states;
  }
}
