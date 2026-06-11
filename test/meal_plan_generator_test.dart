import 'package:flutter_test/flutter_test.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/meal_plan_generator.dart';

void main() {
  group('MealPlanGenerator', () {
    test('generateStagePlan returns plan for express stage 0', () {
      final plan = generateStagePlan(MethodologyIds.express, 0, []);
      expect(plan, isNotEmpty);
      expect(plan.first.day, 1);
      expect(plan.first.meals, isNotEmpty);
    });

    test('generateStagePlan returns plan for victory stage 0', () {
      final plan = generateStagePlan(MethodologyIds.victory, 0, []);
      expect(plan, isNotEmpty);
    });

    test('generateStagePlan returns plan for men stage 1', () {
      final plan = generateStagePlan(MethodologyIds.men, 1, []);
      expect(plan, isNotEmpty);
    });

    test('generateStagePlan returns plan for gourmets stage 2', () {
      final plan = generateStagePlan(MethodologyIds.gourmets, 2, []);
      expect(plan, isNotEmpty);
    });

    test('generateStagePlan with empty restrictions — same as source', () {
      final source = MethodologyRegistry.planFor(MethodologyIds.express, 0);
      final generated = generateStagePlan(MethodologyIds.express, 0, []);
      expect(generated.length, source.length);
      for (var i = 0; i < generated.length; i++) {
        expect(generated[i].day, source[i].day);
        expect(generated[i].meals.length, source[i].meals.length);
      }
    });

    test('generateStagePlan with restriction — replaces banned ingredients', () {
      // Запрещаем овсянку — она должна исчезнуть из описания
      final plan = generateStagePlan(MethodologyIds.express, 0, ['овсянка']);
      bool hasOatmeal = false;
      for (final day in plan) {
        for (final meal in day.meals) {
          if (meal.details.toLowerCase().contains('овсянка')) {
            hasOatmeal = true;
          }
        }
      }
      expect(hasOatmeal, false);
    });

    test('generateStagePlan with non-existent restriction — no change', () {
      final source = MethodologyRegistry.planFor(MethodologyIds.express, 0);
      final generated = generateStagePlan(
        MethodologyIds.express,
        0,
        ['нетипичный_продукт_который_не_встречается'],
      );
      expect(generated.length, source.length);
    });

    test('generateStagePlan for invalid stage index — returns empty', () {
      final plan = generateStagePlan(MethodologyIds.express, 999, []);
      expect(plan, isEmpty);
    });

    test('generateStagePlan for invalid methodology — returns express plan', () {
      // MethodologyRegistry.get() возвращает express по умолчанию
      final plan = generateStagePlan('unknown_methodology', 0, []);
      expect(plan, isNotEmpty);
    });

    test('generateStagePlan — case insensitive restriction', () {
      final plan1 = generateStagePlan(MethodologyIds.express, 0, ['ОВСЯНКА']);
      final plan2 = generateStagePlan(MethodologyIds.express, 0, ['овсянка']);
      final plan3 = generateStagePlan(MethodologyIds.express, 0, ['Овсянка']);

      bool hasOatmeal(String planStr) =>
          planStr.toLowerCase().contains('овсянка');

      final str1 = plan1.toString();
      final str2 = plan2.toString();
      final str3 = plan3.toString();

      expect(hasOatmeal(str1), false);
      expect(hasOatmeal(str2), false);
      expect(hasOatmeal(str3), false);
    });

    test('generatePrepPlan is alias for express stage 0', () {
      final prepPlan = generatePrepPlan([]);
      final stagePlan = generateStagePlan(MethodologyIds.express, 0, []);
      expect(prepPlan.length, stagePlan.length);
    });
  });

  group('MethodologyRegistry', () {
    test('get returns correct config for each id', () {
      expect(MethodologyRegistry.get(MethodologyIds.express).id, MethodologyIds.express);
      expect(MethodologyRegistry.get(MethodologyIds.gourmets).id, MethodologyIds.gourmets);
      expect(MethodologyRegistry.get(MethodologyIds.fun).id, MethodologyIds.fun);
      expect(MethodologyRegistry.get(MethodologyIds.men).id, MethodologyIds.men);
      expect(MethodologyRegistry.get(MethodologyIds.victory).id, MethodologyIds.victory);
    });

    test('get returns express as default for unknown id', () {
      final config = MethodologyRegistry.get('unknown_id');
      expect(config.id, MethodologyIds.express);
    });

    test('planFor returns correct plans for each methodology', () {
      for (final id in [
        MethodologyIds.express,
        MethodologyIds.gourmets,
        MethodologyIds.fun,
        MethodologyIds.men,
        MethodologyIds.victory,
      ]) {
        final config = MethodologyRegistry.get(id);
        for (var i = 0; i < config.plans.length; i++) {
          final plan = MethodologyRegistry.planFor(id, i);
          expect(plan, isNotEmpty, reason: 'Plan for $id stage $i should not be empty');
        }
      }
    });

    test('dayCount returns correct number for express stage 0', () {
      final count = MethodologyRegistry.dayCount(MethodologyIds.express, 0);
      expect(count, greaterThan(0));
      final plan = MethodologyRegistry.planFor(MethodologyIds.express, 0);
      expect(count, plan.length);
    });

    test('storagePrefix — express has no prefix', () {
      expect(MethodologyRegistry.storagePrefix(MethodologyIds.express), '');
    });

    test('storagePrefix — other methodologies have prefix with underscore', () {
      expect(MethodologyRegistry.storagePrefix(MethodologyIds.gourmets),
          '${MethodologyIds.gourmets}_');
      expect(MethodologyRegistry.storagePrefix(MethodologyIds.fun), '${MethodologyIds.fun}_');
      expect(MethodologyRegistry.storagePrefix(MethodologyIds.men), '${MethodologyIds.men}_');
      expect(MethodologyRegistry.storagePrefix(MethodologyIds.victory),
          '${MethodologyIds.victory}_');
    });
  });
}