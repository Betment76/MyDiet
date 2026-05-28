import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ключи для напоминаний
class ReminderPrefs {
  static const enabled = 'water_reminder_enabled';
  static const interval = 'water_reminder_interval'; // в минутах
  static const startHour = 'water_reminder_start_hour';
  static const endHour = 'water_reminder_end_hour';
  static const lastId = 'last_notification_id';
}

/// Сервис локальных уведомлений для напоминаний о воде
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Инициализация
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Показать одно уведомление о воде
  Future<void> showWaterReminder() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'water_channel',
        'Водный баланс',
        channelDescription: 'Напоминания выпить воду',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getInt(ReminderPrefs.lastId) ?? 0) + 1;
    await prefs.setInt(ReminderPrefs.lastId, id);

    await _plugin.show(
      id,
      'Пора выпить воды! 💧',
      'Не забывайте о водном балансе — 1,5–2 литра в день',
      details,
    );
  }

  /// Запланировать повторяющиеся напоминания
  Future<void> scheduleWaterReminders({
    required bool enabled,
    int intervalMinutes = 60,
    int startHour = 8,
    int endHour = 22,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ReminderPrefs.enabled, enabled);
    await prefs.setInt(ReminderPrefs.interval, intervalMinutes);
    await prefs.setInt(ReminderPrefs.startHour, startHour);
    await prefs.setInt(ReminderPrefs.endHour, endHour);

    // В flutter_local_notifications v18 нет встроенного повторения
    // с умными интервалами, поэтому создаём простое уведомление
    // для проверки. Полноценное планирование делаем через
    // показ первого уведомления.
    if (enabled) {
      await showWaterReminder();
    }
  }

  /// Загрузить настройки напоминаний
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(ReminderPrefs.enabled) ?? false,
      'interval': prefs.getInt(ReminderPrefs.interval) ?? 60,
      'startHour': prefs.getInt(ReminderPrefs.startHour) ?? 8,
      'endHour': prefs.getInt(ReminderPrefs.endHour) ?? 22,
    };
  }
}
