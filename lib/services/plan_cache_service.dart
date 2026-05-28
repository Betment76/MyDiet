// Сервис для кеширования меню всех этапов
// Каждый этап хранится отдельно по ключу stage_{index}

import 'dart:convert';

import 'package:my_diet/data/prep_plan_data.dart';
import 'package:my_diet/data/stage_meal_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanCacheService {
  /// Сохранить меню для этапа [stageIndex]
  static Future<void> save(int stageIndex, List<PrepDay> plan,
      List<String> restricted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _planKey(stageIndex),
        jsonEncode(plan.map((d) => d.toJson()).toList()));
    await prefs.setString(
        _hashKey(stageIndex), _hash(restricted));
  }

  /// Загрузить кеш для этапа, если хеш совпадает
  static Future<List<PrepDay>?> load(
      int stageIndex, List<String> currentRestricted) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_hashKey(stageIndex));
    if (storedHash != _hash(currentRestricted)) return null;

    final raw = prefs.getString(_planKey(stageIndex));
    if (raw == null || raw.isEmpty) return null;

    try {
      final list = (jsonDecode(raw) as List)
          .map((d) => PrepDay.fromJson(d as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return null;
    }
  }

  /// Получить количество дней для этапа
  static int dayCount(int stageIndex) => stagePlans[stageIndex].length;

  static Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 3; i++) {
      await prefs.remove(_planKey(i));
      await prefs.remove(_hashKey(i));
    }
  }

  static String _planKey(int i) => 'cached_plan_$i';
  static String _hashKey(int i) => 'restrict_hash_$i';
  static String _hash(List<String> list) {
    final sorted = List<String>.from(list)..sort();
    return sorted.join('|');
  }
}
