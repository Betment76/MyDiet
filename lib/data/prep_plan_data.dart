// Меню подготовительного этапа из книги «Минус размер» (Ковальков)
// 14 дней — белково-овощная основа, без мяса, без быстрых углеводов

class PrepMeal {
  final String name;
  final String details;
  /// Ингредиенты для фильтрации по запретам (из food_data.dart)
  final List<String> ingredients;

  const PrepMeal({
    required this.name,
    required this.details,
    required this.ingredients,
  });

  PrepMeal copyWith({String? details, List<String>? ingredients}) => PrepMeal(
    name: name,
    details: details ?? this.details,
    ingredients: ingredients ?? this.ingredients,
  );

  /// Примерная калорийность по типу приёма
  int get calories {
    switch (name) {
      case 'Завтрак': return 250;
      case 'Перекус': return 100;
      case 'Обед': return 350;
      case 'Ужин': return 250;
      case 'Перед сном': return 80;
      default: return 0;
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'details': details,
    'ingredients': ingredients,
  };

  factory PrepMeal.fromJson(Map<String, dynamic> json) => PrepMeal(
    name: json['name'] as String,
    details: json['details'] as String,
    ingredients: List<String>.from(json['ingredients'] as List),
  );
}

class PrepDay {
  final int day;
  final List<PrepMeal> meals;

  const PrepDay({required this.day, required this.meals});

  Map<String, dynamic> toJson() => {
    'day': day,
    'meals': meals.map((m) => m.toJson()).toList(),
  };

  factory PrepDay.fromJson(Map<String, dynamic> json) => PrepDay(
    day: json['day'] as int,
    meals: (json['meals'] as List)
        .map((m) => PrepMeal.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}

/// 14-дневное меню подготовительного этапа
/// Завтрак — кисломолочка + орехи + отруби
/// В течение дня — 4 яблока, отруби до 100 г, вода
/// Ужин — овощной салат с творогом / белком
/// Перед сном — 2 яичных белка
const List<PrepDay> prepPlan = [
  PrepDay(day: 1, meals: [
    PrepMeal(name: 'Завтрак', details: 'Кефир (200 мл) + кедровые орехи (20 г) + отруби (2 ст.л.)',
        ingredients: ['Кефир', 'Кедровые орехи', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Греческий салат с творогом: огурцы, помидоры, перец болгарский, творог, оливковое масло',
        ingredients: ['Огурцы', 'Помидоры', 'Болгарский перец', 'Творог', 'Оливковое масло']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Рукола с творогом и овощами: рукола, огурец, помидор, творог',
        ingredients: ['Рукола', 'Огурцы', 'Помидоры', 'Творог']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.), соевый соус, перец',
        ingredients: ['Яйца', 'Соевый соус']),
  ]),
  PrepDay(day: 2, meals: [
    PrepMeal(name: 'Завтрак', details: 'Питьевой йогурт (200 мл) + миндаль (30 г) + отруби (2 ст.л.)',
        ingredients: ['Натуральный йогурт', 'Миндаль', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Салат из пекинской капусты, огурца, зелени с творогом',
        ingredients: ['Пекинская капуста', 'Огурцы', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Рукола с творогом и овощами',
        ingredients: ['Рукола', 'Творог']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.)',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 3, meals: [
    PrepMeal(name: 'Завтрак', details: 'Коктейль: кефир (200 мл) + грецкие орехи (20 г) + отруби (2 ст.л.) + яблоко + ванилин',
        ingredients: ['Кефир', 'Грецкие орехи', 'Отруби', 'Яблоки']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Салат из дайкона, огурцов, творога с зеленью',
        ingredients: ['Дайкон', 'Огурцы', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Запечённые яблоки (2 шт.) с корицей',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.)',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 4, meals: [
    PrepMeal(name: 'Завтрак', details: 'Ряженка (200 мл) + кешью (20 г) + отруби (2 ст.л.)',
        ingredients: ['Кефир', 'Фундук', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Груша (1 шт.)',
        ingredients: ['Груши']),
    PrepMeal(name: 'Обед', details: 'Салат из обжаренных баклажанов, сладкого перца, лука, чеснока, соевого соуса с тофу',
        ingredients: ['Баклажаны', 'Болгарский перец', 'Соевый соус']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Запечённые яблоки (2 шт.) с корицей и острым перцем',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.)',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 5, meals: [
    PrepMeal(name: 'Завтрак', details: 'Творог (100 г) + кедровые орехи (20 г) + отруби (2 ст.л.)',
        ingredients: ['Творог', 'Кедровые орехи', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Овощной салат с творогом: капуста, огурец, помидор, зелень, творог',
        ingredients: ['Капуста белокочанная', 'Огурцы', 'Помидоры', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Киви (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Киви', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Творог с зеленью и огурцом',
        ingredients: ['Творог', 'Огурцы']),
    PrepMeal(name: 'Перед сном', details: 'Омлет белковый с шампиньонами, помидором, кабачком',
        ingredients: ['Яйца', 'Шампиньоны', 'Помидоры', 'Кабачки']),
  ]),
  PrepDay(day: 6, meals: [
    PrepMeal(name: 'Завтрак', details: 'Кефир (200 мл) + грецкие орехи (20 г) + отруби (2 ст.л.)',
        ingredients: ['Кефир', 'Грецкие орехи', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Салат из цветной капусты, брокколи, зелени с творогом',
        ingredients: ['Цветная капуста', 'Брокколи', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Творожная запеканка с орехами и ягодами (без сахара)',
        ingredients: ['Творог', 'Грецкие орехи', 'Малина']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.) или омлет',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 7, meals: [
    PrepMeal(name: 'Завтрак', details: 'Натуральный йогурт (200 мл) + миндаль (30 г) + отруби (2 ст.л.)',
        ingredients: ['Натуральный йогурт', 'Миндаль', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Овощной салат с творогом: рукола, огурец, перец, творог',
        ingredients: ['Рукола', 'Огурцы', 'Болгарский перец', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Груша (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Груши', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Овощной салат с творогом',
        ingredients: ['Творог', 'Огурцы', 'Помидоры']),
    PrepMeal(name: 'Перед сном', details: 'Омлет белковый с зеленью',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 8, meals: [
    PrepMeal(name: 'Завтрак', details: 'Кефир (200 мл) + кедровые орехи (20 г) + отруби (2 ст.л.)',
        ingredients: ['Кефир', 'Кедровые орехи', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Салат с авокадо, огурцом, помидором, зеленью и творогом',
        ingredients: ['Огурцы', 'Помидоры', 'Творог', 'Оливковое масло']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Творог с огурцом, укропом и чесноком',
        ingredients: ['Творог', 'Огурцы']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.), бальзамический уксус',
        ingredients: ['Яйца', 'Бальзамический уксус']),
  ]),
  PrepDay(day: 9, meals: [
    PrepMeal(name: 'Завтрак', details: 'Творог (100 г) + ягоды (50 г) + отруби (2 ст.л.)',
        ingredients: ['Творог', 'Голубика', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Тёплый салат из пекинской капусты, шампиньонов и зелени',
        ingredients: ['Пекинская капуста', 'Шампиньоны', 'Растительное масло']),
    PrepMeal(name: 'Перекус', details: 'Киви (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Киви', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Запечённые яблоки (2 шт.) с творогом и корицей',
        ingredients: ['Яблоки', 'Творог']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.)',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 10, meals: [
    PrepMeal(name: 'Завтрак', details: 'Ряженка (200 мл) + фундук (20 г) + отруби (2 ст.л.)',
        ingredients: ['Кефир', 'Фундук', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Груша (1 шт.)',
        ingredients: ['Груши']),
    PrepMeal(name: 'Обед', details: 'Салат из кабачков, болгарского перца и зелени с творогом',
        ingredients: ['Кабачки', 'Болгарский перец', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Творожная запеканка с корицей и яблоком',
        ingredients: ['Творог', 'Яблоки']),
    PrepMeal(name: 'Перед сном', details: 'Омлет белковый с кабачком и помидором',
        ingredients: ['Яйца', 'Кабачки', 'Помидоры']),
  ]),
  PrepDay(day: 11, meals: [
    PrepMeal(name: 'Завтрак', details: 'Коктейль: кефир + отруби + яблоко + корица',
        ingredients: ['Кефир', 'Отруби', 'Яблоки']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Салат из брокколи, цветной капусты, зелени с творогом',
        ingredients: ['Брокколи', 'Цветная капуста', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Груша (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Груши', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Салат из сельдерея, яблока и творога',
        ingredients: ['Сельдерей', 'Яблоки', 'Творог']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.)',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 12, meals: [
    PrepMeal(name: 'Завтрак', details: 'Натуральный йогурт (200 мл) + кедровые орехи (20 г) + отруби (2 ст.л.)',
        ingredients: ['Натуральный йогурт', 'Кедровые орехи', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Киви (1 шт.)',
        ingredients: ['Киви']),
    PrepMeal(name: 'Обед', details: 'Салат из пекинской капусты, огурца, перца, зелени с творогом',
        ingredients: ['Пекинская капуста', 'Огурцы', 'Болгарский перец', 'Творог']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Запечённые яблоки с творогом и орехами',
        ingredients: ['Яблоки', 'Творог', 'Грецкие орехи']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.)',
        ingredients: ['Яйца']),
  ]),
  PrepDay(day: 13, meals: [
    PrepMeal(name: 'Завтрак', details: 'Творог (100 г) + малина (50 г) + отруби (2 ст.л.)',
        ingredients: ['Творог', 'Малина', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Овощное рагу из кабачков, баклажанов, перца и помидоров',
        ingredients: ['Кабачки', 'Баклажаны', 'Болгарский перец', 'Помидоры']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Яблоки', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Творог с зеленью, огурцом и чесноком',
        ingredients: ['Творог', 'Огурцы']),
    PrepMeal(name: 'Перед сном', details: 'Омлет белковый с шампиньонами',
        ingredients: ['Яйца', 'Шампиньоны']),
  ]),
  PrepDay(day: 14, meals: [
    PrepMeal(name: 'Завтрак', details: 'Кефир (200 мл) + грецкие орехи (20 г) + отруби (2 ст.л.)',
        ingredients: ['Кефир', 'Грецкие орехи', 'Отруби']),
    PrepMeal(name: 'Перекус', details: 'Яблоко (1 шт.)',
        ingredients: ['Яблоки']),
    PrepMeal(name: 'Обед', details: 'Салат с авокадо, руколой, помидором и творогом',
        ingredients: ['Рукола', 'Помидоры', 'Творог', 'Оливковое масло']),
    PrepMeal(name: 'Перекус', details: 'Груша (1 шт.), отруби (2 ст.л.)',
        ingredients: ['Груши', 'Отруби']),
    PrepMeal(name: 'Ужин', details: 'Творожная запеканка с ягодами (без сахара)',
        ingredients: ['Творог', 'Голубика']),
    PrepMeal(name: 'Перед сном', details: 'Яичный белок (2 шт.)',
        ingredients: ['Яйца']),
  ]),
];
