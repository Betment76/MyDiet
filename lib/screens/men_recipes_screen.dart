import 'package:flutter/material.dart';
import 'package:my_diet/data/men/men_recipes_data.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/screens/men_recipe_detail_screen.dart';
import 'package:my_diet/widgets/common_widgets.dart';
import 'package:my_diet/widgets/methodology_recipes_list.dart';

/// Список рецептов «Диета мужская» по этапам и типам блюд.
class MenRecipesScreen extends StatelessWidget {
  const MenRecipesScreen({super.key});

  static const _subcategoryDefs = [
    (id: 'salads', title: 'Салаты', salads: true),
    (id: 'meals', title: 'Основные блюда', salads: false),
  ];

  static List<MethodologyRecipeStageGroup> _stageGroups(
    MethodologyConfig config,
    void Function(MenRecipe recipe) onTap,
  ) {
    return [
      for (var stageIndex = 0; stageIndex < 3; stageIndex++)
        MethodologyRecipeStageGroup(
          id: 'stage_$stageIndex',
          title: '${config.stageCardNames[stageIndex]} этап',
          stageIndex: stageIndex,
          subcategories: [
            for (final def in _subcategoryDefs)
              MethodologyRecipeSubcategoryGroup(
                id: def.id,
                title: def.title,
                recipes: [
                  for (final recipe in MenRecipesData.forStageType(
                    stageIndex,
                    salads: def.salads,
                  ))
                    MethodologyRecipeEntry(
                      title: recipe.title,
                      onTap: () => onTap(recipe),
                    ),
                ],
              ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = MethodologyRegistry.get(MethodologyIds.men);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MethodologyGradientBackground(
        gradient: config.backgroundGradient,
        child: Column(
          children: [
            const MethodologyFixedHeader(title: 'Рецепты методики'),
            Expanded(
              child: MethodologyRecipesStageAccordion(
                config: config,
                stages: _stageGroups(
                  config,
                  (recipe) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MenRecipeDetailScreen(recipe: recipe),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
