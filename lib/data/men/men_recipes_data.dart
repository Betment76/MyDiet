// Выдержки из «Как худеют настоящие мужчины».
// Отдельного сборника рецептов нет — только правила питания.
// ignore_for_file: lines_longer_than_80_chars

class MenRecipe {
  final String id;
  final String title;
  final String categoryId;
  final int stageIndex;
  final List<String> ingredients;
  final List<String> steps;

  const MenRecipe({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.stageIndex,
    required this.ingredients,
    required this.steps,
  });
}

class MenRecipeCategory {
  final String id;
  final String title;
  final int stageIndex;

  const MenRecipeCategory({
    required this.id,
    required this.title,
    required this.stageIndex,
  });
}

class MenRecipesData {
  MenRecipesData._();

  static const categories = [
    MenRecipeCategory(
      id: 'prep',
      title: 'Подготовительный',
      stageIndex: 0,
    ),
    MenRecipeCategory(
      id: 'main',
      title: 'Основной',
      stageIndex: 1,
    ),
    MenRecipeCategory(
      id: 'dinner',
      title: 'Вечерний ужин',
      stageIndex: 1,
    ),
  ];

  static const recipes = [
    MenRecipe(
      id: 'm0',
      title: 'Рис «Басмати» с курагой',
      categoryId: 'prep',
      stageIndex: 0,
      ingredients: [
        'рис «Басмати» — 1 стакан (сухой)',
        'курага — 250 г',
        'вода — 1,5–2 л в день',
        'куркума, перец — на кончике ножа (по желанию)',
      ],
      steps: [
        'Два–три дня — только рис с курагой, без соли.',
        'Разварить стакан риса «Басмати» в кастрюлю.',
        '250 г кураги мелко нарезать, смешать с рисом.',
        'Обильно пить воду. Больше ничего.',
        'Затем — основной этап.',
      ],
    ),
    MenRecipe(
      id: 'm1',
      title: 'Фитомуцил с изолятом протеина',
      categoryId: 'main',
      stageIndex: 1,
      ingredients: [
        '«Фитомуцил Слим Смарт» — 1 пакет',
        'изолят протеина — 1 ст. л.',
        'вода — 200 мл, негазированная',
      ],
      steps: [
        'При первом желании есть — смесь фитомуцила и протеина.',
        'Развести в 200 мл воды, быстро выпить (шейкер).',
        '3–4 порции в день равномерно.',
        'Последняя — примерно в 18:00.',
      ],
    ),
    MenRecipe(
      id: 'm2',
      title: 'Салат к ужину',
      categoryId: 'dinner',
      stageIndex: 1,
      ingredients: [
        'любые свежие овощи и зелень над землёй',
        'оливковое масло нерафинированное — 1 ст. л.',
        'винный или бальзамический уксус — 1 ст. л. (по желанию)',
        'специи по вкусу',
      ],
      steps: [
        'Любые свежие овощи, травы, зелень (чеснок — исключение).',
        '1 ст. л. оливкового масла, по желанию — уксус.',
        'Можно добавлять специи по вкусу.',
      ],
    ),
    MenRecipe(
      id: 'm3',
      title: 'Белковое блюдо к ужину',
      categoryId: 'dinner',
      stageIndex: 1,
      ingredients: [
        'мясо — до 160 г готового продукта',
        'или рыба / морепродукты — до 180 г',
        'масло — минимально, на продукт',
      ],
      steps: [
        'Мясо любых сортов, жир обрезать.',
        'Говядина, свинина, баранина, птица — до 160 г.',
        'Рыба или морепродукты — до 180 г.',
        'Жарка, гриль, пар, духовка — как угодно.',
        'Продукты периодически чередовать.',
        'По желанию — 100 мл сухого красного вина.',
      ],
    ),
  ];

  static List<MenRecipe> forCategory(String categoryId) =>
      recipes.where((r) => r.categoryId == categoryId).toList();

  static bool isSalad(MenRecipe recipe) => _isSaladTitle(recipe.title);

  static List<MenRecipe> forStageType(
    int stageIndex, {
    required bool salads,
  }) {
    final list = recipes
        .where((r) => r.stageIndex == stageIndex && isSalad(r) == salads)
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  static bool _isSaladTitle(String title) {
    final t = title.toLowerCase().trim();
    return t.contains('салат');
  }
}
