/// Версия приложения — синхронизировать с `pubspec.yaml` (version: X.Y.Z+N).
abstract final class AppVersion {
  static const version = '1.0.3';
  static const build = 4;

  static const full = '$version+$build';
  static const display = 'Версия $version';
  static const whatsNewTitle = 'Что нового в версии $version';
}
