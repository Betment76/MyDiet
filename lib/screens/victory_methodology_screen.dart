import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/data/prep_plan_data.dart';
import 'package:my_diet/screens/victory_method_screen.dart';
import 'package:my_diet/screens/victory_recipes_screen.dart';
import 'package:my_diet/screens/stage_plan_screen.dart';
import 'package:my_diet/services/meal_plan_generator.dart';
import 'package:my_diet/services/plan_cache_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/widgets/common_widgets.dart';
import 'package:my_diet/widgets/methodology_stage_cards.dart';

/// Экран «Победа над весом» — этапы, совет дня, меню по дням.
class VictoryMethodologyScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isActiveView;

  const VictoryMethodologyScreen({
    super.key,
    this.onBack,
    this.isActiveView = false,
  });

  @override
  State<VictoryMethodologyScreen> createState() =>
      _VictoryMethodologyScreenState();
}

class _VictoryMethodologyScreenState extends State<VictoryMethodologyScreen> {
  static const _methodologyId = MethodologyIds.victory;
  static final _config = MethodologyRegistry.get(_methodologyId);

  final _stageCardsKey = GlobalKey<MethodologyStageCardsState>();
  int? _stageIndex;
  List<PrepDay>? _currentPlan;
  bool _stageLoading = false;

  void _openStage(int index) {
    setState(() {
      _stageIndex = index;
      _stageLoading = true;
    });
    _loadStagePlan(index);
  }

  Future<void> _loadStagePlan(int stageIndex) async {
    setState(() => _stageLoading = true);
    final restricted = await ProfileService.loadRestricted();
    var plan = await PlanCacheService.load(
      _methodologyId,
      stageIndex,
      restricted,
    );
    if (plan == null) {
      plan = generateStagePlan(_methodologyId, stageIndex, restricted);
      await PlanCacheService.save(
        _methodologyId,
        stageIndex,
        plan,
        restricted,
      );
    }
    if (mounted) {
      setState(() {
        _currentPlan = plan;
        _stageLoading = false;
      });
    }
  }

  void _closeStage() {
    setState(() {
      _stageIndex = null;
      _currentPlan = null;
    });
    _stageCardsKey.currentState?.refresh();
  }

  @override
  void didUpdateWidget(VictoryMethodologyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveView && !oldWidget.isActiveView) {
      _onBecameActive();
    }
  }

  Future<void> _onBecameActive() async {
    if (_stageIndex != null) {
      setState(() {
        _stageIndex = null;
        _currentPlan = null;
      });
    }
    await _stageCardsKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MethodologyGradientBackground(
      gradient: _config.backgroundGradient,
      child: Stack(
        children: [
          _VictoryMethodologyBody(
            config: _config,
            stageCardsKey: _stageCardsKey,
            onOpenStage: _openStage,
            onBack: widget.onBack,
          ),
          if (_stageIndex != null)
            Positioned.fill(
              child: _buildStageContent(),
            ),
        ],
      ),
    );
  }

  Widget _buildStageContent() {
    if (_stageLoading) {
      return MethodologyGradientBackground(
        gradient: _config.backgroundGradient,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final plan = _currentPlan;
    if (plan == null || plan.isEmpty) {
      return const Center(child: Text('Не удалось загрузить меню'));
    }
    return StagePlanScreen(
      methodologyId: _methodologyId,
      stageIndex: _stageIndex!,
      plan: plan,
      onBack: _closeStage,
    );
  }
}

class _VictoryMethodologyBody extends StatelessWidget {
  final MethodologyConfig config;
  final GlobalKey<MethodologyStageCardsState> stageCardsKey;
  final void Function(int index) onOpenStage;
  final VoidCallback? onBack;

  const _VictoryMethodologyBody({
    required this.config,
    required this.stageCardsKey,
    required this.onOpenStage,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void handleBack() {
      if (onBack != null) {
        onBack!();
      } else {
        Navigator.of(context).pop();
      }
    }

    return Column(
      children: [
        MethodologyFixedHeader(
          title: config.title,
          subtitle: config.subtitle,
          onBack: handleBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: config.stageColors.first,
                        width: 6,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VictoryMethodScreen(),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'О методике',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Обязательно к прочтению',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
                  ),
                ),
                const SizedBox(height: 24),
                MethodologyStageCards(
                  key: stageCardsKey,
                  methodologyId: MethodologyIds.victory,
                  onOpenStage: onOpenStage,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: config.stageColors[1],
                        width: 6,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VictoryRecipesScreen(),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Правила питания',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Правила питания методики',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
