/// API-ключ AppMetrica из кабинета: Настройки → Основное.
/// https://appmetrica.yandex.ru/docs/ru/sdk/flutter/analytics/quick-start
abstract final class AppMetricaConstants {
  static const apiKey = '965a7327-532f-4184-98d3-94f0037804b5';

  static bool get isConfigured => apiKey.isNotEmpty;
}
