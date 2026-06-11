import 'package:flutter/material.dart';
import 'package:my_diet/data/food_data.dart';
import 'package:my_diet/screens/plan_loading_screen.dart';
import 'package:my_diet/services/plan_cache_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран выбора запрещённых продуктов (аллергия / непереносимость)
/// Категории раскрываются по тапу, продукты — аккуратной сеткой.
class FoodRestrictionsScreen extends StatefulWidget {
  const FoodRestrictionsScreen({super.key});

  @override
  State<FoodRestrictionsScreen> createState() => _FoodRestrictionsScreenState();
}

class _FoodRestrictionsScreenState extends State<FoodRestrictionsScreen> {
  Set<String> _restricted = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await ProfileService.loadRestricted();
    setState(() {
      _restricted = saved.toSet();
      _loading = false;
    });
  }

  Future<void> _save() async {
    await ProfileService.saveRestricted(_restricted.toList());
    await PlanCacheService.invalidate();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PlanLoadingScreen(isRegeneration: true),
        ),
        (route) => false,
      );
    }
  }

  void _toggle(String food) {
    setState(() {
      if (_restricted.contains(food)) {
        _restricted.remove(food);
      } else {
        _restricted.add(food);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: AppGradientBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: AppGradientBackground(
        child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 40,
                bottom: 24,
                left: 20,
                right: 20,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выберите ограничения',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Отметьте продукты, которые вам нельзя.\n'
                    'Мы исключим их из меню.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Категории — раскрывающиеся контейнеры на всю ширину
                  ...allFoods.map((cat) => _CategoryTile(
                        category: cat,
                        restricted: _restricted,
                        onToggle: _toggle,
                      )),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const PlanLoadingScreen(),
                            ),
                          );
                        }
                      },
                      child: const Text('Пропустить, у меня нет ограничений'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Раскрывающаяся категория на всю ширину
class _CategoryTile extends StatelessWidget {
  final FoodCategory category;
  final Set<String> restricted;
  final void Function(String food) onToggle;

  const _CategoryTile({
    required this.category,
    required this.restricted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedCount =
        category.items.where((f) => restricted.contains(f)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Theme(
          data: theme.copyWith(
            dividerColor: Colors.transparent,
            listTileTheme: const ListTileThemeData(
              contentPadding: EdgeInsets.only(left: 16, right: 8),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              category.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (checkedCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$checkedCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                const Icon(Icons.expand_more, color: Colors.grey),
              ],
            ),
            children: [
              // Сетка продуктов 2 колонки
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.8,
                children: category.items.map((food) {
                  final isRestricted = restricted.contains(food);
                  return GestureDetector(
                    onTap: () => onToggle(food),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRestricted
                            ? Colors.red.shade50
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isRestricted
                              ? Colors.red.shade300
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isRestricted) ...[
                            Icon(Icons.block,
                                size: 14, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              food,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isRestricted ? FontWeight.w600 : FontWeight.normal,
                                color: isRestricted ? Colors.red.shade700 : null,
                                decoration:
                                    isRestricted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
