import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/services/notification_service.dart';
import 'package:my_diet/services/purchase_verification_service.dart';
import 'package:my_diet/services/rustore_review_service.dart';
import 'package:my_diet/services/rustore_update_service.dart';
import 'package:my_diet/services/yandex_ads_service.dart';
import 'package:my_diet/utils/ad_free_notifier.dart';

/// Фоновая инициализация после первого кадра — не блокирует сплэш.
class AppBootstrap {
  AppBootstrap._();

  static bool _started = false;

  static void scheduleAfterFirstFrame({required bool disclaimerAccepted}) {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_run(disclaimerAccepted: disclaimerAccepted));
    });
  }

  static Future<void> _run({required bool disclaimerAccepted}) async {
    await _safe('YandexAds', () => YandexAdsService().initialize());
    await _safe('AdFreeNotifier', AdFreeNotifier.refreshFromPrefs);
    await _safe('Notifications.init', NotificationService().init);
    await _safe(
      'Notifications.schedule',
      NotificationService().rescheduleFromSavedSettings,
    );
    await _safe(
      'PurchaseVerification',
      PurchaseVerificationService.verifyAndSyncPurchases,
      timeout: const Duration(seconds: 20),
    );
    await _safe('RuStoreReview', RustoreReviewService.initialize);
    if (disclaimerAccepted) {
      await _safe('AppMetrica', AppMetricaService.initialize);
      await _safe('RuStoreUpdate', RustoreUpdateService.checkOnStartup);
    }
  }

  static Future<void> _safe(
    String name,
    Future<void> Function() action, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      await action().timeout(timeout);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Bootstrap $name failed: $e\n$st');
      }
    }
  }
}
