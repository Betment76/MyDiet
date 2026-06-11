import 'package:my_diet/constants/app_links.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:share_plus/share_plus.dart';

/// Сервис экспорта и шаринга
class ExportService {
  /// Поделиться ссылкой на приложение в RuStore.
  static Future<void> shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Приложение «Моя диета» — поэтапное похудение с умом! '
            'Скачай в RuStore: ${AppLinks.rustoreAppPage}',
      ),
    );
  }

  /// Поделиться прогрессом из сохранённого профиля.
  static Future<void> shareCurrentProgress() async {
    final data = await ProfileService.load();
    final history = await ProfileService.loadWeightHistory();
    final dates = await ProfileService.loadWeightDates();
    final methodologyId = await ProfileService.getActiveMethodology();
    final config = MethodologyRegistry.get(methodologyId);

    final startWeight = data['startWeight'] as double;
    final currentWeight =
        history.isNotEmpty ? history.last : data['weight'] as double;
    final targetWeight = data['targetWeight'] as double;

    var weeks = 0;
    if (dates.length >= 2) {
      weeks = dates.last.difference(dates.first).inDays ~/ 7;
    }

    await shareProgress(
      startWeight: startWeight,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      weeks: weeks,
      methodologyTitle: config.title,
    );
  }
  /// Поделиться статистикой прогресса
  static Future<void> shareProgress({
    required double startWeight,
    required double currentWeight,
    required double targetWeight,
    required int weeks,
    String? methodologyTitle,
  }) async {
    final lost = startWeight - currentWeight;
    final remaining = currentWeight - targetWeight;
    final lostPercent =
        startWeight - targetWeight > 0
            ? (lost / (startWeight - targetWeight) * 100).toStringAsFixed(1)
            : '100';

    final achievement = remaining > 0
        ? '⏳ Осталось: ${remaining.toStringAsFixed(1)} кг'
        : '\n✅ Цель достигнута!';

    final methodLine = methodologyTitle != null && methodologyTitle.isNotEmpty
        ? '📋 Методика: $methodologyTitle\n'
        : '';

    final message = '''
🏆 Моя диета — отчёт о прогрессе

$methodLine📅 Длительность: $weeks недель
⚖️ Начальный вес: ${startWeight.toStringAsFixed(1)} кг
📍 Текущий вес: ${currentWeight.toStringAsFixed(1)} кг
🎯 Целевой вес: ${targetWeight.toStringAsFixed(1)} кг
📉 Сброшено: ${lost.toStringAsFixed(1)} кг ($lostPercent%)
$achievement

Поэтапное похудение без голодовок — в приложении «Моя диета».
Присоединяйтесь! 💪
''';

    await SharePlus.instance.share(ShareParams(text: message));
  }
}
