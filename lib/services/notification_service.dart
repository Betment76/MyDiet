import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Инициализация
  Future<void> init() async {
    if (_initialized) return;

    // Инициализируем timezone
    tz.initializeTimeZones();

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

  void _onNotificationResponse(NotificationResponse response) {
    // Пользователь нажал на уведомление — можно показать экран воды
  }

  /// Показать одно уведомление о воде (immediate, без планирования)
  Future<void> showWaterReminder() async {
    await init();
    await _show(0, 'Пора выпить воды! 💧',
        'Не забывайте о водном балансе — 1,5–2 литра в день');
  }

  Future<void> _show(int id, String title, String body) async {
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

    await _plugin.show(id, title, body, details);
  }

  /// Запланировать повторяющиеся напоминания на сегодня
  /// и удалить старые. Вызывать при каждом изменении настроек.
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

    if (!enabled) {
      await cancelAllReminders();
      return;
    }

    // Отменяем все старые запланированные
    await cancelAllReminders();

    await init();

    // Планируем цепочку уведомлений на сегодня
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, startHour);
    final todayEnd = DateTime(now.year, now.month, now.day, endHour);

    // ID сдвигаем, чтобы не пересекались
    final baseId = ((prefs.getInt(ReminderPrefs.nextId) ?? 100) ~/ 100) * 100;
    await prefs.setInt(ReminderPrefs.nextId, baseId + 100);

    DateTime next = todayStart;
    var id = baseId;

    while (next.isBefore(todayEnd) || next.isAtSameMomentAs(todayEnd)) {
      if (next.isAfter(now)) {
        await _scheduleOne(id, next, intervalMinutes, startHour, endHour);
        id++;
      }
      next = next.add(Duration(minutes: intervalMinutes));
    }
  }

  /// Запланировать одно уведомление и при его показе —
  /// перезапланировать следующее на завтра.
  Future<void> _scheduleOne(
    int id,
    DateTime time,
    int intervalMinutes,
    int startHour,
    int endHour,
  ) async {
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

    final scheduledDate = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Пора выпить воды! 💧',
      'Не забывайте о водном балансе — 1,5–2 литра в день',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Отменить все запланированные напоминания
  Future<void> cancelAllReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    final waterIds = pending
        .where((r) => r.id >= 100)
        .map((r) => r.id)
        .toList();
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