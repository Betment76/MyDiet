/// Модель профиля пользователя
class UserProfile {
  String name;
  double currentWeight; // текущий вес в кг
  double targetWeight; // целевой вес в кг
  double height; // рост в см
  int currentStage; // текущий этап (1, 2, 3)
  DateTime stageStartDate; // дата начала текущего этапа
  List<double> weightHistory; // история взвешиваний
  List<DateTime> weightDates; // даты взвешиваний

  UserProfile({
    this.name = '',
    required this.currentWeight,
    required this.targetWeight,
    required this.height,
    this.currentStage = 1,
    DateTime? stageStartDate,
    List<double>? weightHistory,
    List<DateTime>? weightDates,
  })  : stageStartDate = stageStartDate ?? DateTime.now(),
        weightHistory = weightHistory ?? [currentWeight],
        weightDates = weightDates ?? [DateTime.now()];

  /// ИМТ (индекс массы тела)
  double get bmi {
    final h = height / 100;
    return currentWeight / (h * h);
  }

  /// Прогресс похудения в процентах
  double get progressPercent {
    final startWeight = weightHistory.first;
    final totalToLose = startWeight - targetWeight;
    if (totalToLose <= 0) return 100;
    final lost = startWeight - currentWeight;
    return (lost / totalToLose * 100).clamp(0, 100);
  }

  /// Сколько кг осталось сбросить
  double get remainingToLose =>
      (currentWeight - targetWeight).clamp(0, double.infinity);
}
