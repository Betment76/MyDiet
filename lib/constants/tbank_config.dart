import 'package:flutter/foundation.dart';

/// Настройки терминала T‑Банка для «Моя диета».
/// Заполните перед включением оплаты. Оплата через RuStore не используется.
class TBankConfig {
  TBankConfig._();

  /// Тестовый терминал (debug-сборка).
  static const String debugTerminalKey = '1781066501056DEMO';
  static const String debugPassword = 'UV3r!ljnuW!t741A';

  /// Боевой терминал (release-сборка).
  static const String releaseTerminalKey = '1781066501077';
  static const String releasePassword = '*eGrGmMic^R3uFFC';

  static String get terminalKey =>
      kDebugMode ? debugTerminalKey : releaseTerminalKey;

  static String get password =>
      kDebugMode ? debugPassword : releasePassword;

  static bool get isConfigured =>
      terminalKey.isNotEmpty && password.isNotEmpty;
}
