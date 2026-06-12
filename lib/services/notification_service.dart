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
  Future<bool> rescheduleFromSavedSettings() async {
    final settings = await loadSettings();
    return scheduleWaterReminders(
      enabled: settings['enabled'] as bool,
      intervalMinutes: settings['interval'] as int,
      startHour: settings['startHour'] as int,
      endHour: settings['endHour'] as int,
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Запрос разрешений на уведомления.
  /// [prompt] — при включении тумблера: всегда вызвать системный диалог Android 13+.
  Future<bool> requestPermissionsForReminders({bool prompt = false}) async {
    await init();

    if (!Platform.isAndroid) return true;

    final android = _android;
    if (android == null) return true;

    if (prompt) {
      await android.requestNotificationsPermission();
    } else {
      final alreadyEnabled = await android.areNotificationsEnabled();
      if (alreadyEnabled != true) {
        await android.requestNotificationsPermission();
      }
    }

    final enabled = await android.areNotificationsEnabled();
    if (enabled == false) return false;
    // null на Android < 13 — разрешение не требуется.
    return true;
  }

  Future<bool> _ensureAndroidNotificationPermission({bool prompt = false}) =>
      requestPermissionsForReminders(prompt: prompt);

  Future<bool> _ensureExactAlarmPermissionIfNeeded() async {
    if (!Platform.isAndroid) return true;

    final android = _android;
    if (android == null) return true;

    final canSchedule = await android.canScheduleExactNotifications();
    if (canSchedule == true) return true;

    await android.requestExactAlarmsPermission();
    final afterRequest = await android.canScheduleExactNotifications();
    return afterRequest ?? false;
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final android = _android;
    if (android == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final canExact = await android.canScheduleExactNotifications();
    return canExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
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
  /// Возвращает false, если включено, но запланировать не удалось (нет разрешений и т.п.).
  Future<bool> scheduleWaterReminders({
    required bool enabled,
    int intervalMinutes = 60,
    int startHour = 8,
    int endHour = 22,
    bool requestPermissionPrompt = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await cancelAllReminders();

    if (!enabled) {
      await prefs.setBool(ReminderPrefs.enabled, false);
      return true;
    }

    if (!enabledWindow(startHour, endHour, intervalMinutes)) {
      await prefs.setBool(ReminderPrefs.enabled, false);
      return false;
    }

    if (!await _ensureAndroidNotificationPermission(
      prompt: requestPermissionPrompt,
    )) {
      await prefs.setBool(ReminderPrefs.enabled, false);
      return false;
    }

    await _ensureExactAlarmPermissionIfNeeded();

    final slots = computeWaterReminderSlots(
      now: DateTime.now(),
      startHour: startHour,
      endHour: endHour,
      intervalMinutes: intervalMinutes,
    );
    if (slots.isEmpty) {
      await prefs.setBool(ReminderPrefs.enabled, false);
      return false;
    }

    final scheduleMode = await _androidScheduleMode();
    final baseId = ((prefs.getInt(ReminderPrefs.nextId) ?? 100) ~/ 100) * 100;
    await prefs.setInt(ReminderPrefs.nextId, baseId + 100);

    var id = baseId;
    for (final slot in slots) {
      await _scheduleOne(id, slot, scheduleMode);
      id++;
    }

    await prefs.setBool(ReminderPrefs.enabled, true);
    await prefs.setInt(ReminderPrefs.interval, intervalMinutes);
    await prefs.setInt(ReminderPrefs.startHour, startHour);
    await prefs.setInt(ReminderPrefs.endHour, endHour);
    await prefs.setInt(ReminderPrefs.pendingCount, slots.length);
    return true;
  }

  Future<void> _scheduleOne(
    int id,
    DateTime time,
    AndroidScheduleMode scheduleMode,
  ) async {
    final scheduledDate = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Пора выпить воды! 💧',
      'Не забывайте о водном балансе — 1,5–2 литра в день',
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: scheduleMode,
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
