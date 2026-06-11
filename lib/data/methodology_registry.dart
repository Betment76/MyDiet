import 'package:flutter/material.dart';
import 'package:my_diet/data/fun/fun_meal_data.dart';
import 'package:my_diet/data/fun/fun_stage_data.dart';
import 'package:my_diet/data/gourmet/gourmet_meal_data.dart';
import 'package:my_diet/data/gourmet/gourmet_stage_data.dart';
import 'package:my_diet/data/men/men_meal_data.dart';
import 'package:my_diet/data/men/men_stage_data.dart';
import 'package:my_diet/data/victory/victory_meal_data.dart';
import 'package:my_diet/data/victory/victory_stage_data.dart';
import 'package:my_diet/data/prep_plan_data.dart';
import 'package:my_diet/data/stage_data.dart';
import 'package:my_diet/data/stage_meal_data.dart';
import 'package:my_diet/models/stage_info.dart';

/// Идентификаторы методик приложения.
abstract final class MethodologyIds {
  static const express = 'express';
  static const gourmets = 'gourmets';
  static const fun = 'fun';
  static const men = 'men';
  static const victory = 'victory';
}

/// Метаданные методики для UI и сервисов.
class MethodologyConfig {
  final String id;
  final String title;
  final String subtitle;
  final List<StageInfo> stages;
  final List<List<PrepDay>> plans;
  final List<String> stageEmojis;
  final List<Color> stageColors;
  final List<String> stageCardNames;
  final List<String> stageDurations;
  final LinearGradient backgroundGradient;

  const MethodologyConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.stages,
    required this.plans,
    required this.stageEmojis,
    required this.stageColors,
    required this.stageCardNames,
    required this.stageDurations,
    required this.backgroundGradient,
  });
}

/// Единая точка доступа к данным всех методик.
class MethodologyRegistry {
  MethodologyRegistry._();

  static const _express = MethodologyConfig(
    id: MethodologyIds.express,
    title: 'Диета быстрая',
    subtitle: 'Поэтапное похудения для здоровых людей.',
    stages: StageData.stages,
    plans: stagePlans,
    stageEmojis: ['\u{1F3C3}', '\u{1F4AA}', '\u{1F3AF}'],
    stageColors: [
      Color(0xFFFF9800),
      Color(0xFF2E7D32),
      Color(0xFF1976D2),
    ],
    stageCardNames: ['Подготовительный', 'Основной', 'Завершающий'],
    stageDurations: ['14 дней', '21 день', '14 дней'],
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E7D32), Color(0xFF81C784), Colors.white],
      stops: [0.0, 0.35, 1.0],
    ),
  );

  static const _gourmets = MethodologyConfig(
    id: MethodologyIds.gourmets,
    title: 'Диета вкусная',
    subtitle: 'Вкусно и без строгих ограничений',
    stages: GourmetStageData.stages,
    plans: gourmetStagePlans,
    stageEmojis: ['\u{1F96C}', '\u{1F372}', '\u{1F3C6}'],
    stageColors: [
      Color(0xFFE65100),
      Color(0xFFBF360C),
      Color(0xFF6A1B9A),
    ],
    stageCardNames: ['Подготовительный', 'Основной', 'Завершающий'],
    stageDurations: ['14–21 день', 'до цели', '1–1,5 года'],
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE65100), Color(0xFFFFCC80), Colors.white],
      stops: [0.0, 0.35, 1.0],
    ),
  );

  static const _fun = MethodologyConfig(
    id: MethodologyIds.fun,
    title: 'Диета интересная',
    subtitle: 'Игровой подход к снижению веса',
    stages: FunStageData.stages,
    plans: funStagePlans,
    stageEmojis: ['\u{1F3AE}', '\u{1F37D}', '\u{2728}'],
    stageColors: [
      Color(0xFF7B1FA2),
      Color(0xFF512DA8),
      Color(0xFF283593),
    ],
    stageCardNames: ['Подготовительный', 'Основной', 'Завершающий'],
    stageDurations: ['2–3 недели', '3–6 месяцев', '1–1,5 года'],
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7B1FA2), Color(0xFFCE93D8), Colors.white],
      stops: [0.0, 0.35, 1.0],
    ),
  );

  static const _men = MethodologyConfig(
    id: MethodologyIds.men,
    title: 'Диета мужская',
    subtitle: 'Программа с учётом мужского метаболизма',
    stages: MenStageData.stages,
    plans: menStagePlans,
    stageEmojis: ['\u{1F3E5}', '\u{1F4AA}', '\u{1F3C6}'],
    stageColors: [
      Color(0xFF1565C0),
      Color(0xFF0D47A1),
      Color(0xFF37474F),
    ],
    stageCardNames: ['Подготовительный', 'Основной', 'Завершающий'],
    stageDurations: ['2–3 дня', 'до цели', '4–8 недель'],
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1565C0), Color(0xFF90CAF9), Colors.white],
      stops: [0.0, 0.35, 1.0],
    ),
  );

  static const _victory = MethodologyConfig(
    id: MethodologyIds.victory,
    title: 'Диета трудная',
    subtitle: 'Долгосрочная стратегия закрепления результата',
    stages: VictoryStageData.stages,
    plans: victoryStagePlans,
    stageEmojis: ['\u{1F331}', '\u{1F3C3}', '\u{1F3C6}'],
    stageColors: [
      Color(0xFFC62828),
      Color(0xFFB71C1C),
      Color(0xFF880E4F),
    ],
    stageCardNames: ['Подготовительный', 'Основной', 'Завершающий'],
    stageDurations: ['2–3 недели', 'до цели', '1–1,5 года'],
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC62828), Color(0xFFEF9A9A), Colors.white],
      stops: [0.0, 0.35, 1.0],
    ),
  );

  static const _all = [_express, _gourmets, _fun, _men, _victory];

  static MethodologyConfig get(String id) {
    for (final m in _all) {
      if (m.id == id) return m;
    }
    return _express;
  }

  static List<PrepDay> planFor(String methodologyId, int stageIndex) {
    final config = get(methodologyId);
    if (stageIndex < 0 || stageIndex >= config.plans.length) {
      return const [];
    }
    return config.plans[stageIndex];
  }

  static int dayCount(String methodologyId, int stageIndex) =>
      planFor(methodologyId, stageIndex).length;

  /// Префикс ключей SharedPreferences (express — без префикса для совместимости).
  static String storagePrefix(String methodologyId) =>
      methodologyId == MethodologyIds.express ? '' : '${methodologyId}_';
}
