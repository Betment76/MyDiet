import 'package:flutter/material.dart';
import 'package:my_diet/data/prep_plan_data.dart';
import 'package:my_diet/data/tips_data.dart';
import 'package:my_diet/screens/diary_screen.dart';
import 'package:my_diet/screens/method_screen.dart';
import 'package:my_diet/screens/profile_screen.dart';
import 'package:my_diet/screens/progress_screen.dart';
import 'package:my_diet/screens/settings_screen.dart';
import 'package:my_diet/screens/stage_plan_screen.dart';
import 'package:my_diet/services/plan_cache_service.dart';
import 'package:my_diet/services/meal_plan_generator.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Главный экран — нижний бар всегда виден, этапы открываются поверх
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _selectedIndex = 0;

  int? _stageIndex;
  List<PrepDay>? _currentPlan;
  bool _stageLoading = false;

  final _progressKey = GlobalKey<ProgressScreenState>();
  final _diaryKey = GlobalKey<DiaryScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _screenList;

  @override
  void initState() {
    super.initState();
    _screenList = [
      _HomePage(onOpenStage: _openStage),
      DiaryScreen(key: _diaryKey, onWeightChanged: _onDiaryWeightChanged),
      ProgressScreen(key: _progressKey),
      ProfileScreen(key: _profileKey),
      const SettingsScreen(),
    ];
  }

  void _openStage(int index) {
    setState(() {
      _stageIndex = index;
      _stageLoading = true;
    });
    _loadStagePlan(index);
  }

  void _onDiaryWeightChanged() {
    _profileKey.currentState?.refresh();
    _progressKey.currentState?.refresh();
  }

  Future<void> _loadStagePlan(int stageIndex) async {
    setState(() => _stageLoading = true);
    // Сохраняем текущий этап и дату старта для дневника
    await ProfileService.setStage(stageIndex + 1);
    final restricted = await ProfileService.loadRestricted();
    var plan = await PlanCacheService.load(stageIndex, restricted);
    // Если кеш пуст — генерируем на лету
    if (plan == null) {
      plan = generateStagePlan(stageIndex, restricted);
      await PlanCacheService.save(stageIndex, plan, restricted);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screenList,
          ),
          if (_stageIndex != null)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: _buildStageContent(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: StyledBottomNav(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() {
            if (_stageIndex != null) {
              _stageIndex = null;
              _currentPlan = null;
            }
            _selectedIndex = i;
          });
          if (i == 1) _diaryKey.currentState?.refresh();
          if (i == 2) _progressKey.currentState?.refresh();
          if (i == 3) _profileKey.currentState?.refresh();
        },
      ),
    );
  }

  Widget _buildStageContent() {
    if (_stageLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final plan = _currentPlan;
    if (plan == null || plan.isEmpty) {
      return const Center(child: Text('Не удалось загрузить меню'));
    }
    return StagePlanScreen(
      stageIndex: _stageIndex!,
      plan: plan,
      onBack: _closeStage,
    );
  }
}

class _HomePage extends StatelessWidget {
  final void Function(int index)? onOpenStage;

  const _HomePage({this.onOpenStage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tipOfDay = TipsData.getRandom();

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: ThemeProvider.headerGradient,
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Привет! 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Продолжай двигаться к своей цели',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFFE53935),
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
                          builder: (_) => const MethodScreen(),
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
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Обязательно к прочтению',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Этапы методики',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _StageCard(
                  emoji: '\u{1F3C3}',
                  name: 'Подготовительный',
                  duration: '14 дней',
                  color: const Color(0xFFFF9800),
                  onTap: () => onOpenStage?.call(0),
                ),
                _StageCard(
                  emoji: '\u{1F4AA}',
                  name: 'Основной',
                  duration: '21 день',
                  color: const Color(0xFF2E7D32),
                  onTap: () => onOpenStage?.call(1),
                ),
                _StageCard(
                  emoji: '\u{1F3AF}',
                  name: 'Закрепительный',
                  duration: '14 дней',
                  color: const Color(0xFF1976D2),
                  onTap: () => onOpenStage?.call(2),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE082), Color(0xFFFFD54F)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 32, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Совет дня',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipOfDay,
                              style: TextStyle(
                                color: Colors.brown.shade800,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String duration;
  final Color color;
  final VoidCallback onTap;

  const _StageCard({
    required this.emoji,
    required this.name,
    required this.duration,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 6)),
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
