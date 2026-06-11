import 'package:shared_preferences/shared_preferences.dart';

/// Согласие пользователя с дисклеймером приложения.
class DisclaimerService {
  DisclaimerService._();

  static const _disclaimerKey = 'disclaimer_accepted_v1';
  static const _pdConsentKey = 'pd_consent_accepted_v1';

  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_disclaimerKey) ?? false) &&
        (prefs.getBool(_pdConsentKey) ?? false);
  }

  static Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerKey, true);
    await prefs.setBool(_pdConsentKey, true);
  }
}
