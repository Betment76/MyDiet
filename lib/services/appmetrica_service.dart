import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:my_diet/constants/appmetrica_constants.dart';
import 'package:my_diet/services/disclaimer_service.dart';

/// Яндекс AppMetrica — аналитика (после согласия на обработку ПД).
class AppMetricaService {
  AppMetricaService._();

  static bool _activated = false;

  static bool get isActivated => _activated;

  /// Активировать SDK, если есть ключ и пользователь принял дисклеймер.
  static Future<void> initialize() async {
    if (_activated || !AppMetricaConstants.isConfigured) return;
    if (!await DisclaimerService.isAccepted()) return;

    try {
      await AppMetrica.activate(
        AppMetricaConfig(AppMetricaConstants.apiKey),
      );
      _activated = true;
      await reportEvent(kDebugMode ? 'app_debug_launch' : 'app_launch');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppMetrica activate failed: $e\n$st');
      }
    }
  }

  static Future<void> reportEvent(String name) async {
    if (!_activated) return;
    try {
      await AppMetrica.reportEvent(name);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppMetrica reportEvent($name) failed: $e');
      }
    }
  }
}
