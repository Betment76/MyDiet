// Экран загрузки — анимация 15 сек + советы по 3 сек
// Генерирует меню для всех трёх этапов

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/meal_plan_generator.dart';
import 'package:my_diet/services/plan_cache_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/theme_provider.dart';

/// Советы для всех этапов
const _allTips = [
  // Подготовительный этап
  'На подготовительном этапе исключите все быстрые углеводы: сахар, хлеб, макароны, рис, картофель.',
  'Пейте 30 мл воды на каждый кг веса. Вода ускоряет метаболизм и выводит токсины.',
  'Утром до завтрака — 40–60 минут ходьбы. Организм сжигает именно жиры на пустой желудок.',
  'Завтрак — кисломолочка с орехами и отрубями. Это основа подготовительного этапа.',
  'В течение дня съедайте 4 зелёных яблока и до 100 г отрубей, запивая водой.',
  'Ужин — только овощной салат с творогом. Никакого мяса на подготовительном этапе.',
  'Перед сном — 2 яичных белка. Чистый белок без жиров запускает ночное жиросжигание.',
  'Исключите сладкие фрукты: бананы, виноград, хурму. Только яблоки, груши, киви.',
  'Не голодайте! 5–6 приёмов пищи в день небольшими порциями.',
  'Отруби — обязательны. Клетчатка не даёт белку гнить в кишечнике и чистит организм.',
  'Молочные продукты стимулируют инсулин. Предпочитайте кефир и творог, а не молоко.',
  'Ложитесь спать до 23:00. Гормон роста, сжигающий жир, вырабатывается ночью.',
  'Кедровые орехи — идеальный перекус. 20 г подавляют аппетит на 2–3 часа.',
  'Не запивайте еду — пейте за 20 минут до или через час после еды.',
  'Хром в брокколи снижает тягу к сладкому. Ешьте брокколи каждый день.',
  // Основной этап
  'На основном этапе можно мясо, рыбу и птицу до 400 г в день.',
  'Загрузочный день раз в неделю — психологическая разгрузка, ешьте разрешённое без ограничений.',
  'L-карнитин 1500 мг до и после ходьбы усиливает жиросжигание.',
  'Контролируйте БЖУ: белок ≤100г, жиры 80-100г, углеводы 40-60г.',
  'Зелёные яблоки и грейпфруты — лучшие фрукты на основном этапе.',
  'Грибы можно 1–2 раза в неделю, бобовые — изредка.',
  'Орехи — горсть в день, но не увлекайтесь, они калорийны.',
  'Ходьба 40–60 мин ежедневно утром натощак — обязательно!',
  'Взвешивайтесь раз в неделю в одно и то же время.',
  // Завершающий этап
  'На завершающем этапе постепенно возвращайте привычные продукты.',
  'Цельнозерновой хлеб — до 2 кусочков в день.',
  'Тёмный шоколад (от 75% какао) можно до 30 г в день.',
  'При срыве — вернитесь на основной этап на 1–2 дня.',
  'Сахар больше не враг, но контролируйте его количество.',
  'Продолжайте ходьбу 3–4 раза в неделю для поддержания веса.',
  'Помните: это не диета, а новый образ жизни.',
];

class PlanLoadingScreen extends StatefulWidget {
  /// true — перегенерация при изменении запретов
  /// false — первая генерация после онбординга
  final bool isRegeneration;

  const PlanLoadingScreen({super.key, this.isRegeneration = false});

  @override
  State<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends State<PlanLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryTextColor = Color(0xFF3E2723);
  static const _secondaryTextColor = Color(0xFF5D4037);

  late AnimationController _animCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;

  int _tipIndex = 0;
  bool _tipVisible = true;
  double _progress = 0;

  Timer? _progressTimer;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );

    _startLoading();
  }

  void _startLoading() {
    final start = DateTime.now();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed >= 15000) {
        _progressTimer?.cancel();
        _tipTimer?.cancel();
        _finishLoading();
        return;
      }
      setState(() => _progress = elapsed / 15000);
    });

    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final next = (_tipIndex + 1) % _allTips.length;
      setState(() {
        _tipIndex = next;
        _tipVisible = false;
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _tipVisible = true);
      });
    });

    _generateAllPlans();
  }

  Future<void> _generateAllPlans() async {
    final restricted = await ProfileService.loadRestricted();
    for (int i = 0; i < 3; i++) {
      for (final id in [MethodologyIds.express, MethodologyIds.gourmets, MethodologyIds.fun, MethodologyIds.men, MethodologyIds.victory]) {
        final plan = generateStagePlan(id, i, restricted);
        await PlanCacheService.save(id, i, plan, restricted);
      }
    }
  }

  Future<void> _finishLoading() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _tipTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: ThemeProvider.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Анимированная иконка
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Transform.rotate(
                    angle: _rotateAnim.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              Text(
                widget.isRegeneration
                    ? 'Пересоздаём меню\nс вашими новыми предпочтениями'
                    : 'Составляем меню\nна все этапы',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _primaryTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                widget.isRegeneration
                    ? 'Обновляем список блюд...'
                    : 'Учитываем ваши ограничения...',
                style: const TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              // Прогресс-бар
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.brown.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation(_primaryTextColor),
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Советы с анимацией появления
              AnimatedOpacity(
                opacity: _tipVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: AnimatedSlide(
                  offset: _tipVisible
                      ? Offset.zero
                      : const Offset(0, 0.1),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 18,
                                color:
                                    _secondaryTextColor.withValues(alpha: 0.95)),
                            const SizedBox(width: 6),
                            const Text(
                              'Совет',
                              style: TextStyle(
                                fontSize: 12,
                                color: _secondaryTextColor,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _allTips[_tipIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _primaryTextColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
