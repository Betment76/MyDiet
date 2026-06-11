import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_diet/data/stage_meal_data.dart';
import 'package:my_diet/services/meal_plan_generator.dart';
import 'package:my_diet/services/plan_cache_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/widgets/common_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран «Дневник» — календарь, калории, ходьба, вода
class DiaryScreen extends StatefulWidget {
  final VoidCallback? onWeightChanged;

  const DiaryScreen({super.key, this.onWeightChanged});

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen> {
  int _waterMl = 0;
  int _waterTotal = 0;
  int _walkMinutes = 0;
  static const _walkTotal = 60;

  double _currentWeight = 0;
  double _startWeight = 0;
  double _targetWeight = 0;

  bool _loading = true;
  int _todayCalories = 0;
  int _checkedCount = 0;
  int _totalMeals = 0;
  int _stageDay = 1;

  late DateTime _selectedDate;
  late List<DateTime> _allDays;
  late ScrollController _calendarCtrl;
  Timer? _midnightTimer;

  static const _pastDays = 365;
  static const _futureDays = 365;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _allDays = _buildAllDays();
    _calendarCtrl = ScrollController();
    _scrollTodayToLeft();
    _scheduleMidnightReset();
    _load();
  }

  @override
  void dispose() {
    _calendarCtrl.dispose();
    _midnightTimer?.cancel();
    super.dispose();
  }

  /// Запланировать сброс данных в 00:00
  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () {
      // Если экран открыт — перезагрузим данные для нового дня
      if (mounted) {
        _selectedDate = DateTime.now();
        _allDays = _buildAllDays();
        _scrollTodayToLeft();
        _load();
      }
      // Запланировать следующий сброс
      _scheduleMidnightReset();
    });
  }

  /// Построить массив дней: начиная с [past] дней назад
  List<DateTime> _buildAllDays() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - _pastDays);
    return List.generate(_pastDays + _futureDays + 1, (i) => start.add(Duration(days: i)));
  }

  /// Публичный метод — вызвать при переключении на вкладку
  Future<void> refresh() {
    _selectedDate = DateTime.now();
    _allDays = _buildAllDays();
    _scrollTodayToLeft();
    return _load();
  }

  void _scrollTodayToLeft() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = _pastDays; // сегодня — _pastDays-й элемент
      if (_calendarCtrl.hasClients) {
        // ширина элемента 48 + 3+3 margin = 54
        const itemWidth = 54.0;
        final vw = _calendarCtrl.position.viewportDimension;
        _calendarCtrl.jumpTo((idx * itemWidth) - vw + itemWidth);
      }
    });
  }

  Future<void> _load() async {
    int totalCal = 0;
    int checked = 0;
    int total = 0;
    int mealCount = 0;
    int water = 0;
    int walk = 0;

    // Текущий этап
    final methodologyId = await ProfileService.getActiveMethodology();
    int stageIdx = (await ProfileService.getStage(methodologyId: methodologyId)) - 1;
    if (stageIdx < 0 || stageIdx >= stagePlans.length) stageIdx = 0;

    final stageStart = await ProfileService.getStageStartDate(methodologyId: methodologyId);

    // Определяем день этапа для выбранной даты
    if (stageStart != null && stageIdx < stagePlans.length) {
      final diff = _selectedDate.difference(stageStart).inDays;
      mealCount = diff >= 0 ? diff + 1 : 1;
      if (diff >= 0) {
        final dayIndex = diff.clamp(0, stagePlans[stageIdx].length - 1);

        // Загружаем план
        final restricted = await ProfileService.loadRestricted();
        final plan = await PlanCacheService.load(methodologyId, stageIdx, restricted) ??
            generateStagePlan(methodologyId, stageIdx, restricted);

        if (plan.isNotEmpty && dayIndex < plan.length) {
          final currentDay = plan[dayIndex];
          total = currentDay.meals.length;

          // Загружаем отметки
          final prefs = await SharedPreferences.getInstance();
          final key = 'stage_${stageIdx}_progress';
          final stored = prefs.getString(key);
          final done = stored != null && stored.isNotEmpty
              ? Set<String>.from(List<String>.from(jsonDecode(stored)))
              : <String>{};

          for (var mi = 0; mi < currentDay.meals.length; mi++) {
            final meal = currentDay.meals[mi];
            final mealKey = 'stage${stageIdx}_day_${dayIndex}_meal_$mi';
            if (done.contains(mealKey)) {
              totalCal += meal.calories;
              checked++;
            }
          }
        }
      }
    }
    if (mealCount == 0) mealCount = 1;

    // Загружаем сохранённую воду для выбранной даты
    final dateKey = _dateKey(_selectedDate);
    final prefs = await SharedPreferences.getInstance();

    // Норма воды = вес × 30 мл (по книге)
    final profile = await ProfileService.load();
    final currentWeightVal = (profile['weight'] as double?) ?? 0;
    final startWeightVal = (profile['startWeight'] as double?) ?? currentWeightVal;
    final weight = currentWeightVal > 0 ? currentWeightVal : 60.0;
    final waterTotal = (weight * 30).round();
    final targetWeightVal = (profile['targetWeight'] as double?) ?? currentWeightVal;

    // Fallback: если раньше вода сохранялась по ключу water_today
    if (dateKey == _dateKey(DateTime.now())) {
      final oldVal = prefs.getDouble('water_today');
      if (oldVal != null && oldVal > 0 && !prefs.containsKey('water_$dateKey')) {
        water = (oldVal / 250).round() * 250;
        await prefs.setInt('water_$dateKey', water);
      } else {
        water = prefs.getInt('water_$dateKey') ?? 0;
      }
    } else {
      water = prefs.getInt('water_$dateKey') ?? 0;
    }

    // Загружаем ходьбу
    walk = prefs.getInt('walk_$dateKey') ?? 0;

    if (mounted) {
      setState(() {
        _todayCalories = totalCal;
        _checkedCount = checked;
        _totalMeals = total;
        _stageDay = mealCount;
        _waterMl = water;
        _waterTotal = waterTotal;
        _walkMinutes = walk;
        _currentWeight = currentWeightVal;
        _startWeight = startWeightVal;
        _targetWeight = targetWeightVal;
        _loading = false;
      });
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _loading = true;
    });
    _load();
  }

  void _addWater(int ml) async {
    final newVal = (_waterMl + ml).clamp(0, _waterTotal);
    setState(() => _waterMl = newVal);
    final dateKey = _dateKey(_selectedDate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_$dateKey', newVal);
  }

  void _addWalk(int min) async {
    final newVal = (_walkMinutes + min).clamp(0, _walkTotal);
    setState(() => _walkMinutes = newVal);
    final dateKey = _dateKey(_selectedDate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('walk_$dateKey', newVal);
  }

  void _addWeightChange(double grams) async {
    final newWeight = _currentWeight + (grams / 1000);
    if (newWeight <= 0) return;
    final newWaterTotal = (newWeight * 30).round();
    setState(() {
      _currentWeight = newWeight;
      _waterTotal = newWaterTotal;
    });
    await ProfileService.updateWeight(newWeight);
    widget.onWeightChanged?.call();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppGradientBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);

    final dateStr =
        '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}, ${_weekDay(_selectedDate.weekday)}';
    final isToday = sel == today;

    return AppGradientBackground(
      child: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Дневник',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      _monthNameCap(_selectedDate.month),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Календарь — бесконечная лента дней, сегодня у левого края
          SizedBox(
            height: 68,
            child: ListView.builder(
              controller: _calendarCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              itemCount: _allDays.length,
              itemBuilder: (context, index) {
                final d = _allDays[index];
                final dNorm = DateTime(d.year, d.month, d.day);
                final isSel = dNorm == sel;
                final isTodayDate = dNorm == today;
                final dayName = _shortDay(d.weekday);
                return GestureDetector(
                  onTap: () => _selectDate(d),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFF2E7D32)
                          : isTodayDate
                              ? Colors.green.shade50
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isTodayDate && !isSel
                          ? Border.all(color: const Color(0xFF2E7D32))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSel
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSel
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const SizedBox(height: 4),

                // Ходьба
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_walk,
                                color: Color(0xFF2E7D32), size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'Утренняя ходьба',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              '$_walkMinutes / $_walkTotal мин',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _walkTotal > 0
                                ? _walkMinutes / _walkTotal
                                : 0,
                            minHeight: 6,
                            backgroundColor: Colors.green.withValues(alpha: 0.15),
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [10, 30, 60].map((min) {
                            final enabled = isToday;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: enabled ? 4 : 0),
                                child: GestureDetector(
                                  onTap: enabled ? () => _addWalk(min) : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: enabled
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+$min мин',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: enabled
                                            ? const Color(0xFF2E7D32)
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Трекер воды
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'Трекер воды',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_waterMl / $_waterTotal мл',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _waterTotal > 0
                                ? _waterMl / _waterTotal
                                : 0,
                            minHeight: 6,
                            backgroundColor: Colors.blue.withValues(alpha: 0.15),
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [200, 250, 300].map((ml) {
                            final enabled = isToday;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: enabled ? 4 : 0),
                                child: GestureDetector(
                                  onTap: enabled ? () => _addWater(ml) : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: enabled
                                          ? Colors.blue.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+$ml мл',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: enabled
                                            ? Colors.blue
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (!isToday)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Редактировать воду можно только за сегодня',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Калории + прогресс
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Color(0xFFFF5722), size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '$_todayCalories ккал',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '$_checkedCount / $_totalMeals',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        isToday
                            ? Text(
                                'Сегодня',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Text(
                                'День $_stageDay',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _totalMeals > 0
                                ? _checkedCount / _totalMeals
                                : 0,
                            minHeight: 6,
                            backgroundColor:
                                Colors.orange.withValues(alpha: 0.15),
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Текущий вес
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monitor_weight_outlined,
                                color: Colors.purple.shade400, size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'Текущий вес',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              _weightString(_currentWeight),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _startWeight > _targetWeight
                                ? ((_currentWeight - _targetWeight) /
                                        (_startWeight - _targetWeight))
                                    .clamp(0.0, 1.0)
                                : 0,
                            minHeight: 6,
                            backgroundColor: Colors.purple.withValues(alpha: 0.15),
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final chip in [
                              (-50, '-50 г'),
                              (-100, '-100 г'),
                              (-300, '-300 г'),
                              (50, '+50 г'),
                              (100, '+100 г'),
                              (300, '+300 г'),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: GestureDetector(
                                    onTap: () => _addWeightChange(chip.$1.toDouble()),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        chip.$2,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _shortDay(int d) {
    const days = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[d];
  }

  String _weightString(double kg) {
    final whole = kg.floor();
    final grams = ((kg - whole) * 1000).round();
    if (grams == 0) return '$whole кг';
    return '$whole кг $grams г';
  }

  String _monthName(int m) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return months[m - 1];
  }

  String _monthNameCap(int m) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[m - 1];
  }

  String _weekDay(int d) {
    const days = [
      'понедельник', 'вторник', 'среда', 'четверг',
      'пятница', 'суббота', 'воскресенье'
    ];
    return days[d - 1];
  }
}
