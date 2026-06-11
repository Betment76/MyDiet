import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:my_diet/services/water_reminder_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Ключи для напоминаний
class ReminderPrefs {
  static const enabled = 'water_reminder_enabled';
  static const interval = 'water_reminder_interval'; // в минутах
  static const startHour = 'water_reminder_start_hour';
  static const endHour = 'water_reminder_end_hour';
  static const nextId = 'next_notification_id';
  static const pendingCount = 'pending_reminders_count';
}

/// Сервис локальных уведомлений для напоминаний о воде
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timeZoneReady = false;

  static const _notificationDetails = NotificationDetails(
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

  /// Инициализация
  Future<void> init() async {
    if (_initialized) return;

    await _ensureLocalTimeZone();

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

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
  }

  Future<void> _ensureLocalTimeZone() async {
    if (_timeZoneReady) return;
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
    _timeZoneReady = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Пользователь нажал на уведомление — можно показать экран воды
  }

  /// Перепланировать по сохранённым настройкам (старт приложения / возврат из фона).
  Future<void> rescheduleFromSavedSettings() async {
    final settings = await loadSettings();
    await scheduleWaterReminders(
      enabled: settings['enabled'] as bool,
      intervalMinutes: settings['interval'] as int,
      startHour: settings['startHour'] as int,
      endHour: settings['endHour'] as int,
    );
  }

  Future<bool> _requestPermissionsIfNeeded() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Показать одно уведомление о воде (immediate, без планирования)
  Future<void> showWaterReminder() async {
    await init();
    await _show(0, 'Пора выпить воды! 💧',
        'Не забывайте о водном балансе — 1,5–2 литра в день');
  }

  Future<void> _show(int id, String title, String body) async {
    await _plugin.show(id, title, body, _notificationDetails);
  }

  /// Запланировать напоминания на ближайшие 7 дней.
  /// Вызывать при изменении настроек и при старте приложения.
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

    await cancelAllReminders();

    if (!enabled) return;

    if (!enabledWindow(startHour, endHour, intervalMinutes)) return;

    final permitted = await _requestPermissionsIfNeeded();
    if (!permitted) return;

    await init();

    final slots = computeWaterReminderSlots(
      now: DateTime.now(),
      startHour: startHour,
      endHour: endHour,
      intervalMinutes: intervalMinutes,
    );
    if (slots.isEmpty) return;

    final baseId = ((prefs.getInt(ReminderPrefs.nextId) ?? 100) ~/ 100) * 100;
    await prefs.setInt(ReminderPrefs.nextId, baseId + 100);

    var id = baseId;
    for (final slot in slots) {
      await _scheduleOne(id, slot);
      id++;
    }

    await prefs.setInt(ReminderPrefs.pendingCount, slots.length);
  }

  Future<void> _scheduleOne(int id, DateTime time) async {
    final scheduledDate = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Пора выпить воды! 💧',
      'Не забывайте о водном балансе — 1,5–2 литра в день',
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Отменить все запланированные напоминания
  Future<void> cancelAllReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    final waterIds =
        pending.where((r) => r.id >= 100).map((r) => r.id).toList();
    for (final id in waterIds) {
      await _plugin.cancel(id);
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
