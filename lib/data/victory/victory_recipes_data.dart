// Выдержки из «Победа над весом». Не сборник рецептов.
// ignore_for_file: lines_longer_than_80_chars

class VictoryRecipe {
  final String id;
  final String title;
  final String categoryId;
  final int stageIndex;
  final List<String> ingredients;
  final List<String> steps;

  const VictoryRecipe({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.stageIndex,
    required this.ingredients,
    required this.steps,
  });
}

class VictoryRecipeCategory {
  final String id;
  final String title;
  final int stageIndex;

  const VictoryRecipeCategory({
    required this.id,
    required this.title,
    required this.stageIndex,
  });
}

class VictoryRecipesData {
  VictoryRecipesData._();

  static const categories = [
    VictoryRecipeCategory(
      id: 'prep',
      title: 'Подготовительный',
      stageIndex: 0,
    ),
    VictoryRecipeCategory(
      id: 'main',
      title: 'Основной',
      stageIndex: 1,
    ),
  ];

  static const recipes = [
    VictoryRecipe(
      id: 'v0',
      title: 'Завтрак 1-го этапа',
      categoryId: 'prep',
      stageIndex: 0,
      ingredients: [
        'кефир с бифидобактериями — 200 мл',
        'кедровые орехи — горсть (кулак)',
        'отруби — по нарастанию до 100 г/сут',
      ],
      steps: [
        'Через 1,5 ч после утренней ходьбы.',
        'Кефир без ароматизаторов.',
        'Орехи — при отсутствии аллергии.',
        'Витаминно-минеральный комплекс с завтраком.',
      ],
    ),
    VictoryRecipe(
      id: 'v1',
      title: 'Ужин 1-го этапа',
      categoryId: 'prep',
      stageIndex: 0,
      ingredients: [
        'свежие овощи',
        'оливковое масло — 1 ст. л.',
        'творог обезжиренный — 2 ст. л.',
        'уксус — по желанию',
        'куркума и специи',
        'вино сухое — 100–150 мл',
      ],
      steps: [
        'С 18:00 до 22:00.',
        'Салат из свежих овощей с маслом и творогом.',
        'CoQ10 и витаминный комплекс после салата.',
        'Вино — во время еды, не до и не после.',
      ],
    ),
    VictoryRecipe(
      id: 'v2',
      title: 'Обед 2-го этапа — творог',
      categoryId: 'main',
      stageIndex: 1,
      ingredients: [
        'творог — 180–200 г, 0–7% жирности',
        'овощи и зелень',
      ],
      steps: [
        '2 дня в неделю.',
        'Первые 2 дня 2-го этапа — только творог.',
        'С 0% творога — 3 кураги или 3 чернослива или 2 инжира.',
        'Фрукты в день тогда сократить на треть.',
      ],
    ),
    VictoryRecipe(
      id: 'v3',
      title: 'Обед 2-го этапа — рыба',
      categoryId: 'main',
      stageIndex: 1,
      ingredients: [
        'рыба жирных пород — до 180 г готового',
        'или морепродукты — до 180 г',
        'овощи, морская капуста',
      ],
      steps: [
        '3 дня в неделю.',
        'Готовить без масла.',
        'В «рыбный» ужин: 1 желток в салат, масло — ч. л.',
      ],
    ),
    VictoryRecipe(
      id: 'v4',
      title: 'Обед 2-го этапа — мясо',
      categoryId: 'main',
      stageIndex: 1,
      ingredients: [
        'курица без кожи — до 250 г',
        'или кролик, говядина, телятина',
        'овощи — гарнир',
      ],
      steps: [
        '2 дня в неделю.',
        'Без масла: тушение, варка, гриль, аэрогриль.',
        'Специи, чеснок — без ограничений.',
      ],
    ),
  ];

  static List<VictoryRecipe> forCategory(String categoryId) =>
      recipes.where((r) => r.categoryId == categoryId).toList();

  static bool isSalad(VictoryRecipe recipe) {
    if (recipe.id == 'v1') return true;
    return _isSaladTitle(recipe.title);
  }

  static List<VictoryRecipe> forStageType(
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
