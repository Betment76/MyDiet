import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:my_diet/constants/tbank_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис оплаты через T‑Банк (СБП / банковская карта).
class TBankPaymentService {
  static const String _baseUrl = 'https://securepay.tinkoff.ru/v2';
  static const String _lastPaymentIdKey = 'my_diet_last_payment_id';
  static const _requestTimeout = Duration(seconds: 20);

  Future<http.Response> _post(Uri uri, String body) {
    return http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_requestTimeout);
  }

  static String paymentSuccessDeeplink(String orderId) =>
      'app://payment/success/$orderId';

  static String paymentFailDeeplink(String orderId) =>
      'app://payment/fail/$orderId';

  static bool get isConfigured => TBankConfig.isConfigured;

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Терминал T‑Банка не настроен. Заполните lib/constants/tbank_config.dart',
      );
    }
  }

  String _generateToken(Map<String, dynamic> requestData) {
    final pairs = <MapEntry<String, String>>[];
    for (final entry in requestData.entries) {
      if (entry.key == 'Token' || entry.key == 'Receipt' || entry.key == 'DATA') {
        continue;
      }
      pairs.add(MapEntry(entry.key, entry.value.toString()));
    }
    pairs.add(MapEntry('Password', TBankConfig.password));
    pairs.sort((a, b) => a.key.compareTo(b.key));
    final tokenString = pairs.map((pair) => pair.value).join('');
    return sha256.convert(utf8.encode(tokenString)).toString().toLowerCase();
  }

  Future<Map<String, dynamic>> initiatePayment({
    required int amount,
    required String orderId,
    required String description,
    required String receiptItemName,
    required String email,
  }) async {
    _ensureConfigured();

    final requestData = <String, dynamic>{
      'TerminalKey': TBankConfig.terminalKey,
      'Amount': amount,
      'OrderId': orderId,
      'Description': description,
      'SuccessURL': paymentSuccessDeeplink(orderId),
      'FailURL': paymentFailDeeplink(orderId),
      'DATA': {'connection_type': 'Widget'},
      'Receipt': {
        'Email': email,
        'Taxation': 'usn_income',
        'Items': [
          {
            'Name': receiptItemName,
            'Price': amount,
            'Quantity': 1,
            'Amount': amount,
            'Tax': 'none',
          },
        ],
      },
    };

    final token = _generateToken(requestData);
    requestData['Token'] = token;

    final response = await _post(
      Uri.parse('$_baseUrl/Init'),
      jsonEncode(requestData),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ошибка: ${response.statusCode}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    if (responseData['Success'] == true) {
      return {
        'PaymentURL': responseData['PaymentURL'] as String,
        'PaymentId': responseData['PaymentId'] as String,
      };
    }
    throw Exception(
      'Ошибка инициации платежа: ${responseData['Message'] ?? 'Неизвестная ошибка'}',
    );
  }

  Future<String?> getQrPayload(String paymentId) async {
    _ensureConfigured();
    try {
      final requestData = <String, dynamic>{
        'TerminalKey': TBankConfig.terminalKey,
        'PaymentId': paymentId,
        'DataType': 'PAYLOAD',
      };
      requestData['Token'] = _generateToken(requestData);

      final response = await _post(
        Uri.parse('$_baseUrl/GetQr'),
        jsonEncode(requestData),
      );

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['Success'] == true && data['Data'] is String) {
        return data['Data'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> checkOrder(String orderId) async {
    _ensureConfigured();
    try {
      final requestData = <String, dynamic>{
        'TerminalKey': TBankConfig.terminalKey,
        'OrderId': orderId,
      };
      requestData['Token'] = _generateToken(requestData);

      final response = await _post(
        Uri.parse('$_baseUrl/CheckOrder'),
        jsonEncode(requestData),
      );

      if (response.statusCode != 200) {
        return {'Success': false, 'Message': 'HTTP ${response.statusCode}'};
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      String? status;
      String? paymentId;
      if (data['Payments'] is List && (data['Payments'] as List).isNotEmpty) {
        final first = (data['Payments'] as List).first as Map<String, dynamic>;
        status = first['Status'] as String?;
        paymentId = first['PaymentId']?.toString();
      } else {
        status = data['Status'] as String?;
        paymentId = data['PaymentId']?.toString();
      }

      return {
        'Success': data['Success'] == true,
        'Status': status,
        'PaymentId': paymentId,
        'Message': data['Message'] as String?,
      };
    } catch (e) {
      return {'Success': false, 'Message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    _ensureConfigured();
    final requestData = <String, dynamic>{
      'TerminalKey': TBankConfig.terminalKey,
      'PaymentId': paymentId,
    };
    requestData['Token'] = _generateToken(requestData);

    final response = await _post(
      Uri.parse('$_baseUrl/GetState'),
      jsonEncode(requestData),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ошибка: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> setLastPaymentId(String paymentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPaymentIdKey, paymentId);
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final file = File('${directory.path}/my_diet_payment_id.txt');
        await file.writeAsString(paymentId);
      }
    } catch (_) {}
  }

  Future<String?> getLastPaymentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPaymentIdKey);
  }

  Future<bool> isLastPaymentSuccessful() async {
    if (!isConfigured) return false;
    final paymentId = await getLastPaymentId();
    if (paymentId == null) return false;
    try {
      final status = await getPaymentStatus(paymentId);
      final paymentStatus = (status['Status'] as String?)?.toUpperCase();
      return paymentStatus == 'CONFIRMED' || paymentStatus == 'AUTHORIZED';
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkLastPaymentStatus() async => isLastPaymentSuccessful();
}
