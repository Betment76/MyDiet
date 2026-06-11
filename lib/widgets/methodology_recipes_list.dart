import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';

/// Элемент списка рецептов.
class MethodologyRecipeEntry {
  final String title;
  final String? imageAsset;
  final VoidCallback onTap;

  const MethodologyRecipeEntry({
    required this.title,
    this.imageAsset,
    required this.onTap,
  });
}

/// Подкатегория внутри этапа: салаты или основные блюда.
class MethodologyRecipeSubcategoryGroup {
  final String id;
  final String title;
  final List<MethodologyRecipeEntry> recipes;

  const MethodologyRecipeSubcategoryGroup({
    required this.id,
    required this.title,
    required this.recipes,
  });
}

/// Этап методики с подкатегориями салатов и основных блюд.
class MethodologyRecipeStageGroup {
  final String id;
  final String title;
  final int stageIndex;
  final List<MethodologyRecipeSubcategoryGroup> subcategories;

  const MethodologyRecipeStageGroup({
    required this.id,
    required this.title,
    required this.stageIndex,
    required this.subcategories,
  });
}

/// Рецепты одной категории («Подготовительный — салаты» и т.д.).
class MethodologyRecipeCategoryGroup {
  final String id;
  final String title;
  final int stageIndex;
  final List<MethodologyRecipeEntry> recipes;

  const MethodologyRecipeCategoryGroup({
    required this.id,
    required this.title,
    required this.stageIndex,
    required this.recipes,
  });
}

/// Список рецептов: карточки категорий этапов, внутри — рецепты.
class MethodologyRecipesAccordion extends StatefulWidget {
  final MethodologyConfig config;
  final List<MethodologyRecipeCategoryGroup> categories;
  /// Белые карточки на градиенте (как «О методике»), а не полупрозрачные.
  final bool surfaceHeaders;

  const MethodologyRecipesAccordion({
    super.key,
    required this.config,
    required this.categories,
    this.surfaceHeaders = false,
  });

  @override
  State<MethodologyRecipesAccordion> createState() =>
      _MethodologyRecipesAccordionState();
}

class _MethodologyRecipesAccordionState
    extends State<MethodologyRecipesAccordion> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.categories.where((c) => c.recipes.isNotEmpty).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final group = visible[index];
        final expanded = _expanded.contains(group.id);
        final accent = widget.config.stageColors[
            group.stageIndex.clamp(0, widget.config.stageColors.length - 1)];

        return Padding(
          padding: EdgeInsets.only(bottom: index < visible.length - 1 ? 12 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CategoryHeader(
                title: group.title,
                count: group.recipes.length,
                expanded: expanded,
                accent: accent,
                surfaceStyle: widget.surfaceHeaders,
                onTap: () {
                  setState(() {
                    if (expanded) {
                      _expanded.remove(group.id);
                    } else {
                      _expanded.add(group.id);
                    }
                  });
                },
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < group.recipes.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < group.recipes.length - 1 ? 8 : 0,
                          ),
                          child: _RecipeTile(
                            entry: group.recipes[i],
                            accent: accent,
                          ),
                        ),
                    ],
                  ),
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Трёхуровневый список: этап → салаты / основные блюда → рецепты.
class MethodologyRecipesStageAccordion extends StatefulWidget {
  final MethodologyConfig config;
  final List<MethodologyRecipeStageGroup> stages;
  final bool surfaceHeaders;

  const MethodologyRecipesStageAccordion({
    super.key,
    required this.config,
    required this.stages,
    this.surfaceHeaders = true,
  });

  @override
  State<MethodologyRecipesStageAccordion> createState() =>
      _MethodologyRecipesStageAccordionState();
}

class _MethodologyRecipesStageAccordionState
    extends State<MethodologyRecipesStageAccordion> {
  final _expandedStages = <String>{};
  final _expandedSubcategories = <String>{};

  @override
  Widget build(BuildContext context) {
    final visibleStages = widget.stages
        .map((stage) {
          final subs = stage.subcategories
              .where((s) => s.recipes.isNotEmpty)
              .toList();
          if (subs.isEmpty) return null;
          return MethodologyRecipeStageGroup(
            id: stage.id,
            title: stage.title,
            stageIndex: stage.stageIndex,
            subcategories: subs,
          );
        })
        .whereType<MethodologyRecipeStageGroup>()
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: visibleStages.length,
      itemBuilder: (context, index) {
        final stage = visibleStages[index];
        final stageExpanded = _expandedStages.contains(stage.id);
        final accent = widget.config.stageColors[
            stage.stageIndex.clamp(0, widget.config.stageColors.length - 1)];
        final recipeCount = stage.subcategories.fold<int>(
          0,
          (sum, s) => sum + s.recipes.length,
        );

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < visibleStages.length - 1 ? 12 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CategoryHeader(
                title: stage.title,
                count: recipeCount,
                expanded: stageExpanded,
                accent: accent,
                surfaceStyle: widget.surfaceHeaders,
                onTap: () {
                  setState(() {
                    if (stageExpanded) {
                      _expandedStages.remove(stage.id);
                    } else {
                      _expandedStages.add(stage.id);
                    }
                  });
                },
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Column(
                    children: [
                      for (var i = 0; i < stage.subcategories.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < stage.subcategories.length - 1 ? 8 : 0,
                          ),
                          child: _buildSubcategory(stage, stage.subcategories[i], accent),
                        ),
                    ],
                  ),
                ),
                crossFadeState: stageExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubcategory(
    MethodologyRecipeStageGroup stage,
    MethodologyRecipeSubcategoryGroup sub,
    Color accent,
  ) {
    final key = '${stage.id}_${sub.id}';
    final expanded = _expandedSubcategories.contains(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryHeader(
          title: sub.title,
          count: sub.recipes.length,
          expanded: expanded,
          accent: accent,
          surfaceStyle: widget.surfaceHeaders,
          compact: true,
          leadingIcon: sub.id == 'salads'
              ? Icons.eco_outlined
              : Icons.restaurant_outlined,
          onTap: () {
            setState(() {
              if (expanded) {
                _expandedSubcategories.remove(key);
              } else {
                _expandedSubcategories.add(key);
              }
            });
          },
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Column(
              children: [
                for (var i = 0; i < sub.recipes.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i < sub.recipes.length - 1 ? 8 : 0,
                    ),
                    child: _RecipeTile(
                      entry: sub.recipes[i],
                      accent: accent,
                    ),
                  ),
              ],
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool expanded;
  final Color accent;
  final bool surfaceStyle;
  final bool compact;
  final IconData? leadingIcon;
  final VoidCallback onTap;

  const _CategoryHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.accent,
    required this.surfaceStyle,
    this.compact = false,
    this.leadingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (surfaceStyle) {
      final borderWidth = compact ? 4.0 : 6.0;
      final verticalPad = compact ? 10.0 : 12.0;
      return Material(
        color: theme.colorScheme.surface,
        elevation: compact ? 1 : 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: verticalPad),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: borderWidth)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  leadingIcon ??
                      (compact ? Icons.eco_outlined : Icons.menu_book_outlined),
                  color: accent,
                  size: compact ? 20 : 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: (compact
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.titleSmall)
                        ?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final MethodologyRecipeEntry entry;
  final Color accent;

  const _RecipeTile({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: entry.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 4)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (entry.imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    entry.imageAsset!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbPlaceholder(accent),
                  ),
                )
              else
                _thumbPlaceholder(accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(Color accent) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant_menu, color: accent),
    );
  }
}
