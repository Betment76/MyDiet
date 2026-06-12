import 'package:flutter_test/flutter_test.dart';
import 'package:my_diet/data/meal_calories.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/data/prep_plan_data.dart';

void main() {
  test('fun prep day 1 — суточная норма 680 ккал', () {
    final plan = MethodologyRegistry.planFor(MethodologyIds.fun, 0);
    final day = plan.first;
    expect(
      MealCalories.dailyTotal(
        day.meals,
        methodologyId: MethodologyIds.fun,
        stageIndex: 0,
      ),
      680,
    );
  });

  test('fun main stage day — норма отличается от экспресса', () {
    final funMain = MethodologyRegistry.planFor(MethodologyIds.fun, 1).first;
    final expressMain =
        MethodologyRegistry.planFor(MethodologyIds.express, 1).first;

    final funTotal = MealCalories.dailyTotal(
      funMain.meals,
      methodologyId: MethodologyIds.fun,
      stageIndex: 1,
    );
    final expressTotal = MealCalories.dailyTotal(
      expressMain.meals,
      methodologyId: MethodologyIds.express,
      stageIndex: 1,
    );

    expect(funTotal, 1045);
    expect(expressTotal, greaterThan(1000));
    expect(funTotal, isNot(equals(expressTotal)));
  });

  test('men prep — один приём «Питание»', () {
    final day = MethodologyRegistry.planFor(MethodologyIds.men, 0).first;
    expect(
      MealCalories.dailyTotal(
        day.meals,
        methodologyId: MethodologyIds.men,
        stageIndex: 0,
      ),
      1250,
    );
  });

  test('PrepMeal.calories — только экспресс подготовительный', () {
    final meal = prepPlan.first.meals.first;
    expect(meal.calories, 250);
    expect(
      MealCalories.forMeal(
        meal,
        methodologyId: MethodologyIds.fun,
        stageIndex: 1,
      ),
      300,
    );
  });
}
