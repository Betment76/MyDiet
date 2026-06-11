// Сервис для кеширования меню всех этапов и методик

import 'dart:convert';

import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/data/prep_plan_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanCacheService {
  /// Сохранить меню для этапа [stageIndex] методики [methodologyId].
  static Future<void> save(
    String methodologyId,
    int stageIndex,
    List<PrepDay> plan,
    List<String> restricted,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _planKey(methodologyId, stageIndex),
      jsonEncode(plan.map((d) => d.toJson()).toList()),
    );
    await prefs.setString(
      _hashKey(methodologyId, stageIndex),
      _hash(restricted),
    );
  }

  /// Загрузить кеш для этапа, если хеш совпадает.
  static Future<List<PrepDay>?> load(
    String methodologyId,
    int stageIndex,
    List<String> currentRestricted,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_hashKey(methodologyId, stageIndex));
    if (storedHash != _hash(currentRestricted)) return null;

    final raw = prefs.getString(_planKey(methodologyId, stageIndex));
    if (raw == null || raw.isEmpty) return null;

    try {
      return (jsonDecode(raw) as List)
          .map((d) => PrepDay.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static int dayCount(String methodologyId, int stageIndex) =>
      MethodologyRegistry.dayCount(methodologyId, stageIndex);

  static Future<void> invalidate({String? methodologyId}) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = methodologyId != null
        ? [methodologyId]
        : [MethodologyIds.express, MethodologyIds.gourmets, MethodologyIds.fun, MethodologyIds.men, MethodologyIds.victory];
    for (final id in ids) {
      for (var i = 0; i < 3; i++) {
        await prefs.remove(_planKey(id, i));
        await prefs.remove(_hashKey(id, i));
      }
    }
  }

  static String _planKey(String methodologyId, int i) {
    final p = MethodologyRegistry.storagePrefix(methodologyId);
    final v = methodologyId == MethodologyIds.men ? '_v3' : '';
    return p.isEmpty ? 'cached_plan_$i$v' : '${p}cached_plan_$i$v';
  }

  static String _hashKey(String methodologyId, int i) {
    final p = MethodologyRegistry.storagePrefix(methodologyId);
    final v = methodologyId == MethodologyIds.men ? '_v3' : '';
    return p.isEmpty ? 'restrict_hash_$i$v' : '${p}restrict_hash_$i$v';
  }

  static String _hash(List<String> list) {
    final sorted = List<String>.from(list)..sort();
    return sorted.join('|');
  }
}
