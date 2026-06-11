import 'dart:convert';

import 'package:my_diet/data/meal_calories.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/data/prep_plan_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Отметки: календарный день, когда отметили + номер дня плана.
class MealProgressService {
  MealProgressService._();

  static String dateKey(DateTime date) {
    final d = normalizeDate(date);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _scope(String methodologyId) =>
      MethodologyRegistry.storagePrefix(methodologyId);

  static String mealLogKey(
    int stageIndex,
    DateTime logDate,
    int planDay,
    int mealIndex, {
    String methodologyId = MethodologyIds.express,
  }) =>
      '${_scope(methodologyId)}stage${stageIndex}_${dateKey(logDate)}_p${planDay}_meal_$mealIndex';

  static String legacyMealKey(
    int stageIndex,
    int planDayIndex,
    int mealIndex, {
    String methodologyId = MethodologyIds.express,
  }) =>
      '${_scope(methodologyId)}stage${stageIndex}_day_${planDayIndex}_meal_$mealIndex';

  static String _storageKey(
    String methodologyId,
    int stageIndex,
  ) {
    final p = _scope(methodologyId);
    return p.isEmpty
        ? 'stage_${stageIndex}_progress'
        : '${p}stage_${stageIndex}_progress';
  }

  static RegExp _legacyKeyRe(String methodologyId) => RegExp(
        '^${_scope(methodologyId)}stage(\\d+)_day_(\\d+)_meal_(\\d+)\$',
      );

  static RegExp _logKeyRe(String methodologyId) => RegExp(
        '^${_scope(methodologyId)}stage(\\d+)_(\\d{4}-\\d{2}-\\d{2})_p(\\d+)_meal_(\\d+)\$',
      );

  static RegExp _dateOnlyKeyRe(String methodologyId) => RegExp(
        '^${_scope(methodologyId)}stage(\\d+)_(\\d{4}-\\d{2}-\\d{2})_meal_(\\d+)\$',
      );

  static final _prepKeyRe = RegExp(r'^day_(\d+)_meal_(\d+)$');

  static Future<Set<String>> loadDone(
    int stageIndex, {
    String methodologyId = MethodologyIds.express,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (methodologyId == MethodologyIds.express && stageIndex == 0) {
      await _migratePrepProgress(prefs);
    }
    final stored = prefs.getString(_storageKey(methodologyId, stageIndex));
    if (stored == null || stored.isEmpty) return {};
    try {
      return Set<String>.from(List<String>.from(jsonDecode(stored)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveDone(
    int stageIndex,
    Set<String> done, {
    String methodologyId = MethodologyIds.express,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(methodologyId, stageIndex),
      jsonEncode(done.toList()),
    );
  }

  /// Перенос старого prep_progress → stage_0_progress (legacy-ключи).
  static Future<void> _migratePrepProgress(SharedPreferences prefs) async {
    final prep = prefs.getString('prep_progress');
    if (prep == null || prep.isEmpty) return;

    Set<String> done = {};
    final stored = prefs.getString(_storageKey(MethodologyIds.express, 0));
    if (stored != null && stored.isNotEmpty) {
      try {
        done = Set<String>.from(List<String>.from(jsonDecode(stored)));
      } catch (_) {}
    }

    try {
      final list = List<String>.from(jsonDecode(prep));
      var changed = false;
      for (final k in list) {
        final m = _prepKeyRe.firstMatch(k);
        if (m == null) continue;
        final legacy = legacyMealKey(
          0,
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
        );
        if (!done.contains(legacy)) {
          done.add(legacy);
          changed = true;
        }
      }
      if (changed) {
        await prefs.setString(
          _storageKey(MethodologyIds.express, 0),
          jsonEncode(done.toList()),
        );
      }
      await prefs.remove('prep_progress');
    } catch (_) {}
  }

  static int countUniqueMealsCompleted(
    int stageIndex,
    Set<String> done, {
    String methodologyId = MethodologyIds.express,
  }) {
    final slots = <String>{};
    final logRe = _logKeyRe(methodologyId);
    final legacyRe = _legacyKeyRe(methodologyId);
    final dateRe = _dateOnlyKeyRe(methodologyId);

    for (final k in done) {
      final log = logRe.firstMatch(k);
      if (log != null && int.parse(log.group(1)!) == stageIndex) {
        slots.add('${log.group(3)}_${log.group(4)}');
        continue;
      }
      final legacy = legacyRe.firstMatch(k);
      if (legacy != null && int.parse(legacy.group(1)!) == stageIndex) {
        slots.add('${int.parse(legacy.group(2)!) + 1}_${legacy.group(3)}');
        continue;
      }
      final simple = dateRe.firstMatch(k);
      if (simple != null && int.parse(simple.group(1)!) == stageIndex) {
        slots.add('1_${simple.group(3)}');
      }
    }

    return slots.length;
  }

  static PrepDay? planDayByNumber(List<PrepDay> plan, int planDay) {
    for (final d in plan) {
      if (d.day == planDay) return d;
    }
    return null;
  }

  static DateTime? inferStageStartFromProgress(
    int stageIndex,
    Set<String> done, {
    String methodologyId = MethodologyIds.express,
  }) {
    DateTime? earliest;
    final logRe = _logKeyRe(methodologyId);

    for (final k in done) {
      final log = logRe.firstMatch(k);
      if (log == null || int.parse(log.group(1)!) != stageIndex) continue;
      if (int.parse(log.group(3)!) != 1) continue;
      final d = DateTime.parse(log.group(2)!);
      if (earliest == null || d.isBefore(earliest)) earliest = d;
    }

    return earliest;
  }

  static Map<int, Set<int>> marksOnLogDate({
    required Set<String> done,
    required int stageIndex,
    required DateTime logDate,
    DateTime? stageStart,
    String methodologyId = MethodologyIds.express,
  }) {
    final marks = <int, Set<int>>{};
    final dk = dateKey(logDate);
    final logRe = _logKeyRe(methodologyId);
    final legacyRe = _legacyKeyRe(methodologyId);
    final dateRe = _dateOnlyKeyRe(methodologyId);

    for (final k in done) {
      final log = logRe.firstMatch(k);
      if (log != null &&
          int.parse(log.group(1)!) == stageIndex &&
          log.group(2) == dk) {
        final planDay = int.parse(log.group(3)!);
        marks.putIfAbsent(planDay, () => {}).add(int.parse(log.group(4)!));
      }
    }
    if (marks.isNotEmpty) return marks;

    if (stageStart != null) {
      final idx =
          normalizeDate(logDate).difference(normalizeDate(stageStart)).inDays;
      if (idx >= 0) {
        final planDay = idx + 1;
        for (final k in done) {
          final legacy = legacyRe.firstMatch(k);
          if (legacy == null ||
              int.parse(legacy.group(1)!) != stageIndex ||
              int.parse(legacy.group(2)!) != idx) {
            continue;
          }
          marks
              .putIfAbsent(planDay, () => {})
              .add(int.parse(legacy.group(3)!));
        }
        if (marks.isNotEmpty) return marks;
      }
    }

    for (final k in done) {
      final simple = dateRe.firstMatch(k);
      if (simple != null &&
          int.parse(simple.group(1)!) == stageIndex &&
          simple.group(2) == dk) {
        marks.putIfAbsent(1, () => {}).add(int.parse(simple.group(3)!));
      }
    }

    return marks;
  }

  static int _primaryPlanDay(Map<int, Set<int>> marks) {
    if (marks.isEmpty) return 0;
    return marks.keys.reduce((a, b) => a > b ? a : b);
  }

  static ({int checked, int totalMeals, int totalCal}) summarizeForDate({
    required Set<String> done,
    required int stageIndex,
    required DateTime selectedDate,
    required List<PrepDay> plan,
    DateTime? stageStart,
    String methodologyId = MethodologyIds.express,
  }) {
    final marks = marksOnLogDate(
      done: done,
      stageIndex: stageIndex,
      logDate: selectedDate,
      stageStart: stageStart,
      methodologyId: methodologyId,
    );

    if (marks.isEmpty) {
      return (checked: 0, totalMeals: 0, totalCal: 0);
    }

    final planDayNum = _primaryPlanDay(marks);
    final planDay = planDayByNumber(plan, planDayNum);
    if (planDay == null) {
      return (checked: 0, totalMeals: 0, totalCal: 0);
    }

    final indices = marks[planDayNum] ?? {};
    var checked = 0;
    var totalCal = 0;

    for (final mi in indices) {
      if (mi >= 0 && mi < planDay.meals.length) {
        checked++;
        totalCal += MealCalories.forMeal(
          planDay.meals[mi],
          methodologyId: methodologyId,
          stageIndex: stageIndex,
        );
      }
    }

    return (checked: checked, totalMeals: planDay.meals.length, totalCal: totalCal);
  }

  static bool isPlanMealMarked(
    Set<String> done,
    int stageIndex,
    int planDay,
    int mealIndex, {
    String methodologyId = MethodologyIds.express,
  }) {
    final scope = _scope(methodologyId);
    final suffix = '_p${planDay}_meal_$mealIndex';
    for (final k in done) {
      if (k.startsWith('${scope}stage${stageIndex}_') && k.endsWith(suffix)) {
        return true;
      }
    }
    return done.contains(
      legacyMealKey(stageIndex, planDay - 1, mealIndex,
          methodologyId: methodologyId),
    );
  }

  static String todayLogKey(
    int stageIndex,
    int planDay,
    int mealIndex, {
    String methodologyId = MethodologyIds.express,
  }) =>
      mealLogKey(
        stageIndex,
        normalizeDate(DateTime.now()),
        planDay,
        mealIndex,
        methodologyId: methodologyId,
      );

  static Future<Set<String>> convertLegacyToDatedKeys(
    int stageIndex,
    Set<String> done,
    DateTime stageStart, {
    String methodologyId = MethodologyIds.express,
  }) async {
    final start = normalizeDate(stageStart);
    var changed = false;
    final legacyRe = _legacyKeyRe(methodologyId);

    for (final k in done.toList()) {
      final m = legacyRe.firstMatch(k);
      if (m == null || int.parse(m.group(1)!) != stageIndex) continue;

      final idx = int.parse(m.group(2)!);
      final mi = int.parse(m.group(3)!);
      final newKey = mealLogKey(
        stageIndex,
        start.add(Duration(days: idx)),
        idx + 1,
        mi,
        methodologyId: methodologyId,
      );
      done.remove(k);
      if (!done.contains(newKey)) done.add(newKey);
      changed = true;
    }

    if (changed) {
      await saveDone(stageIndex, done, methodologyId: methodologyId);
    }
    return done;
  }

  static Future<Set<String>> repairMisplacedPlanDay1({
    required int stageIndex,
    required Set<String> done,
    required DateTime stageStart,
    String methodologyId = MethodologyIds.express,
  }) async {
    final start = normalizeDate(stageStart);
    final startKey = dateKey(start);
    final hasOnStart = done.any((k) => k.contains('_${startKey}_p1_'));
    if (hasOnStart) return done;

    final wrongDateMeals = <String, Set<int>>{};
    final logRe = _logKeyRe(methodologyId);

    for (final k in done) {
      final m = logRe.firstMatch(k);
      if (m == null || int.parse(m.group(1)!) != stageIndex) continue;
      if (int.parse(m.group(3)!) != 1 || m.group(2) == startKey) continue;
      wrongDateMeals
          .putIfAbsent(m.group(2)!, () => {})
          .add(int.parse(m.group(4)!));
    }

    for (final entry in wrongDateMeals.entries) {
      if (entry.value.length < 4) continue;
      var changed = false;
      for (final mi in entry.value) {
        done.remove(mealLogKey(
          stageIndex,
          DateTime.parse(entry.key),
          1,
          mi,
          methodologyId: methodologyId,
        ));
        done.add(mealLogKey(stageIndex, start, 1, mi,
            methodologyId: methodologyId));
        changed = true;
      }
      if (changed) {
        await saveDone(stageIndex, done, methodologyId: methodologyId);
        break;
      }
    }
    return done;
  }

  static Future<Set<String>> togglePlanMeal({
    required Set<String> done,
    required int stageIndex,
    required int planDay,
    required int mealIndex,
    String methodologyId = MethodologyIds.express,
  }) async {
    final copy = Set<String>.from(done);
    final todayKey = todayLogKey(stageIndex, planDay, mealIndex,
        methodologyId: methodologyId);
    final suffix = '_p${planDay}_meal_$mealIndex';

    if (copy.contains(todayKey)) {
      copy.remove(todayKey);
    } else if (copy.any((k) => k.endsWith(suffix))) {
      copy.removeWhere((k) => k.endsWith(suffix));
    } else {
      copy.remove(legacyMealKey(stageIndex, planDay - 1, mealIndex,
          methodologyId: methodologyId));
      copy.add(todayKey);
    }

    await saveDone(stageIndex, copy, methodologyId: methodologyId);
    return copy;
  }
}
