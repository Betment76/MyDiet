// Генератор меню для всех этапов и методик

import 'package:my_diet/data/food_data.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/data/prep_plan_data.dart';

/// Все продукты, которые есть в нашей базе (приведены к нижнему регистру)
final Set<String> _allValid = allFoods
    .expand((cat) => cat.items)
    .map((s) => s.toLowerCase().trim())
    .toSet();

/// Сгенерировать меню для этапа с учётом запретов.
List<PrepDay> generateStagePlan(
  String methodologyId,
  int stageIndex,
  List<String> restricted,
) {
  final source = MethodologyRegistry.planFor(methodologyId, stageIndex);
  final banned = restricted.map((s) => s.toLowerCase().trim()).toSet();
  if (banned.isEmpty) return source;

  final Map<String, List<PrepMeal>> alternatives = {};
  for (final day in source) {
    for (final meal in day.meals) {
      alternatives.putIfAbsent(meal.name, () => []).add(meal);
    }
  }

  return source.map((day) {
    final meals = day.meals.map((meal) {
      final hasBanned = meal.ingredients.any(
        (ing) => banned.contains(ing.toLowerCase().trim()),
      );
      if (!hasBanned) return meal;

      final candidates = (alternatives[meal.name] ?? []).where((alt) {
        if (identical(alt, meal)) return false;
        final ings = alt.ingredients.map((s) => s.toLowerCase().trim());
        return ings.every((ing) => _allValid.contains(ing)) &&
            !ings.any((ing) => banned.contains(ing));
      }).toList();

      if (candidates.isNotEmpty) {
        return candidates[_randomIndex(candidates.length)];
      }

      return meal.copyWith(
        details: _cleanDescription(meal.details, restricted),
      );
    }).toList();

    return PrepDay(day: day.day, meals: meals);
  }).toList();
}

int _randomIndex(int max) => DateTime.now().microsecondsSinceEpoch % max;

String _cleanDescription(String desc, List<String> restricted) {
  String result = desc;
  for (final item in restricted) {
    result = result.replaceAll(
      RegExp(',?\\s*$item\\s*,?', caseSensitive: false),
      '',
    );
  }
  result = result
      .replaceAll(RegExp(r',\s*,+'), ',')
      .replaceAll(RegExp(r'^\s*,\s*'), '')
      .replaceAll(RegExp(r'\s*,\s*$'), '')
      .trim();
  return result;
}

/// Для обратной совместимости (экспресс, этап 0).
List<PrepDay> generatePrepPlan(List<String> restricted) =>
    generateStagePlan(MethodologyIds.express, 0, restricted);
