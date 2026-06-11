import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' show ClientException;
import 'package:my_diet/constants/ad_constants.dart';
import 'package:my_diet/services/tbank_payment_service.dart';
import 'package:my_diet/services/yandex_ads_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Экран ожидания оплаты T‑Банк (браузер / СБП).
class PaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String paymentId;
  final String orderId;
  final int amountKopecks;
  final String title;

  const PaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.paymentId,
    required this.orderId,
    required this.amountKopecks,
    required this.title,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  Timer? _statusCheckTimer;
  bool _paymentCompleted = false;
  bool _checkingOnClose = false;
  bool _browserOpened = false;
  final TBankPaymentService _paymentService = TBankPaymentService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startStatusCheckTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openPaymentInCustomTab());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_paymentCompleted) {
      unawaited(_verifyPaymentSuccess());
    }
  }

  String get _url {
    final uri = Uri.parse(widget.paymentUrl);
    if (uri.host == 'qr.nspk.ru') return widget.paymentUrl;
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'mobile': '1'})
        .toString();
  }

  Future<void> _openPaymentInCustomTab() async {
    if (_browserOpened || !mounted) return;
    final uri = Uri.parse(_url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть страницу оплаты'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
      return;
    }
    _browserOpened = true;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть браузер для оплаты'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  Future<void> _closeBrowser() async {
    try {
      await closeInAppWebView();
    } catch (_) {}
  }

  Future<String?> _getStateStatus() async {
    final data = await _paymentService.getPaymentStatus(widget.paymentId);
    if (data['Success'] != true) return null;
    final amount = data['Amount'];
    if (amount != null && (amount as num).toInt() != widget.amountKopecks) {
      return null;
    }
    return data['Status'] as String?;
  }

  Future<String?> _getStateWithNetworkRetry() async {
    try {
      return await _getStateStatus();
    } on SocketException {
      await Future.delayed(const Duration(seconds: 2));
      return _getStateStatus();
    } on ClientException {
      await Future.delayed(const Duration(seconds: 2));
      return _getStateStatus();
    }
  }

  Future<String?> _checkOrderStatus() async {
    final result = await _paymentService.checkOrder(widget.orderId);
    if (result['Success'] == true) {
      return result['Status'] as String?;
    }
    return null;
  }

  Future<String?> _checkOrderWithNetworkRetry() async {
    try {
      return await _checkOrderStatus();
    } on SocketException {
      await Future.delayed(const Duration(seconds: 2));
      return _checkOrderStatus();
    } on ClientException {
      await Future.delayed(const Duration(seconds: 2));
      return _checkOrderStatus();
    }
  }

  /// Сначала GetState; CheckOrder — если GetState недоступен (T‑Bank mobile).
  Future<String?> _fetchPaymentStatus() async {
    try {
      return await _getStateWithNetworkRetry();
    } on SocketException {
      return _checkOrderWithNetworkRetry();
    } on ClientException {
      return _checkOrderWithNetworkRetry();
    } catch (_) {
      return _checkOrderWithNetworkRetry();
    }
  }

  Future<void> _verifyPaymentSuccess() async {
    if (_paymentCompleted) return;
    try {
      final paymentStatus = (await _fetchPaymentStatus())?.toUpperCase();

      if (paymentStatus == 'CONFIRMED' || paymentStatus == 'AUTHORIZED') {
        _paymentCompleted = true;
        _statusCheckTimer?.cancel();
        await _paymentService.setLastPaymentId(widget.paymentId);
        await _closeBrowser();
        if (mounted) {
          await _showOrderIdDialog();
          if (mounted) Navigator.of(context).pop(true);
        }
      } else if (paymentStatus == 'CANCELLED' ||
          paymentStatus == 'REVERSED' ||
          paymentStatus == 'REFUNDED' ||
          paymentStatus == 'PARTIAL_REFUNDED' ||
          paymentStatus == 'REJECTED' ||
          paymentStatus == 'AUTH_FAIL') {
        _paymentCompleted = true;
        _statusCheckTimer?.cancel();
        await _closeBrowser();
        if (mounted) {
          await _showPaymentNotCompletedDialog();
          if (mounted) Navigator.of(context).pop(false);
        }
      }
    } catch (_) {}
  }

  Future<void> _closePaymentScreen() async {
    if (_checkingOnClose) return;
    setState(() => _checkingOnClose = true);
    _statusCheckTimer?.cancel();
    await _closeBrowser();

    if (!_paymentCompleted) {
      await _verifyPaymentSuccess();
    }

    if (!mounted || _paymentCompleted) return;

    final recovered = await _paymentService.checkLastPaymentStatus();
    if (!mounted || _paymentCompleted) return;

    if (!recovered) {
      await _showPaymentNotCompletedDialog();
    }
    if (!mounted || _paymentCompleted) return;
    Navigator.of(context).pop(recovered);
  }

  Future<void> _showPaymentNotCompletedDialog() async {
    if (!mounted) return;
    await showAppBottomSheet<void>(
      context: context,
      title: 'Оплата не произведена',
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: ThemeProvider.primaryGreen,
          ),
          child: const Text('Понятно'),
        ),
      ],
    );
    if (!mounted) return;
    await YandexAdsService().loadAndShowInterstitial(
      adUnitId: AdConstants.interstitialAdUnitId,
    );
  }

  Future<void> _showOrderIdDialog() async {
    if (!mounted) return;
    final orderId = widget.orderId;
    await showAppBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      title: 'Оплата успешно прошла',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Сохраните номер заказа:'),
          const SizedBox(height: 12),
          SelectableText(
            orderId,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: orderId));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Номер заказа скопирован')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Скопировать'),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: ThemeProvider.primaryGreen,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_paymentCompleted && mounted) {
        unawaited(_verifyPaymentSuccess());
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final amountRub = widget.amountKopecks / 100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_closePaymentScreen());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1B2A4A),
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: ThemeProvider.primaryGreen,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => unawaited(_closePaymentScreen()),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${amountRub.toStringAsFixed(0)} р',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white70),
                const SizedBox(height: 24),
                Text(
                  _checkingOnClose
                      ? 'Проверяем оплату…'
                      : 'Оплата открыта в браузере.\n'
                          'Завершите оплату и вернитесь в приложение.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
