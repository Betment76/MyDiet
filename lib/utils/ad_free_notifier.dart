import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Глобальный статус «реклама отключена» (покупка / восстановление).
class AdFreeNotifier {
  static const _prefsKey = 'ads_free_purchased';

  static final ValueNotifier<bool> value = ValueNotifier<bool>(false);

  static Future<void> refreshFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isFree = prefs.getBool(_prefsKey) ?? false;
    if (value.value != isFree) value.value = isFree;
  }

  static Future<void> set(bool isFree) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isFree);
    if (value.value != isFree) value.value = isFree;
  }
}
