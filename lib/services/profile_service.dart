import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_diet/models/meal_entry.dart';

/// Сервис для сохранения/загрузки профиля пользователя
class ProfileService {
  static const _prefix = 'profile_';
  static const _nameKey = '${_prefix}name';
  static const _heightKey = '${_prefix}height';
  static const _weightKey = '${_prefix}weight';
  static const _birthDateKey = '${_prefix}birth_date';
  static const _weightHistoryKey = '${_prefix}weight_history';
  static const _weightDatesKey = '${_prefix}weight_dates';
  static const _targetWeightKey = '${_prefix}target_weight';
  static const _startWeightKey = '${_prefix}start_weight';
  static const _profileExistsKey = '${_prefix}exists';
  static const _stageKey = '${_prefix}current_stage';
  static const _stageStartKey = '${_prefix}stage_start';
  static const _mealsKey = '${_prefix}meals';
  static const _restrictedKey = '${_prefix}restricted';

  static const _stageStartsKey = '${_prefix}stage_starts';

  /// Проверить, заполнен ли профиль
  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileExistsKey) ?? false;
  }

  /// Сохранить профиль (при первом запуске)
  static Future<void> save({
    required String name,
    required double height,
    required double weight,
    required DateTime birthDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Начальный вес сохраняется только один раз — при первом запуске
    final startAlreadySaved = prefs.containsKey(_startWeightKey);

    await prefs.setString(_nameKey, name);
    await prefs.setDouble(_heightKey, height);
    await prefs.setDouble(_weightKey, weight);
    await prefs.setString(_birthDateKey, birthDate.toIso8601String());

    // Целевой вес не сбрасываем, если он уже был установлен
    if (!prefs.containsKey(_targetWeightKey)) {
      await prefs.setDouble(_targetWeightKey, weight);
    }

    if (!startAlreadySaved) {
      await prefs.setDouble(_startWeightKey, weight);
    }

    // Добавляем первый вес в историю, только если её ещё нет
    if (!prefs.containsKey(_weightHistoryKey)) {
      await prefs.setString(_weightHistoryKey, weight.toString());
    }
    if (!prefs.containsKey(_weightDatesKey)) {
      await prefs.setString(
        _weightDatesKey,
        DateTime.now().toIso8601String(),
      );
    }

    await prefs.setBool(_profileExistsKey, true);
  }

  /// Загрузить профиль
  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final birthDateStr = prefs.getString(_birthDateKey) ?? '';

    double startWeight = prefs.getDouble(_startWeightKey) ?? 0;

    // Для старых профилей — берём из истории, если startWeight не сохранялся
    if (startWeight == 0) {
      final history = await loadWeightHistory();
      if (history.isNotEmpty) {
        startWeight = history.first;
        // Сохраняем, чтоб в следующий раз не вычислять
        await prefs.setDouble(_startWeightKey, startWeight);
      }
    }

    return {
      'name': prefs.getString(_nameKey) ?? '',
      'height': prefs.getDouble(_heightKey) ?? 0,
      'weight': prefs.getDouble(_weightKey) ?? 0,
      'startWeight': startWeight,
      'birthDate': birthDateStr.isNotEmpty ? DateTime.tryParse(birthDateStr) : null,
      'targetWeight': prefs.getDouble(_targetWeightKey) ?? 0,
    };
  }

  /// Посчитать возраст из даты рождения
  static int calcAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Обновить вес + добавить в историю
  static Future<void> updateWeight(double newWeight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weightKey, newWeight);

    final historyStr = prefs.getString(_weightHistoryKey) ?? '';
    final datesStr = prefs.getString(_weightDatesKey) ?? '';

    final history = historyStr.isEmpty
        ? <double>[]
        : historyStr.split(',').map((s) => double.tryParse(s) ?? 0).toList();
    final dates = datesStr.isEmpty
        ? <DateTime>[]
        : datesStr.split(',').map((s) => DateTime.tryParse(s) ?? DateTime.now()).toList();

    history.add(newWeight);
    dates.add(DateTime.now());

    await prefs.setString(_weightHistoryKey, history.join(','));
    await prefs.setString(_weightDatesKey, dates.map((d) => d.toIso8601String()).join(','));
  }

  /// Обновить целевой вес
  static Future<void> updateTarget(double target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_targetWeightKey, target);
  }

  /// Обновить рост
  static Future<void> updateHeight(double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_heightKey, height);
  }

  /// Обновить имя
  static Future<void> updateName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  /// Загрузить историю веса
  static Future<List<double>> loadWeightHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_weightHistoryKey) ?? '';
    if (str.isEmpty) return [];
    return str.split(',').map((s) => double.tryParse(s) ?? 0).toList();
  }

  /// Загрузить даты взвешиваний
  static Future<List<DateTime>> loadWeightDates() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_weightDatesKey) ?? '';
    if (str.isEmpty) return [];
    return str
        .split(',')
        .map((s) => DateTime.tryParse(s) ?? DateTime.now())
        .toList();
  }

  // --- Управление текущим этапом ---

  /// Сохранить текущий этап
  static Future<void> setStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stageKey, stage);
    await prefs.setString(_stageStartKey, DateTime.now().toIso8601String());
    // Сохраняем дату старта для конкретного этапа
    final raw = prefs.getString(_stageStartsKey);
    final starts = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    starts[stage.toString()] = DateTime.now().toIso8601String();
    await prefs.setString(_stageStartsKey, jsonEncode(starts));
  }

  /// Загрузить даты старта всех этапов (индекс = этап)
  static Future<Map<int, DateTime>> loadStageStartDates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stageStartsKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return map.map((k, v) => MapEntry(int.parse(k), DateTime.parse(v as String)));
  }

  /// Загрузить текущий этап (по умолчанию 1)
  static Future<int> getStage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stageKey) ?? 1;
  }

  /// Загрузить дату начала текущего этапа
  static Future<DateTime?> getStageStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_stageStartKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // --- Дневник питания (MealEntry) ---

  /// Сохранить приёмы пищи на дату
  static Future<void> saveMeals(DateTime date, List<MealEntry> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    final all = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    final key = _dateKey(date);
    all[key] = meals.map((m) => m.toJson()).toList();
    await prefs.setString(_mealsKey, jsonEncode(all));
  }

  /// Загрузить приёмы пищи на дату
  static Future<List<MealEntry>> loadMeals(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    if (raw == null) return [];
    final all = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final key = _dateKey(date);
    final list = all[key] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => MealEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Загрузить все приёмы пищи (сырые данные)
  static Future<Map<String, dynamic>> loadAllMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // --- Вода ---

  /// Норма воды по Ковалькову: 30 мл на 1 кг веса
  static double waterGoal(double currentWeight) =>
      (currentWeight * 30).clamp(1200, 4000);

  // --- Фото профиля ---

  /// Сохранить фото профиля (копирует файл в директорию приложения)
  static Future<void> savePhoto(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final saved = await image.copy('${dir.path}/profile_photo.jpg');
    // Даем права на чтение (особенно Android)
    await saved.setLastModified(DateTime.now());
  }

  /// Загрузить фото профиля (null если нет)
  static Future<File?> loadPhoto() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/profile_photo.jpg');
    if (await file.exists()) return file;
    return null;
  }

  // --- Запрещённые продукты пользователя ---

  /// Сохранить список запрещённых продуктов (JSON-массив строк)
  static Future<void> saveRestricted(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restrictedKey, jsonEncode(items));
  }

  /// Загрузить список запрещённых продуктов
  static Future<List<String>> loadRestricted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_restrictedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as String).toList();
  }

  // --- Вода ---

  /// Сохранить воду за сегодня
  static Future<void> saveWaterToday(double ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('water_today', ml);
  }

  /// Загрузить воду за сегодня
  static Future<double> loadWaterToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('water_today') ?? 0;
  }
}
