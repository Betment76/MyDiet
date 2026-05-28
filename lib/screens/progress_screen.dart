import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_diet/data/stage_meal_data.dart';
import 'package:my_diet/services/export_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран прогресса — вес + прогресс по этапам
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  List<double> _weightPoints = [];
  List<DateTime> _weightDates = [];
  double _targetWeight = 0;
  double _startWeight = 0;
  double _currentWeight = 0;
  bool _loading = true;

  // Прогресс этапов
  final List<int> _stageCompleted = [0, 0, 0];
  final List<int> _stageTotal = [0, 0, 0];
  int _weeks = 0;

  int _selectedStage = 0; // 0/1/2 = конкретный этап
  Map<int, DateTime> _stageStarts = {};
  final _stageColors = [
    const Color(0xFFFF9800),
    const Color(0xFF2E7D32),
    const Color(0xFF1976D2),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Публичный метод — вызовите при возврате на экран прогресса
  Future<void> refresh() => _load();

  Future<void> _load() async {
    final data = await ProfileService.load();
    final history = await ProfileService.loadWeightHistory();
    final dates = await ProfileService.loadWeightDates();
    await _loadStageProgress();
    final stageStarts = await ProfileService.loadStageStartDates();

    // Fallback: если новая система пуста — берём из старой даты для текущего этапа
    final currentStage = await ProfileService.getStage();
    if (stageStarts.isEmpty) {
      final oldStart = await ProfileService.getStageStartDate();
      if (oldStart != null) {
        stageStarts[currentStage] = oldStart;
      }
    } else if (!stageStarts.containsKey(currentStage)) {
      // Текущий этап не сохранён в новой системе — берём из старой
      final oldStart = await ProfileService.getStageStartDate();
      if (oldStart != null) {
        stageStarts[currentStage] = oldStart;
      }
    }

    // Недели с первого взвешивания
    int weeks = 0;
    if (dates.length >= 2) {
      weeks = dates.last.difference(dates.first).inDays ~/ 7;
    }

    setState(() {
      _startWeight = data['startWeight'] as double;
      _currentWeight = history.isNotEmpty ? history.last : _startWeight;
      _weightPoints = history.isNotEmpty ? history : [_startWeight];
      _weightDates = dates.isNotEmpty ? dates : [DateTime.now()];
      _targetWeight = data['targetWeight'] as double;
      _weeks = weeks;
      _stageStarts = stageStarts;
      _selectedStage = currentStage - 1;
      _loading = false;
    });
  }

  Future<void> _loadStageProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (int stageIdx = 0; stageIdx < 3; stageIdx++) {
      final plan = stagePlans[stageIdx];
      int total = 0;
      for (final day in plan) {
        total += day.meals.length;
      }
      _stageTotal[stageIdx] = total;

      final stored = prefs.getString('stage_${stageIdx}_progress');
      if (stored != null && stored.isNotEmpty) {
        try {
          final list = List<String>.from(jsonDecode(stored));
          _stageCompleted[stageIdx] = list.length;
        } catch (_) {
          _stageCompleted[stageIdx] = 0;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final currentWeight = _weightPoints.last;
    final lost = _startWeight - currentWeight;

    final overallCompleted =
        _stageCompleted.fold(0, (a, b) => a + b);
    final overallTotal = _stageTotal.fold(0, (a, b) => a + b);
    final overallPercent =
        overallTotal > 0 ? overallCompleted / overallTotal : 0.0;

    final stageData = [
      (name: 'Подготовительный', emoji: '\u{1F3C3}', color: const Color(0xFFFF9800)),
      (name: 'Основной', emoji: '\u{1F4AA}', color: const Color(0xFF2E7D32)),
      (name: 'Закрепительный', emoji: '\u{1F3AF}', color: const Color(0xFF1976D2)),
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Градиент-хедер
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
                  'Ваш прогресс',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Отслеживай свои достижения',
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
              children: [
                const SizedBox(height: 16),

                // Герой-карточка (сброшенные кг)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${lost.toStringAsFixed(1)} кг',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'сброшено${_weeks > 0 ? ' за $_weeks ${_weekWord(_weeks)}' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Прогресс по этапам
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Прогресс по этапам',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(overallPercent * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: overallPercent,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(3, (i) {
                        final sd = stageData[i];
                        final completed = _stageCompleted[i];
                        final total = _stageTotal[i];
                        final percent = total > 0 ? completed / total : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StageProgressRow(
                            emoji: sd.emoji,
                            name: sd.name,
                            color: sd.color,
                            completed: completed,
                            total: total,
                            percent: percent,
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Grid 3 stats
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Начальный',
                        value: _startWeight.toStringAsFixed(1),
                        unit: 'кг',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Текущий',
                        value: currentWeight.toStringAsFixed(1),
                        unit: 'кг',
                        highlighted: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Цель',
                        value: _targetWeight.toStringAsFixed(1),
                        unit: 'кг',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // График веса с переключателем этапов
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.show_chart, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'График веса',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Кнопки выбора этапа
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        _StageChip(
                          label: '${i + 1}-й этап',
                          selected: _selectedStage == i,
                          color: _stageColors[i],
                          onTap: () => setState(() => _selectedStage = i),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (_buildFilteredPoints().length >= 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: SizedBox(
                      height: 250,
                      child: CustomPaint(
                        size: const Size(double.infinity, 250),
                        painter: _WeightChartPainter(
                          _buildFilteredPoints(),
                          minY: _targetWeight,
                          maxY: _startWeight,
                          stageDays: _selectedStage >= 0 && _selectedStage < stagePlans.length
                              ? stagePlans[_selectedStage].length
                              : null,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Для графика нужно минимум 2 замера',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 24),

                // Достижения — сетка 2×2
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        color: Colors.amber.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Достижения',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._buildAchievements(_startWeight, currentWeight, _targetWeight),

                const SizedBox(height: 16),

                // Кнопка «Поделиться»
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ExportService.shareProgress(
                      startWeight: _startWeight,
                      currentWeight: currentWeight,
                      targetWeight: _targetWeight,
                      weeks: _weeks,
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться результатом'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

  List<({int day, double weight})> _buildFilteredPoints() {
    // Этапы в SharedPreferences хранятся 1-индексированными
    final stageKey = _selectedStage + 1;

    // Определяем дату начала этапа
    final stageStart = _stageStarts[stageKey];
    if (stageStart == null) return [];

    // Берём только последнюю запись за день
    final dates = _weightDates;
    final weights = _weightPoints;
    final lastPerDay = <String, double>{};
    for (var i = 0; i < weights.length && i < dates.length; i++) {
      final key = '${dates[i].year}-${dates[i].month}-${dates[i].day}';
      lastPerDay[key] = weights[i];
    }

    // Восстанавливаем даты для lastPerDay (в порядке вставки)
    final distinctDates = lastPerDay.keys.map((k) {
      final p = k.split('-');
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    }).toList();
    final distinctWeights = lastPerDay.values.toList();

    final List<({int day, double weight})> result = [];

    // Конкретный этап
    final stageEnd = _stageStarts.containsKey(stageKey + 1)
        ? _stageStarts[stageKey + 1]!
        : DateTime(2099);

    // Начальный вес — в День 0
    result.add((day: 0, weight: _startWeight));

    for (var i = 0; i < distinctWeights.length; i++) {
      final date = i < distinctDates.length ? distinctDates[i] : DateTime.now();
      if (!date.isBefore(stageStart) && date.isBefore(stageEnd)) {
        final day = date.difference(stageStart).inDays + 1;
        result.add((day: day, weight: distinctWeights[i]));
      }
    }

    // Гарантируем минимум 2 точки (начальный вес + текущий)
    if (result.length < 2 && _currentWeight > 0) {
      final today = DateTime.now();
      final day = today.difference(stageStart).inDays + 1;
      result.add((day: day > 0 ? day : 1, weight: _currentWeight));
    }

    return result;
  }

  String _weekWord(int n) {
    if (n >= 5 && n <= 20) return 'недель';
    final last = n % 10;
    if (last == 1) return 'неделю';
    if (last >= 2 && last <= 4) return 'недели';
    return 'недель';
  }

  List<Widget> _buildAchievements(
      double start, double current, double target) {
    final totalToLose = start - target;
    final lost = start - current;

    if (totalToLose <= 0) {
      return [
        _AchievementGrid(
          icon: '🏆',
          title: 'Цель достигнута',
          achieved: current <= target,
        ),
      ];
    }

    final achievements = [
      _AchievementGrid(
        icon: '🥉',
        title: 'Первые 1 кг',
        achieved: lost >= 0.999,
      ),
      _AchievementGrid(
        icon: '🥈',
        title: 'Первые ${(totalToLose * 0.25).toStringAsFixed(1)} кг',
        achieved: lost >= totalToLose * 0.25 - 0.001,
      ),
      _AchievementGrid(
        icon: '🥇',
        title: 'Первые ${(totalToLose * 0.5).toStringAsFixed(1)} кг',
        achieved: lost >= totalToLose * 0.5 - 0.001,
      ),
      _AchievementGrid(
        icon: '🏆',
        title: 'Цель достигнута',
        achieved: current <= target,
      ),
    ];

    return [
      Row(
        children: [
          Expanded(child: achievements[0]),
          const SizedBox(width: 8),
          Expanded(child: achievements[1]),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: achievements[2]),
          const SizedBox(width: 8),
          Expanded(child: achievements[3]),
        ],
      ),
    ];
  }
}

/// Строка прогресса одного этапа
class _StageProgressRow extends StatelessWidget {
  final String emoji;
  final String name;
  final Color color;
  final int completed;
  final int total;
  final double percent;

  const _StageProgressRow({
    required this.emoji,
    required this.name,
    required this.color,
    required this.completed,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Мини-карточка статистики
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool highlighted;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.unit,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlighted ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: highlighted ? Colors.white : null,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: highlighted
                  ? Colors.white.withValues(alpha: 0.8)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка достижения
class _AchievementGrid extends StatelessWidget {
  final String icon;
  final String title;
  final bool achieved;

  const _AchievementGrid({
    required this.icon,
    required this.title,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achieved
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Text(icon, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        if (achieved)
          Positioned(
            top: -14,
            left: -14,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.blue.shade700.withValues(alpha: 0.7),
                    width: 2.5,
                  ),
                ),
              child: Center(
                child: Text(
                  'ПОЛУЧЕНО',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue.shade700,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ),
            ),
          ),
      ],
    );
  }
}

/// График веса (кастомная отрисовка) с фиксированной шкалой
class _WeightChartPainter extends CustomPainter {
  final List<({int day, double weight})> points;
  final double minY;
  final double maxY;
  final int? stageDays;

  _WeightChartPainter(this.points,
      {required this.minY, required this.maxY, this.stageDays});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final totalDays = stageDays ?? points.last.day;

    final linePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2E7D32).withValues(alpha: 0.3),
          const Color(0xFF2E7D32).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final range = (maxY - minY).clamp(0.1, double.infinity);

    // Сетка горизонтальная (5 линий)
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    const gridLines = 5;
    for (var i = 0; i <= gridLines; i++) {
      final y = size.height - 30 - (i / gridLines) * (size.height - 45);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Линия графика
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (points[i].day / totalDays) * size.width;
      final y =
          (1 - (points[i].weight - minY) / range) * (size.height - 30) + 15;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Точки
    for (var i = 0; i < points.length; i++) {
      final x = (points[i].day / totalDays) * size.width;
      final y =
          (1 - (points[i].weight - minY) / range) * (size.height - 30) + 15;
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = const Color(0xFF2E7D32),
      );
    }

    // Подписи по краям шкалы веса (вертикаль)
    final labelStyle =
        TextStyle(color: Colors.grey.shade500, fontSize: 10);
    final tp = TextPainter(
      text: TextSpan(text: minY.toStringAsFixed(1), style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(2, size.height - 20));
    tp.text = TextSpan(text: maxY.toStringAsFixed(1), style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(2, 4));

    // Дни — каждая 3-я точка
    tp.text = TextSpan(text: 'День 1', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(2, size.height - 10));
    tp.text = TextSpan(text: '$totalDays д.', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(size.width - tp.width - 2, size.height - 10));
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

/// Чип для переключения этапов
class _StageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StageChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}