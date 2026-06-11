import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Тип оплаченной разблокировки.
enum PurchaseKind {
  premium,
  stage,
  allMethodologies,
}

/// Запись об успешной оплате T‑Банк (для проверки возвратов).
class PurchaseRecord {
  final String paymentId;
  final String orderId;
  final PurchaseKind kind;
  final String methodologyId;
  final int? stageIndex;
  final int amountKopecks;
  final bool revoked;

  const PurchaseRecord({
    required this.paymentId,
    required this.orderId,
    required this.kind,
    required this.methodologyId,
    this.stageIndex,
    required this.amountKopecks,
    this.revoked = false,
  });

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'orderId': orderId,
        'kind': kind.name,
        'methodologyId': methodologyId,
        if (stageIndex != null) 'stageIndex': stageIndex,
        'amountKopecks': amountKopecks,
        'revoked': revoked,
      };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) => PurchaseRecord(
        paymentId: json['paymentId'] as String,
        orderId: json['orderId'] as String,
        kind: PurchaseKind.values.byName(json['kind'] as String),
        methodologyId: json['methodologyId'] as String,
        stageIndex: json['stageIndex'] as int?,
        amountKopecks: json['amountKopecks'] as int,
        revoked: json['revoked'] as bool? ?? false,
      );

  PurchaseRecord copyWith({bool? revoked}) => PurchaseRecord(
        paymentId: paymentId,
        orderId: orderId,
        kind: kind,
        methodologyId: methodologyId,
        stageIndex: stageIndex,
        amountKopecks: amountKopecks,
        revoked: revoked ?? this.revoked,
      );
}

class PurchaseRecordService {
  PurchaseRecordService._();

  static const _key = 'payment_purchase_records';

  static Future<List<PurchaseRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PurchaseRecord>> loadActive() async {
    final all = await loadAll();
    return all.where((r) => !r.revoked).toList();
  }

  static Future<void> _saveAll(List<PurchaseRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  static Future<void> add(PurchaseRecord record) async {
    final records = await loadAll();
    records.removeWhere((r) => r.paymentId == record.paymentId);
    records.add(record);
    await _saveAll(records);
  }

  static Future<void> markRevoked(String paymentId) async {
    final records = await loadAll();
    final updated = records
        .map(
          (r) => r.paymentId == paymentId ? r.copyWith(revoked: true) : r,
        )
        .toList();
    await _saveAll(updated);
  }

  static Future<PurchaseRecord?> findByOrderId(String orderId) async {
    final records = await loadAll();
    for (final record in records) {
      if (record.orderId == orderId) return record;
    }
    return null;
  }

  static Future<bool> hasActivePremium(String methodologyId) async {
    final active = await loadActive();
    return active.any(
      (r) => r.kind == PurchaseKind.premium && r.methodologyId == methodologyId,
    );
  }

  static Future<bool> hasActiveAllMethodologies() async {
    final active = await loadActive();
    return active.any((r) => r.kind == PurchaseKind.allMethodologies);
  }

  static Future<bool> hasActiveStage(
    String methodologyId,
    int stageIndex,
  ) async {
    final active = await loadActive();
    return active.any(
      (r) =>
          r.kind == PurchaseKind.stage &&
          r.methodologyId == methodologyId &&
          r.stageIndex == stageIndex,
    );
  }
}
