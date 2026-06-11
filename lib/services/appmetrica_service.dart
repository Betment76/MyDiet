import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:my_diet/constants/app_version.dart';
import 'package:my_diet/constants/appmetrica_constants.dart';
import 'package:my_diet/constants/appmetrica_events.dart';
import 'package:my_diet/services/disclaimer_service.dart';
import 'package:my_diet/services/profile_service.dart';

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
        AppMetricaConfig(
          AppMetricaConstants.apiKey,
          appVersion: AppVersion.version,
          appBuildNumber: AppVersion.build,
          crashReporting: true,
          flutterCrashReporting: true,
          nativeCrashReporting: true,
          sessionsAutoTrackingEnabled: true,
          appOpenTrackingEnabled: true,
          advIdentifiersTracking: true,
          anrMonitoring: true,
          revenueAutoTrackingEnabled: true,
          dataSendingEnabled: true,
          logs: kDebugMode,
        ),
      ).timeout(const Duration(seconds: 10));

      if (!kIsWeb && Platform.isAndroid) {
        try {
          await AppMetrica.enableActivityAutoTracking();
        } catch (_) {}
      }

      await AppMetrica.putAppEnvironmentValue('app_version', AppVersion.full);

      _activated = true;
      await reportEvent(
        kDebugMode ? AppMetricaEvents.appDebugLaunch : AppMetricaEvents.appLaunch,
      );
      await syncUserProfileFromStorage();
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

  static Future<void> reportEventWithMap(
    String name,
    Map<String, Object> attributes,
  ) async {
    if (!_activated) return;
    try {
      await AppMetrica.reportEventWithMap(name, attributes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppMetrica reportEventWithMap($name) failed: $e');
      }
    }
  }

  static Future<void> reportScreenView(
    String screenName, {
    Map<String, Object>? params,
  }) async {
    await reportEventWithMap(AppMetricaEvents.screenView, {
      'screen': screenName,
      ...?params,
    });
  }

  static Future<void> reportDisclaimerAccepted() async {
    await reportEvent(AppMetricaEvents.disclaimerAccepted);
  }

  static Future<void> reportOnboardingCompleted() async {
    await reportEvent(AppMetricaEvents.onboardingCompleted);
    await syncUserProfileFromStorage();
  }

  static Future<void> reportTabSelected(String tab) async {
    await reportEventWithMap(AppMetricaEvents.tabSelected, {'tab': tab});
  }

  static Future<void> reportMethodologyOpened(String methodologyId) async {
    await reportEventWithMap(AppMetricaEvents.methodologyOpened, {
      'methodology_id': methodologyId,
    });
    try {
      await AppMetrica.putAppEnvironmentValue(
        'active_methodology',
        methodologyId,
      );
    } catch (_) {}
  }

  static Future<void> reportPaymentStarted({
    required String productId,
    required String purchaseKind,
    required int amountKopecks,
    String? methodologyId,
    int? stageIndex,
  }) async {
    await reportEventWithMap(AppMetricaEvents.paymentStarted, {
      'product_id': productId,
      'purchase_kind': purchaseKind,
      'amount_kopecks': amountKopecks,
      if (methodologyId != null) 'methodology_id': methodologyId,
      if (stageIndex != null) 'stage_index': stageIndex,
    });
  }

  static Future<void> reportPaymentSuccess({
    required String productId,
    required String purchaseKind,
    required int amountKopecks,
    required String orderId,
    required String paymentId,
    String? methodologyId,
    int? stageIndex,
  }) async {
    await reportEventWithMap(AppMetricaEvents.paymentSuccess, {
      'product_id': productId,
      'purchase_kind': purchaseKind,
      'amount_kopecks': amountKopecks,
      'order_id': orderId,
      'payment_id': paymentId,
      if (methodologyId != null) 'methodology_id': methodologyId,
      if (stageIndex != null) 'stage_index': stageIndex,
    });
    await reportRevenueRub(
      amountKopecks: amountKopecks,
      productId: productId,
      orderId: orderId,
      paymentId: paymentId,
    );
  }

  static Future<void> reportPaymentCancelled({
    required String productId,
    required String purchaseKind,
  }) async {
    await reportEventWithMap(AppMetricaEvents.paymentCancelled, {
      'product_id': productId,
      'purchase_kind': purchaseKind,
    });
  }

  static Future<void> reportPaymentFailed({
    required String productId,
    required String purchaseKind,
    Object? error,
  }) async {
    await reportEventWithMap(AppMetricaEvents.paymentFailed, {
      'product_id': productId,
      'purchase_kind': purchaseKind,
      if (error != null) 'error': error.toString(),
    });
    if (error != null) {
      await reportError('payment_failed', error: error);
    }
  }

  static Future<void> reportRevenueRub({
    required int amountKopecks,
    required String productId,
    String? orderId,
    String? paymentId,
    int quantity = 1,
  }) async {
    if (!_activated) return;
    try {
      final rubles = (amountKopecks / 100).toStringAsFixed(2);
      await AppMetrica.reportRevenue(
        AppMetricaRevenue(
          Decimal.parse(rubles),
          'RUB',
          quantity: quantity,
          productId: productId,
          payload: orderId == null
              ? null
              : jsonEncode({
                  'orderId': orderId,
                  if (paymentId != null) 'paymentId': paymentId,
                }),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppMetrica reportRevenue failed: $e');
      }
    }
  }

  static Future<void> reportInterstitialAd({
    required String adUnitId,
    String placement = 'unlock',
  }) async {
    await reportEventWithMap(AppMetricaEvents.adInterstitialShown, {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
    if (!_activated) return;
    try {
      await AppMetrica.reportAdRevenue(
        AppMetricaAdRevenue(
          adRevenue: Decimal.zero,
          currency: 'RUB',
          adType: AppMetricaAdType.interstitial,
          adNetwork: 'yandex',
          adUnitId: adUnitId,
          precision: 'publisher_defined',
          payload: {'placement': placement},
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppMetrica reportAdRevenue failed: $e');
      }
    }
  }

  static Future<void> reportInterstitialAdFailed({
    required String adUnitId,
    String? error,
    String placement = 'unlock',
  }) async {
    await reportEventWithMap(AppMetricaEvents.adInterstitialFailed, {
      'ad_unit_id': adUnitId,
      'placement': placement,
      if (error != null) 'error': error,
    });
  }

  static Future<void> reportError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!_activated) return;
    try {
      await AppMetrica.reportError(
        message: message,
        errorDescription: error != null
            ? AppMetricaErrorDescription.fromObjectAndStackTrace(
                error,
                stackTrace ?? StackTrace.current,
              )
            : AppMetricaErrorDescription.fromCurrentStackTrace(
                message: message,
              ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppMetrica reportError failed: $e');
      }
    }
  }

  static Future<void> syncUserProfileFromStorage() async {
    if (!_activated) return;
    try {
      final data = await ProfileService.load();
      final email = data['email'] as String? ?? '';
      if (email.isNotEmpty) {
        await AppMetrica.setUserProfileID('u_${email.hashCode.abs()}');
      }

      final name = data['name'] as String?;
      final birthDate = data['birthDate'] as DateTime?;
      final height = data['height'] as double?;
      final weight = data['weight'] as double?;
      final targetWeight = data['targetWeight'] as double?;
      final methodology = await ProfileService.getActiveMethodology();

      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile([
          if (name != null && name.isNotEmpty)
            AppMetricaNameAttribute.withValue(name),
          if (birthDate != null)
            AppMetricaBirthDateAttribute.withDate(birthDate),
          if (height != null && height > 0)
            AppMetricaNumberAttribute.withValue('height_cm', height),
          if (weight != null && weight > 0)
            AppMetricaNumberAttribute.withValue('current_weight_kg', weight),
          if (targetWeight != null && targetWeight > 0)
            AppMetricaNumberAttribute.withValue(
              'target_weight_kg',
              targetWeight,
            ),
          AppMetricaStringAttribute.withValue(
            'active_methodology',
            methodology,
          ),
        ]),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppMetrica syncUserProfile failed: $e');
      }
    }
  }
}
