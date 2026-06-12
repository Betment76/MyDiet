import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rustore_update/const.dart';
import 'package:flutter_rustore_update/flutter_rustore_update.dart';
import 'package:my_diet/constants/app_version.dart';
import 'package:my_diet/navigation/app_navigator.dart';

/// RuStore In-app Updates — проверка и установка новой версии.
///
/// Документация: https://www.rustore.ru/help/sdk/updates/flutter/10-0-0
class RustoreUpdateService {
  RustoreUpdateService._();

  static bool _listenerAttached = false;
  static bool _startupChecked = false;
  static bool _dialogVisible = false;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<void> checkOnStartup() async {
    if (!isSupported || _startupChecked) return;
    _startupChecked = true;
    await _checkAndPrompt();
  }

  /// Повторная проверка при возврате в приложение (например, докачка).
  static Future<void> checkOnResume() async {
    if (!isSupported) return;
    await _checkAndPrompt(onlyDownloaded: true);
  }

  static void _attachListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    RustoreUpdateClient.listener((state) {
      if (kDebugMode) {
        debugPrint(
          'RuStore update: status=${state.installStatus} '
          '${state.bytesDownloaded}/${state.totalBytesToDownload}',
        );
      }

      if (state.installStatus == INSTALL_STATUS_DOWNLOADED) {
        _showInstallReadyDialog();
      }
    });
  }

  static Future<void> _checkAndPrompt({bool onlyDownloaded = false}) async {
    try {
      final info = await RustoreUpdateClient.info().timeout(
        const Duration(seconds: 15),
      );

      if (info.updateAvailability != UPDATE_AILABILITY_AVAILABLE) return;

      if (info.installStatus == INSTALL_STATUS_DOWNLOADED) {
        await _showInstallReadyDialog();
        return;
      }

      if (onlyDownloaded) return;

      if (info.installStatus == INSTALL_STATUS_DOWNLOADING ||
          info.installStatus == INSTALL_STATUS_INSTALLING ||
          info.installStatus == INSTALL_STATUS_PENDING) {
        _attachListener();
        return;
      }

      await _showUpdateAvailableDialog(info.availableVersionCode);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RuStore update check failed: $e\n$st');
      }
    }
  }

  static Future<void> _showUpdateAvailableDialog(int availableVersionCode) async {
    if (_dialogVisible) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    _dialogVisible = true;
    try {
      final update = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Доступно обновление'),
          content: Text(
            'В RuStore доступна новая версия приложения '
            '(сборка $availableVersionCode, у вас ${AppVersion.build}).\n\n'
            'Обновите «Мою диету», чтобы получить исправления и улучшения.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Позже'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Обновить'),
            ),
          ],
        ),
      );

      if (update == true) {
        await _startDownload();
      }
    } finally {
      _dialogVisible = false;
    }
  }

  static Future<void> _showInstallReadyDialog() async {
    if (_dialogVisible) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    _dialogVisible = true;
    try {
      final install = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Обновление загружено'),
          content: const Text(
            'Новая версия готова к установке. Перезапустить приложение сейчас?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Позже'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Установить'),
            ),
          ],
        ),
      );

      if (install == true) {
        await _completeFlexibleUpdate();
      }
    } finally {
      _dialogVisible = false;
    }
  }

  static Future<void> _startDownload() async {
    _attachListener();
    try {
      final response = await RustoreUpdateClient.download();
      if (kDebugMode) {
        debugPrint('RuStore download result: ${response.code}');
      }
      if (response.code == ACTIVITY_RESULT_CANCELED) {
        return;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RuStore download failed: $e\n$st');
      }
    }
  }

  static Future<void> _completeFlexibleUpdate() async {
    try {
      await RustoreUpdateClient.completeUpdateFlexible();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RuStore completeUpdateFlexible failed: $e\n$st');
      }
    }
  }
}
