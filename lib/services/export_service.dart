import 'package:share_plus/share_plus.dart';

/// Сервис экспорта прогресса
class ExportService {
  /// Поделиться статистикой прогресса
  static Future<void> shareProgress({
    required double startWeight,
    required double currentWeight,
    required double targetWeight,
    required int weeks,
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

    final message = '''
🏆 Моя диета — отчёт о прогрессе

📅 Длительность: $weeks недель
⚖️ Начальный вес: ${startWeight.toStringAsFixed(1)} кг
📍 Текущий вес: ${currentWeight.toStringAsFixed(1)} кг
🎯 Целевой вес: ${targetWeight.toStringAsFixed(1)} кг
📉 Сброшено: ${lost.toStringAsFixed(1)} кг ($lostPercent%)
$achievement

Методика доктора Ковалькова — поэтапное похудение без голодовок.
Присоединяйтесь! 💪
''';

    await SharePlus.instance.share(ShareParams(text: message));
  }
}
