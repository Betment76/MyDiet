import 'package:flutter_test/flutter_test.dart';
import 'package:my_diet/data/stage_meal_data.dart';
import 'package:my_diet/services/meal_progress_service.dart';

void main() {
  final plan = stagePlans[0];
  final start = DateTime(2025, 5, 24);
  final may24 = DateTime(2025, 5, 24);
  final may29 = DateTime(2025, 5, 29);

  test('29 May: only day 2 breakfast → 1/6', () {
    final done = {
      MealProgressService.mealLogKey(0, may29, 2, 0),
    };
    final s = MealProgressService.summarizeForDate(
      done: done,
      stageIndex: 0,
      selectedDate: may29,
      plan: plan,
      stageStart: start,
    );
    expect(s.checked, 1);
    expect(s.totalMeals, 6);
    expect(s.totalCal, 250);
  });

  test('24 May: six day 1 marks → 6/6', () {
    final done = <String>{};
    for (var i = 0; i < 6; i++) {
      done.add(MealProgressService.mealLogKey(0, may24, 1, i));
    }
    final s = MealProgressService.summarizeForDate(
      done: done,
      stageIndex: 0,
      selectedDate: may24,
      plan: plan,
      stageStart: start,
    );
    expect(s.checked, 6);
    expect(s.totalMeals, 6);
    expect(s.totalCal, greaterThan(0));
  });

  test('29 May: p1 wrongly migrated + p2 breakfast → 1/6 (day 2 wins)', () {
    final done = <String>{};
    for (var i = 0; i < 6; i++) {
      done.add(MealProgressService.mealLogKey(0, may29, 1, i));
    }
    done.add(MealProgressService.mealLogKey(0, may29, 2, 0));
    final s = MealProgressService.summarizeForDate(
      done: done,
      stageIndex: 0,
      selectedDate: may29,
      plan: plan,
      stageStart: start,
    );
    expect(s.checked, 1);
    expect(s.totalCal, 250);
  });

  test('legacy day_0 on start 24 May → 6/6 on 24 May', () {
    final done = <String>{};
    for (var i = 0; i < 6; i++) {
      done.add(MealProgressService.legacyMealKey(0, 0, i));
    }
    final s = MealProgressService.summarizeForDate(
      done: done,
      stageIndex: 0,
      selectedDate: may24,
      plan: plan,
      stageStart: start,
    );
    expect(s.checked, 6);
  });

  test('countUniqueMealsCompleted ignores duplicate dates', () {
    final done = <String>{
      MealProgressService.mealLogKey(0, may24, 1, 0),
      MealProgressService.mealLogKey(0, may29, 1, 0),
      MealProgressService.mealLogKey(0, may29, 2, 0),
    };
    expect(MealProgressService.countUniqueMealsCompleted(0, done), 2);
  });
}
