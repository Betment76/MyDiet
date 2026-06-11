import 'package:flutter/foundation.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/utils/ad_free_notifier.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Сервис межстраничной рекламы Яндекс Mobile Ads SDK.
/// https://ads.yandex.com/helpcenter/ru/dev/flutter/interstitial
class YandexAdsService {
  static final YandexAdsService _instance = YandexAdsService._internal();
  factory YandexAdsService() => _instance;
  YandexAdsService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  InterstitialAdLoader? _interstitialAdLoader;
  String? _interstitialAdUnitId;
  bool _isInterstitialLoading = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await YandexAds.initialize();
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('Yandex Mobile Ads SDK инициализирован');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка инициализации Yandex Mobile Ads SDK: $e');
      }
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> loadAndShowInterstitial({
    required String adUnitId,
    VoidCallback? onAdDismissed,
  }) async {
    if (AdFreeNotifier.value.value) {
      onAdDismissed?.call();
      return;
    }

    if (!_isInitialized) {
      onAdDismissed?.call();
      return;
    }

    try {
      _interstitialAd?.destroy();
      _interstitialAd = null;
      _interstitialAdLoader = null;

      _interstitialAdLoader = InterstitialAdLoader();
      final ad = await _interstitialAdLoader!.loadAd(
        adRequest: AdRequest(adUnitId: adUnitId),
      );
      _interstitialAdUnitId = adUnitId;

      await ad.setAdEventListener(
        eventListener: InterstitialAdEventListener(
          onAdDismissed: () {
            ad.destroy();
            _interstitialAd = null;
            _interstitialAdLoader = null;
            onAdDismissed?.call();
          },
          onAdFailedToShow: (error) {
            if (kDebugMode) {
              debugPrint('Ошибка показа межстраничной рекламы: $error');
            }
            AppMetricaService.reportInterstitialAdFailed(
              adUnitId: adUnitId,
              error: error.toString(),
            );
            ad.destroy();
            _interstitialAd = null;
            _interstitialAdLoader = null;
            onAdDismissed?.call();
          },
        ),
      );
      await ad.show();
      await AppMetricaService.reportInterstitialAd(adUnitId: adUnitId);
      await ad.waitForDismiss();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки межстраничной рекламы: $e');
      }
      AppMetricaService.reportInterstitialAdFailed(
        adUnitId: adUnitId,
        error: e.toString(),
      );
      _interstitialAd = null;
      _interstitialAdLoader = null;
      onAdDismissed?.call();
    }
  }

  Future<void> preloadInterstitial({required String adUnitId}) async {
    if (AdFreeNotifier.value.value || !_isInitialized) return;
    if (_interstitialAd != null || _isInterstitialLoading) return;

    try {
      _isInterstitialLoading = true;
      _interstitialAdLoader = InterstitialAdLoader();
      final ad = await _interstitialAdLoader!.loadAd(
        adRequest: AdRequest(adUnitId: adUnitId),
      );
      _interstitialAd = ad;
      _interstitialAdUnitId = adUnitId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка предзагрузки межстраничной рекламы: $e');
      }
      _interstitialAd = null;
    } finally {
      _isInterstitialLoading = false;
    }
  }

  Future<bool> showPreloadedInterstitialIfAvailable({
    required String adUnitId,
    VoidCallback? onAdDismissed,
  }) async {
    if (AdFreeNotifier.value.value || !_isInitialized) {
      onAdDismissed?.call();
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null || _interstitialAdUnitId != adUnitId) {
      onAdDismissed?.call();
      return false;
    }

    _interstitialAd = null;
    _interstitialAdLoader = null;

    try {
      await ad.setAdEventListener(
        eventListener: InterstitialAdEventListener(
          onAdDismissed: () {
            ad.destroy();
            onAdDismissed?.call();
          },
          onAdFailedToShow: (error) {
            if (kDebugMode) {
              debugPrint('Ошибка показа предзагруженной рекламы: $error');
            }
            AppMetricaService.reportInterstitialAdFailed(
              adUnitId: adUnitId,
              error: error.toString(),
            );
            ad.destroy();
            onAdDismissed?.call();
          },
        ),
      );
      await ad.show();
      await AppMetricaService.reportInterstitialAd(adUnitId: adUnitId);
      await ad.waitForDismiss();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка показа предзагруженной рекламы: $e');
      }
      AppMetricaService.reportInterstitialAdFailed(
        adUnitId: adUnitId,
        error: e.toString(),
      );
      ad.destroy();
      onAdDismissed?.call();
      return false;
    }
  }

  void dispose() {
    _interstitialAd?.destroy();
    _interstitialAd = null;
    _interstitialAdLoader = null;
    _interstitialAdUnitId = null;
    _isInterstitialLoading = false;
  }
}
