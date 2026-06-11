// Универсальный экран этапа — карточка с инфой + дни с чекбоксами
// Работает для всех трёх этапов (0, 1, 2)

import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/data/prep_plan_data.dart';
import 'package:my_diet/models/stage_info.dart';
import 'package:my_diet/services/meal_progress_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/purchase_verification_service.dart';
import 'package:my_diet/services/stage_unlock_service.dart';
import 'package:my_diet/widgets/common_widgets.dart';
import 'package:my_diet/widgets/unlock_dialogs.dart';

class StagePlanScreen extends StatefulWidget {
  final String methodologyId;
  final int stageIndex;
  final List<PrepDay> plan;
  final VoidCallback? onBack;

  const StagePlanScreen({
    super.key,
    required this.methodologyId,
    required this.stageIndex,
    required this.plan,
    this.onBack,
  });

  @override
  State<StagePlanScreen> createState() => _StagePlanScreenState();
}

class _StagePlanScreenState extends State<StagePlanScreen> {
  late final MethodologyConfig _config;
  late final List<PrepDay> _plan;
  Set<String> _done = {};
  int _maxUnlockedDay = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _config = MethodologyRegistry.get(widget.methodologyId);
    _plan = widget.plan;
    _load();
  }

  Future<void> _load() async {
    await PurchaseVerificationService.verifyBeforeAccess(widget.methodologyId);
    final done = await MealProgressService.loadDone(
      widget.stageIndex,
      methodologyId: widget.methodologyId,
    );
    final maxDay = await StageUnlockService.getMaxUnlockedDay(
      widget.methodologyId,
      widget.stageIndex,
      _plan.length,
    );
    if (mounted) {
      setState(() {
        _done = done;
        _maxUnlockedDay = maxDay;
        _loading = false;
      });
    }
  }

  Future<void> _onLockedDayTap(int dayNumber) async {
    await _load();
    if (!mounted || dayNumber <= _maxUnlockedDay) return;

    final unlocked = await showDayUnlockDialog(
      context,
      methodologyId: widget.methodologyId,
      stageIndex: widget.stageIndex,
      dayNumber: dayNumber,
      totalDays: _plan.length,
    );
    if (unlocked && mounted) await _load();
  }

  Future<void> _togglePlanMeal(int planDay, int mealIndex) async {
    final wasMarked = MealProgressService.isPlanMealMarked(
      _done,
      widget.stageIndex,
      planDay,
      mealIndex,
      methodologyId: widget.methodologyId,
    );
    final updated = await MealProgressService.togglePlanMeal(
      done: Set<String>.from(_done),
      stageIndex: widget.stageIndex,
      planDay: planDay,
      mealIndex: mealIndex,
      methodologyId: widget.methodologyId,
    );
    if (!wasMarked &&
        MealProgressService.isPlanMealMarked(
          updated,
          widget.stageIndex,
          planDay,
          mealIndex,
          methodologyId: widget.methodologyId,
        )) {
      await ProfileService.setStage(
        widget.stageIndex + 1,
        methodologyId: widget.methodologyId,
      );
    }
    if (mounted) setState(() => _done = updated);
    ProfileService.setActiveMethodology(widget.methodologyId);
  }

  @override
  Widget build(BuildContext context) {
    final stage = _config.stages[widget.stageIndex];
    final stageEmoji = _config.stageEmojis[widget.stageIndex];
    final stageColor = _config.stageColors[widget.stageIndex];

    if (_loading) {
      return MethodologyGradientBackground(
        gradient: _config.backgroundGradient,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return MethodologyGradientBackground(
      gradient: _config.backgroundGradient,
      child: Column(
        children: [
          MethodologyFixedHeader(
            title: stage.title,
            subtitle: '${_plan.length} дней • отмечайте что съели',
            onBack: widget.onBack,
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return _StageInfoCard(
                            stage: stage,
                            stageColor: stageColor,
                            emoji: stageEmoji,
                            cardTitle:
                                _config.stageCardNames[widget.stageIndex],
                          );
                        }
                        final dayIndex = index - 1;
                        if (dayIndex >= _plan.length) return null;
                        final day = _plan[dayIndex];
                        final isLocked = day.day > _maxUnlockedDay;
                        return _DayCard(
                          day: day,
                          stageIndex: widget.stageIndex,
                          methodologyId: widget.methodologyId,
                          done: _done,
                          isLocked: isLocked,
                          onToggleMeal: _togglePlanMeal,
                          onLockedTap: () => _onLockedDayTap(day.day),
                        );
                      },
                      childCount: _plan.length + 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка с информацией об этапе
class _StageInfoCard extends StatelessWidget {
  final StageInfo stage;
  final Color stageColor;
  final String emoji;
  final String cardTitle;

  const _StageInfoCard({
    required this.stage,
    required this.stageColor,
    required this.emoji,
    required this.cardTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          cardTitle,
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
  final String methodologyId;
  final Set<String> done;
  final bool isLocked;
  final void Function(int planDay, int mealIndex) onToggleMeal;
  final VoidCallback onLockedTap;

  const _DayCard({
    required this.day,
    required this.stageIndex,
    required this.methodologyId,
    required this.done,
    required this.isLocked,
    required this.onToggleMeal,
    required this.onLockedTap,
  });

  bool _isMarked(int mealIndex) =>
      MealProgressService.isPlanMealMarked(
        done,
        stageIndex,
        day.day,
        mealIndex,
        methodologyId: methodologyId,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = day.meals.length;
    final completed = day.meals
        .where((m) => _isMarked(day.meals.indexOf(m)))
        .length;

    if (isLocked) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onLockedTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.lock, size: 18, color: Colors.grey.shade700),
          ),
          title: Text(
            '${day.day}-й день',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          subtitle: const Text(
            'Нажмите, чтобы открыть',
            style: TextStyle(fontSize: 12),
          ),
          trailing: Icon(Icons.lock_outline, color: Colors.grey.shade600),
        ),
      );
    }

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
            final isDone = _isMarked(idx);
            return _MealCheckTile(
              meal: meal,
              isDone: isDone,
              onChanged: (_) => onToggleMeal(day.day, idx),
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
    final icon = _mealIcon(meal.name);

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

IconData _mealIcon(String name) {
  switch (name) {
    case 'Завтрак':
    case 'Утро':
      return Icons.wb_sunny_outlined;
    case 'Обед':
      return Icons.restaurant;
    case 'Ужин':
      return Icons.nightlight_outlined;
    case 'Перекус':
      return Icons.apple_outlined;
    case 'Полдник':
      return Icons.free_breakfast_outlined;
    case 'Перед сном':
      return Icons.bedtime_outlined;
    case 'Порция 1':
    case 'Порция 2':
    case 'Порция 3':
      return Icons.local_drink_outlined;
    case 'Режим':
    case 'Закрепление':
      return Icons.info_outline;
    default:
      return Icons.circle_outlined;
  }
}
