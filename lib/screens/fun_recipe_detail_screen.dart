import 'package:flutter/material.dart';
import 'package:my_diet/data/fun/fun_recipes_data.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Детальный экран одного рецепта с фото.
class FunRecipeDetailScreen extends StatelessWidget {
  final FunRecipe recipe;

  const FunRecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final config = MethodologyRegistry.get(MethodologyIds.fun);
    final theme = Theme.of(context);
    final accent = config.stageColors[recipe.stageIndex.clamp(0, 2)];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MethodologyGradientBackground(
        gradient: config.backgroundGradient,
        child: Column(
          children: [
            MethodologyFixedHeader(title: recipe.title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recipe.imageAsset != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          recipe.imageAsset!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    if (recipe.imageAsset != null) const SizedBox(height: 16),
                    if (recipe.ingredients.isNotEmpty) ...[
                      _SectionTitle(
                        icon: Icons.shopping_basket_outlined,
                        title: 'Ингредиенты',
                        color: accent,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final ing in recipe.ingredients)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.fiber_manual_record,
                                        size: 8,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ing,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (recipe.steps.isNotEmpty) ...[
                      _SectionTitle(
                        icon: Icons.restaurant,
                        title: 'Приготовление',
                        color: accent,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < recipe.steps.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            accent.withValues(alpha: 0.15),
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          recipe.steps[i],
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(height: 1.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
