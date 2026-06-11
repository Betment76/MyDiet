import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис резервного копирования и восстановления данных приложения.
///
/// Сохраняет все данные профиля и приложения (SharedPreferences)
/// в системную папку /Documents/MyDiet_copy/
class BackupService {
  static const _backupDirName = 'MyDiet_copy';

  /// Получить путь к папке /Documents/MyDiet_copy/
  static Future<Directory> _getBackupDir() async {
    // Пробуем системную папку Documents на общем хранилище
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final prefix = extDir.path.split('Android')[0];
        final dir = Directory('${prefix}Documents/$_backupDirName');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    } catch (_) {}

    // Fallback: app-документы
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_backupDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Создать файл резервной копии всех данных профиля и приложения
  static Future<String?> createBackup() async {
    try {
      final dir = await _getBackupDir();

      // Собираем все SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();
      final data = <String, dynamic>{};
      for (final key in allKeys) {
        data[key] = prefs.get(key);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);

      final json = jsonEncode(data);
      final jsonFile = File('${dir.path}/my_diet_backup_$timestamp.json');
      await jsonFile.writeAsString(json);

      return jsonFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Восстановить данные из файла резервной копии (JSON)
  static Future<bool> restoreFromFile(PlatformFile pickedFile) async {
    try {
      final bytes = await File(pickedFile.path!).readAsBytes();
      final json = utf8.decode(bytes);
      final data = jsonDecode(json) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List) {
          // Платформа возвращает List<dynamic>, преобразуем в List<String>
          await prefs.setStringList(key, value.cast<String>().toList());
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
