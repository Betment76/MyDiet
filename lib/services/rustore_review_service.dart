import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_rustore_review/flutter_rustore_review.dart';
import 'package:my_diet/constants/app_links.dart';
import 'package:my_diet/constants/appmetrica_events.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Результат запроса отзыва через RuStore SDK.
enum RustoreReviewResult {
  /// Нативное окно оценки показано.
  inAppShown,

  /// SDK недоступен — открыта страница приложения в каталоге.
  openedStorePage,
}

/// RuStore In-app Review SDK с запасным переходом в каталог.
class RustoreReviewService {
  RustoreReviewService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await RustoreReviewClient.initialize();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  /// Показывает in-app отзыв. При ошибке открывает страницу в RuStore.
  ///
  /// [hint] — короткое пояснение для SnackBar, если пришлось открыть каталог.
  static Future<({RustoreReviewResult result, String? hint})> requestReview() async {
    await AppMetricaService.reportEventWithMap(
      AppMetricaEvents.reviewRequested,
      {'source': 'rustore'},
    );

    if (kIsWeb || !Platform.isAndroid) {
      await _openStorePage();
      return (result: RustoreReviewResult.openedStorePage, hint: null);
    }

    if (!_initialized) {
      await initialize();
    }

    if (_initialized) {
      try {
        await RustoreReviewClient.request();
        await RustoreReviewClient.review();
        return (result: RustoreReviewResult.inAppShown, hint: null);
      } on PlatformException catch (e) {
        await _openStorePage();
        return (
          result: RustoreReviewResult.openedStorePage,
          hint: _hintForError(e.code),
        );
      } catch (_) {
        await _openStorePage();
        return (result: RustoreReviewResult.openedStorePage, hint: null);
      }
    }

    await _openStorePage();
    return (result: RustoreReviewResult.openedStorePage, hint: null);
  }

  static String? _hintForError(String code) {
    switch (code) {
      case 'RuStoreNotInstalledException':
        return 'Установите RuStore или оставьте отзыв на открывшейся странице';
      case 'RuStoreOutdatedException':
        return 'Обновите RuStore и попробуйте снова';
      case 'RuStoreUserUnauthorizedException':
        return 'Войдите в RuStore и попробуйте снова';
      case 'RuStoreRequestLimitReached':
        return 'Сегодня окно оценки уже показывалось — откройте отзыв на странице RuStore';
      case 'RuStoreReviewExists':
        return 'Вы уже оценивали приложение — откроем страницу в RuStore';
      default:
        return null;
    }
  }

  static Future<void> _openStorePage() async {
    final uri = Uri.parse(AppLinks.rustoreAppPage);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
