import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:my_diet/services/purchase_backup_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис резервного копирования и восстановления данных приложения.
///
/// Сохраняет все данные профиля и приложения (SharedPreferences)
/// в системную папку /Documents/MyDiet_copy/
class BackupService {
  BackupService._();

  static const _backupDirName = 'MyDiet_copy';
  static const _backupVersion = 2;
  static const _preferencesKey = 'preferences';
  static const _purchaseFlagsKey = 'purchase_flags';

  /// Папка резервных копий `/Documents/MyDiet_copy/`.
  static Future<Directory> getBackupDirectory() => _getBackupDir();

  /// JSON-файлы резервных копий, новые первыми.
  static Future<List<File>> listBackupFiles() async {
    try {
      final dir = await getBackupDirectory();
      if (!await dir.exists()) return [];

      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
          files.add(entity);
        }
      }

      files.sort((a, b) {
        final aTime = a.lastModifiedSync();
        final bTime = b.lastModifiedSync();
        return bTime.compareTo(aTime);
      });
      return files;
    } catch (_) {
      return [];
    }
  }

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
      final prefs = await SharedPreferences.getInstance();
      final preferences = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        preferences[key] = prefs.get(key);
      }

      final data = {
        'backup_version': _backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        _preferencesKey: preferences,
        _purchaseFlagsKey: await PurchaseBackupService.collectFlags(),
      };

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);

      final jsonFile = File('${dir.path}/my_diet_backup_$timestamp.json');
      await jsonFile.writeAsString(jsonEncode(data));

      return jsonFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Восстановить данные из файла на диске.
  static Future<bool> restoreFromPath(String path) async {
    return restoreFromFile(
      PlatformFile(
        path: path,
        name: path.split(Platform.pathSeparator).last,
        size: await File(path).length(),
      ),
    );
  }

  /// Выбор файла в папке резервных копий (или в файловом менеджере).
  static Future<String?> pickBackupFilePath() async {
    final backupDir = await getBackupDirectory();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      initialDirectory: backupDir.path,
      dialogTitle: 'Выберите резервную копию',
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    return file.path;
  }

  /// Восстановить данные из файла резервной копии (JSON)
  static Future<bool> restoreFromFile(PlatformFile pickedFile) async {
    try {
      final path = pickedFile.path;
      if (path == null || path.isEmpty) return false;
      final bytes = await File(path).readAsBytes();
      final json = utf8.decode(bytes);
      final decoded = jsonDecode(json);

      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('backup_version')) {
        return _restoreStructured(decoded);
      }
      if (decoded is Map<String, dynamic>) {
        return _restoreLegacy(decoded);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _restoreStructured(Map<String, dynamic> data) async {
    final preferences = data[_preferencesKey];
    if (preferences is! Map) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _applyPreferences(prefs, Map<String, dynamic>.from(preferences));

    final flags = data[_purchaseFlagsKey];
    if (flags is Map<String, dynamic>) {
      await PurchaseBackupService.applyFlags(flags);
    } else if (flags is Map) {
      await PurchaseBackupService.applyFlags(Map<String, dynamic>.from(flags));
    }

    return true;
  }

  static Future<bool> _restoreLegacy(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _applyPreferences(prefs, data);

    final flags = await PurchaseBackupService.collectFlags();
    await PurchaseBackupService.applyFlags(flags);
    return true;
  }

  static Future<void> _applyPreferences(
    SharedPreferences prefs,
    Map<String, dynamic> data,
  ) async {
    for (final entry in data.entries) {
      await _setPreference(prefs, entry.key, entry.value);
    }
  }

  static Future<void> _setPreference(
    SharedPreferences prefs,
    String key,
    Object? value,
  ) async {
    if (value == null) return;

    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is num) {
      final number = value.toDouble();
      if (number == number.roundToDouble()) {
        await prefs.setInt(key, number.toInt());
      } else {
        await prefs.setDouble(key, number);
      }
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is List) {
      await prefs.setStringList(
        key,
        value.map((e) => e.toString()).toList(),
      );
    }
  }
}
