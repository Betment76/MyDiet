import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_diet/constants/appmetrica_events.dart';
import 'package:my_diet/screens/food_restrictions_screen.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/services/backup_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/utils/ad_free_notifier.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран первого запуска — дизайн 1:1 из Figma (зелёный фон, белая карточка)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _saving = false;
  bool _restoring = false;
  bool _formatting = false;

  static const _fieldGap = 8.0;

  // Светло-зелёный полупрозрачный стиль полей
  static const _greenInput = InputDecoration(
    filled: true,
    fillColor: Color(0x2081C784), // 12% зелёный
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0x4081C784)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0x4081C784)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
    ),
  );

  @override
  void initState() {
    super.initState();
    _birthDateCtrl.addListener(_formatDate);
  }

  void _formatDate() {
    if (_formatting) return;
    _formatting = true;
    final text = _birthDateCtrl.text.replaceAll('.', '');
    if (text.length > 8) {
      _birthDateCtrl.text = text.substring(0, 8);
      _birthDateCtrl.selection = TextSelection.collapsed(offset: 8);
      _formatting = false;
      return;
    }
    final sb = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) sb.write('.');
      sb.write(text[i]);
    }
    final formatted = sb.toString();
    if (formatted != _birthDateCtrl.text) {
      _birthDateCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _formatting = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parts = _birthDateCtrl.text.trim().split('.');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    _birthDate = DateTime(year, month, day);

    setState(() => _saving = true);
    double parseWeight(String text) =>
        double.parse(text.trim().replaceAll(',', '.'));

    await ProfileService.save(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      height: parseWeight(_heightCtrl.text),
      weight: parseWeight(_weightCtrl.text),
      targetWeight: parseWeight(_targetWeightCtrl.text),
      birthDate: _birthDate!,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FoodRestrictionsScreen()),
    );
  }

  Future<void> _restoreFromBackup() async {
    setState(() => _restoring = true);
    try {
      final backups = await BackupService.listBackupFiles();
      if (!mounted) return;

      String? path;
      if (backups.isNotEmpty) {
        path = await showAppBottomSheet<String>(
          context: context,
          title: 'Резервные копии',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Папка MyDiet_copy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ...backups.map((file) {
                final name = file.path.split(Platform.pathSeparator).last;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.backup_outlined,
                    color: ThemeProvider.primaryGreen,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => Navigator.pop(context, file.path),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, '__browse__'),
              child: const Text('Другой файл…'),
            ),
          ],
        );
      } else {
        path = await BackupService.pickBackupFilePath();
      }

      if (!mounted || path == null) return;
      if (path == '__browse__') {
        path = await BackupService.pickBackupFilePath();
        if (!mounted || path == null) return;
      }

      final ok = await BackupService.restoreFromPath(path);
      if (!mounted) return;

      if (ok) {
        await AdFreeNotifier.refreshFromPrefs();
        await AppMetricaService.reportEvent(AppMetricaEvents.backupRestored);
        if (await ProfileService.exists()) {
          Navigator.of(context).pushReplacementNamed('/home');
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Данные восстановлены' : 'Ошибка восстановления',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: ThemeProvider.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/icon/icon512.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Моя Диета',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Добро пожаловать!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Начните свой путь к здоровью',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _greenInput.copyWith(
                          labelText: 'Ваше имя',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
                      ),
                      const SizedBox(height: _fieldGap),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: _greenInput.copyWith(
                          labelText: 'Электронная почта для чеков (необязательно)',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final email = v.trim();
                          final valid = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email);
                          if (!valid) {
                            return 'Введите корректный адрес почты';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldGap),

                      TextFormField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _greenInput.copyWith(
                          labelText: 'Рост (см)',
                          prefixIcon: const Icon(Icons.height),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Введите рост';
                          final n = double.tryParse(v);
                          if (n == null || n < 80 || n > 250) {
                            return 'Рост от 80 до 250 см';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldGap),

                      TextFormField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _greenInput.copyWith(
                          labelText: 'Текущий вес (кг)',
                          prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Введите текущий вес';
                          }
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n < 30 || n > 300) {
                            return 'Вес от 30 до 300 кг';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldGap),

                      TextFormField(
                        controller: _targetWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _greenInput.copyWith(
                          labelText: 'Целевой вес (кг)',
                          prefixIcon: const Icon(Icons.flag_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Введите целевой вес';
                          }
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n < 30 || n > 300) {
                            return 'Вес от 30 до 300 кг';
                          }
                          final current = double.tryParse(
                            _weightCtrl.text.replaceAll(',', '.'),
                          );
                          if (current != null && n >= current) {
                            return 'Целевой вес должен быть меньше текущего';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldGap),

                      TextFormField(
                        controller: _birthDateCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: _greenInput.copyWith(
                          labelText: 'Дата рождения',
                          hintText: 'дд.мм.гггг',
                          prefixIcon: const Icon(Icons.cake_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Введите дату рождения';
                          }
                          final parts = v.trim().split('.');
                          if (parts.length != 3) {
                            return 'Формат: дд.мм.гггг';
                          }
                          final day = int.tryParse(parts[0]);
                          final month = int.tryParse(parts[1]);
                          final year = int.tryParse(parts[2]);
                          if (day == null || month == null || year == null) {
                            return 'Формат: дд.мм.гггг';
                          }
                          if (day < 1 || day > 31 || month < 1 || month > 12) {
                            return 'Некорректная дата';
                          }
                          final date = DateTime(year, month, day);
                          if (date.isAfter(DateTime.now())) {
                            return 'Дата не может быть в будущем';
                          }
                          return null;
                        },
                      ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                    ),
                    onPressed: _saving || _restoring ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Начать',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton(
                    onPressed: _saving || _restoring ? null : _restoreFromBackup,
                    child: _restoring
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Восстановить из файла',
                            style: TextStyle(fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
