/// Расчёт слотов напоминаний о воде (чистая логика для тестов и планировщика).
List<DateTime> computeWaterReminderSlots({
  required DateTime now,
  required int startHour,
  required int endHour,
  required int intervalMinutes,
  int daysAhead = 7,
}) {
  if (!enabledWindow(startHour, endHour, intervalMinutes)) {
    return const [];
  }

  final slots = <DateTime>[];
  final lastDay = DateTime(now.year, now.month, now.day)
      .add(Duration(days: daysAhead - 1));

  for (var day = DateTime(now.year, now.month, now.day);
      !day.isAfter(lastDay);
      day = day.add(const Duration(days: 1))) {
    final dayStart = DateTime(day.year, day.month, day.day, startHour);
    final dayEnd = DateTime(day.year, day.month, day.day, endHour);
    var next = dayStart;

    while (!next.isAfter(dayEnd)) {
      if (next.isAfter(now)) {
        slots.add(next);
      }
      next = next.add(Duration(minutes: intervalMinutes));
    }
  }

  return slots;
}

bool enabledWindow(int startHour, int endHour, int intervalMinutes) {
  if (intervalMinutes <= 0) return false;
  if (startHour < 0 || startHour > 23) return false;
  if (endHour < 0 || endHour > 23) return false;
  return startHour <= endHour;
}
