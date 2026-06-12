import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/purchase_record_service.dart';
import 'package:my_diet/services/stage_unlock_service.dart';
import 'package:my_diet/utils/ad_free_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Снимок флагов покупок и разблокировок для резервной копии.
class PurchaseBackupService {
  PurchaseBackupService._();

  static const flagsVersion = 1;

  static Future<Map<String, dynamic>> collectFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final premium = <String>[];
    final stages = <Map<String, dynamic>>[];
    final adDays = <Map<String, dynamic>>[];

    for (final id in StageUnlockService.allMethodologyIds) {
      if (await StageUnlockService.isMethodologyFullyUnlocked(id)) {
        premium.add(id);
      }

      for (var stageIndex = 0; stageIndex < 3; stageIndex++) {
        if (await StageUnlockService.hasStagePurchaseUnlock(id, stageIndex)) {
          stages.add({
            'methodology_id': id,
            'stage_index': stageIndex,
          });
        }

        final adMax = await StageUnlockService.getAdMaxUnlockedDay(
          id,
          stageIndex,
        );
        if (adMax > 1) {
          adDays.add({
            'methodology_id': id,
            'stage_index': stageIndex,
            'max_day': adMax,
          });
        }
      }
    }

    final records = await PurchaseRecordService.loadAll();

    return {
      'version': flagsVersion,
      'premium_methodologies': premium,
      'purchased_stages': stages,
      'ad_unlock_days': adDays,
      'ads_free': prefs.getBool(AdFreeNotifier.prefsKey) ?? false,
      'purchase_records': records.map((r) => r.toJson()).toList(),
    };
  }

  /// Применить флаги покупок после восстановления preferences.
  static Future<void> applyFlags(Map<String, dynamic> flags) async {
    await _resetPurchaseState();

    for (final raw in flags['premium_methodologies'] as List? ?? const []) {
      await StageUnlockService.unlockFullMethodology(raw as String);
    }

    for (final raw in flags['purchased_stages'] as List? ?? const []) {
      final entry = raw as Map<String, dynamic>;
      final methodologyId = entry['methodology_id'] as String;
      final stageIndex = _asInt(entry['stage_index']);
      if (stageIndex == null) continue;
      final totalDays = MethodologyRegistry.dayCount(methodologyId, stageIndex);
      await StageUnlockService.unlockAllDaysInStage(
        methodologyId,
        stageIndex,
        totalDays,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    for (final raw in flags['ad_unlock_days'] as List? ?? const []) {
      final entry = raw as Map<String, dynamic>;
      final methodologyId = entry['methodology_id'] as String;
      final stageIndex = _asInt(entry['stage_index']);
      final maxDay = _asInt(entry['max_day']);
      if (stageIndex == null || maxDay == null || maxDay <= 1) continue;

      final prefix = MethodologyRegistry.storagePrefix(methodologyId);
      await prefs.setInt(
        '${prefix}stage_${stageIndex}_ad_max_day',
        maxDay,
      );
    }

    final records = <PurchaseRecord>[];
    for (final raw in flags['purchase_records'] as List? ?? const []) {
      records.add(PurchaseRecord.fromJson(raw as Map<String, dynamic>));
    }
    await PurchaseRecordService.replaceAll(records);

    await AdFreeNotifier.set(flags['ads_free'] as bool? ?? false);
  }

  static Future<void> _resetPurchaseState() async {
    final prefs = await SharedPreferences.getInstance();

    for (final id in StageUnlockService.allMethodologyIds) {
      await StageUnlockService.revokePremiumPurchase(id);
      for (var stageIndex = 0; stageIndex < 3; stageIndex++) {
        await StageUnlockService.revokeStagePurchase(id, stageIndex);
        final prefix = MethodologyRegistry.storagePrefix(id);
        await prefs.remove('${prefix}stage_${stageIndex}_ad_max_day');
      }
    }

    await PurchaseRecordService.replaceAll(const []);
    await AdFreeNotifier.set(false);
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
