// Универсальный экран этапа — карточка с инфой + дни с чекбоксами
// Работает для всех трёх этапов (0, 1, 2)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_diet/data/prep_plan_data.dart';
import 'package:my_diet/data/stage_data.dart';
import 'package:my_diet/models/stage_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StagePlanScreen extends StatefulWidget {
  final int stageIndex;
  final List<PrepDay> plan;
  final VoidCallback? onBack;

  const StagePlanScreen({
    super.key,
    required this.stageIndex,
    required this.plan,
    this.onBack,
  });

  @override
  State<StagePlanScreen> createState() => _StagePlanScreenState();
}

class _StagePlanScreenState extends State<StagePlanScreen> {
  late final List<PrepDay> _plan;
  Set<String> _done = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'stage_${widget.stageIndex}_progress';
    final stored = prefs.getString(key);
    if (stored != null && stored.isNotEmpty) {
      try {
        final list = List<String>.from(jsonDecode(stored));
        if (mounted) setState(() { _done = list.toSet(); _loading = false; });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String key) async {
    setState(() {
      if (_done.contains(key)) { _done.remove(key); } else { _done.add(key); }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stage_${widget.stageIndex}_progress',
        jsonEncode(_done.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final stage = StageData.stages[widget.stageIndex];
    final stageEmoji = ['\u{1F3C3}', '\u{1F4AA}', '\u{1F3AF}'][widget.stageIndex];
    final stageGradient = [
      const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFB74D)]),
      const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
      const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
    ][widget.stageIndex];

    final stageColor = [
      const Color(0xFFFF9800),
      const Color(0xFF2E7D32),
      const Color(0xFF1976D2),
    ][widget.stageIndex];

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Шапка
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: stageGradient),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 4,
              right: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stage.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${_plan.length} дней • отмечайте что съели',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Список
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return _StageInfoCard(stage: stage, stageColor: stageColor, emoji: stageEmoji);
                }
                final dayIndex = index - 1;
                if (dayIndex >= _plan.length) return null;
                return _DayCard(
                  day: _plan[dayIndex],
                  stageIndex: widget.stageIndex,
                  done: _done,
                  onToggle: _toggle,
                );
              },
              childCount: _plan.length + 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Карточка с информацией об этапе
class _StageInfoCard extends StatelessWidget {
  final StageInfo stage;
  final Color stageColor;
  final String emoji;

  const _StageInfoCard({
    required this.stage,
    required this.stageColor,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = [
      'Подготовительный этап\nВход в кетоз',
      'Основной этап\nАктивное жиросжигание',
      'Закрепительный этап\nВыход из диеты',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: stageColor.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: stageColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(
          titles[stage.number - 1],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: const Text('Нажмите, чтобы узнать подробнее',
            style: TextStyle(fontSize: 12)),
        children: [
          Text(
            stage.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (stage.allowedFoods.isNotEmpty) ...[
            Text('Разрешённые продукты',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.green.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...stage.allowedFoods.map((f) => _foodRow(
                Icons.check_circle, Colors.green.shade400, f)),
            const SizedBox(height: 12),
          ],
          if (stage.forbiddenFoods.isNotEmpty) ...[
            Text('Запрещённые продукты',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.red.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...stage.forbiddenFoods.map((f) => _foodRow(
                Icons.cancel, Colors.red.shade400, f)),
            const SizedBox(height: 12),
          ],
          if (stage.tips.isNotEmpty) ...[
            Text('Советы',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...stage.tips.map((t) => _foodRow(
                Icons.lightbulb_outline, Colors.orange.shade400, t)),
          ],
        ],
      ),
    );
  }

  Widget _foodRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final PrepDay day;
  final int stageIndex;
  final Set<String> done;
  final ValueChanged<String> onToggle;

  const _DayCard({
    required this.day,
    required this.stageIndex,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = day.meals.length;
    final completed = day.meals.where((m) =>
        done.contains('stage${stageIndex}_day_${day.day - 1}_meal_${day.meals.indexOf(m)}')).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: completed == total
              ? Colors.green.shade100
              : theme.colorScheme.primaryContainer,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: completed == total
                  ? Colors.green.shade700
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          '${day.day}-й день',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              completed == total
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              size: 20,
              color: completed == total
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        children: [
          ...day.meals.map((meal) {
            final idx = day.meals.indexOf(meal);
            final key = 'stage${stageIndex}_day_${day.day - 1}_meal_$idx';
            final isDone = done.contains(key);
            return _MealCheckTile(
              meal: meal,
              isDone: isDone,
              onChanged: (_) => onToggle(key),
            );
          }),
        ],
      ),
    );
  }
}

class _MealCheckTile extends StatelessWidget {
  final PrepMeal meal;
  final bool isDone;
  final ValueChanged<bool?> onChanged;

  const _MealCheckTile({
    required this.meal,
    required this.isDone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (meal.name) {
      'Завтрак'    => Icons.wb_sunny_outlined,
      'Обед'       => Icons.restaurant,
      'Ужин'       => Icons.nightlight_outlined,
      'Перекус'    => Icons.apple_outlined,
      'Перед сном' => Icons.bedtime_outlined,
      _            => Icons.circle_outlined,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isDone,
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: Colors.green,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.details,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
