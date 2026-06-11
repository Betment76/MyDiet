import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/data/prep_plan_data.dart';

/// Примерная калорийность приёма по меню выбранной методики.
/// Оценки по нормам методики (порции, граммы), не по произвольным блюдам.
abstract final class MealCalories {
  static int forMeal(
    PrepMeal meal, {
    required String methodologyId,
    required int stageIndex,
  }) {
    switch (methodologyId) {
      case MethodologyIds.men:
        return _men(stageIndex, meal);
      case MethodologyIds.victory:
        return _victory(stageIndex, meal);
      case MethodologyIds.gourmets:
      case MethodologyIds.fun:
        return _gourmetOrFun(stageIndex, meal);
      case MethodologyIds.express:
      default:
        return _express(stageIndex, meal);
    }
  }

  /// Экспресс-методика и совместимые названия приёмов.
  static int _express(int stageIndex, PrepMeal meal) {
    if (stageIndex == 2) {
      return _consolidationClassic(meal.name);
    }
    return _classic(meal.name);
  }

  static int _gourmetOrFun(int stageIndex, PrepMeal meal) {
    if (stageIndex == 0) return _classic(meal.name);
    if (stageIndex == 1) {
      switch (meal.name) {
        case 'Завтрак':
          return 300;
        case 'Перекус':
          // 3–4 яблока + отруби
          return 250;
        case 'Ужин':
          return 280;
        case 'Перед сном':
          return 35;
        default:
          return _classic(meal.name);
      }
    }
    if (stageIndex == 2) return _consolidationClassic(meal.name);
    return _classic(meal.name);
  }

  static int _men(int stageIndex, PrepMeal meal) {
    switch (stageIndex) {
      case 0:
        switch (meal.name) {
          case 'Питание':
            // Рис 1 ст. + курага 250 г — суточный котёл
            return 1250;
          default:
            return 0;
        }
      case 2:
        return _menMainOrExit(meal, exitStage: true);
      default:
        return _menMainOrExit(meal, exitStage: false);
    }
  }

  static int _menMainOrExit(PrepMeal meal, {required bool exitStage}) {
    switch (meal.name) {
      case 'Утро':
        // Кофе/чай с молоком до 100 г
        return 30;
      case 'Порция 1':
      case 'Порция 3':
        // Протеин 1 ст. л. + фитомуцил
        return 55;
      case 'Порция 2':
        if (exitStage) {
          // «Салат — как на ужин»
          return 380;
        }
        return 55;
      case 'Ужин':
        // Салат + масло 1 ст. л. + мясо до 160 г / рыба до 180 г
        return 380;
      default:
        return 0;
    }
  }

  static int _victory(int stageIndex, PrepMeal meal) {
    switch (stageIndex) {
      case 0:
        switch (meal.name) {
          case 'Завтрак':
            // Кефир 200 мл + орехи + отруби
            return 350;
          case 'Фрукты':
            // 2–4 яблока или 2 грейпфрута
            return 220;
          case 'Овощи':
            return 80;
          case 'Ужин':
            // Салат + масло + творог; вино не учитываем
            return 280;
          case 'Перед сном':
            return 35;
          default:
            return 0;
        }
      case 1:
        switch (meal.name) {
          case 'Завтрак':
            // Изолят + отруби
            return 180;
          case 'Обед':
            // Творог / рыба / мясо по схеме — средняя оценка
            return 280;
          case 'Фрукты':
            // До 400 г
            return 200;
          case 'Дополнительно':
            // Миндаль 8 шт. + отруби + кефир 1 ст.
            return 220;
          case 'Ужин':
            return 300;
          default:
            return 0;
        }
      case 2:
        switch (meal.name) {
          case 'Питание':
            // Разнообразное питание на закреплении — ориентир суточной нормы
            return 1800;
          default:
            return 0;
        }
      default:
        return 0;
    }
  }

  static int _classic(String name) {
    switch (name) {
      case 'Завтрак':
        return 250;
      case 'Перекус':
        return 100;
      case 'Обед':
        return 350;
      case 'Полдник':
        return 80;
      case 'Ужин':
        return 250;
      case 'Перед сном':
        return 80;
      default:
        return 0;
    }
  }

  /// Завершающий этап экспресса — более калорийные приёмы.
  static int _consolidationClassic(String name) {
    switch (name) {
      case 'Завтрак':
        return 350;
      case 'Перекус':
        return 120;
      case 'Обед':
        return 450;
      case 'Полдник':
        return 100;
      case 'Ужин':
        return 400;
      case 'Перед сном':
        return 120;
      default:
        return 0;
    }
  }
}
