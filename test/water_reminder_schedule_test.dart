import 'package:flutter_test/flutter_test.dart';
import 'package:my_diet/services/water_reminder_schedule.dart';

void main() {
  group('computeWaterReminderSlots', () {
    test('8–22 каждые 60 мин с 10:00 сегодня', () {
      final now = DateTime(2026, 6, 11, 10, 30);
      final slots = computeWaterReminderSlots(
        now: now,
        startHour: 8,
        endHour: 22,
        intervalMinutes: 60,
        daysAhead: 1,
      );

      expect(slots.first, DateTime(2026, 6, 11, 11, 0));
      expect(slots.last, DateTime(2026, 6, 11, 22, 0));
      expect(slots.length, 12); // 11..22 включительно
    });

    test('не включает прошедшее время', () {
      final now = DateTime(2026, 6, 11, 15, 45);
      final slots = computeWaterReminderSlots(
        now: now,
        startHour: 8,
        endHour: 22,
        intervalMinutes: 60,
        daysAhead: 1,
      );

      expect(slots.every((t) => t.isAfter(now)), isTrue);
      expect(slots.first, DateTime(2026, 6, 11, 16, 0));
    });

    test('планирует несколько дней вперёд', () {
      final now = DateTime(2026, 6, 11, 23, 0);
      final slots = computeWaterReminderSlots(
        now: now,
        startHour: 8,
        endHour: 10,
        intervalMinutes: 60,
        daysAhead: 3,
      );

      expect(slots, [
        DateTime(2026, 6, 12, 8, 0),
        DateTime(2026, 6, 12, 9, 0),
        DateTime(2026, 6, 12, 10, 0),
        DateTime(2026, 6, 13, 8, 0),
        DateTime(2026, 6, 13, 9, 0),
        DateTime(2026, 6, 13, 10, 0),
      ]);
    });

    test('некорректное окно — пустой список', () {
      expect(
        computeWaterReminderSlots(
          now: DateTime(2026, 6, 11, 12),
          startHour: 22,
          endHour: 8,
          intervalMinutes: 60,
        ),
        isEmpty,
      );
    });
  });
}
