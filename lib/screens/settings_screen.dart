import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_diet/constants/app_links.dart';
import 'package:my_diet/screens/about_screen.dart';
import 'package:my_diet/screens/premium_screen.dart';
import 'package:my_diet/services/backup_service.dart';
import 'package:my_diet/services/export_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/widgets/common_widgets.dart';
import 'package:my_diet/services/notification_service.dart';
import 'package:my_diet/constants/appmetrica_events.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/services/purchase_verification_service.dart';

/// Экран настроек
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _waterReminder = false;
  int _waterInterval = 60;
  int _startHour = 8;
  int _endHour = 22;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await NotificationService().loadSettings();
    setState(() {
      _waterReminder = s['enabled'] as bool;
      _waterInterval = s['interval'] as int;
      _startHour = s['startHour'] as int;
      _endHour = s['endHour'] as int;
    });
  }

  Future<void> _createBackup() async {
    final path = await BackupService.createBackup();
    if (!mounted) return;
    if (path != null) {
      await AppMetricaService.reportEvent(AppMetricaEvents.backupCreated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Резервная копия сохранена:\n$path')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка создания резервной копии')),
      );
    }
  }

  Future<void> _restoreFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final ok = await BackupService.restoreFromFile(picked);
    if (!mounted) return;

    if (ok) {
      await AppMetricaService.reportEvent(AppMetricaEvents.backupRestored);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Данные восстановлены' : 'Ошибка восстановления'),
      ),
    );
  }

  Future<void> _shareApp() async {
    await ExportService.shareApp();
    await AppMetricaService.reportEvent(AppMetricaEvents.shareApp);
  }

  Future<void> _openAllApps() async {
    final uri = Uri.parse(AppLinks.rustoreDeveloperPage);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Показать диалог выбора часа (0–23)
  Future<int?> _showTimePickerDialog(int currentHour) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    return picked?.hour;
  }

  /// Выбор интервала напоминаний (панель снизу).
  Future<int?> _showIntervalPicker() async {
    const intervals = [30, 45, 60, 90, 120, 150, 180];
    return showAppBottomSheet<int>(
      context: context,
      title: 'Интервал напоминаний',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: intervals.map((m) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('$m мин'),
            trailing: _waterInterval == m
                ? const Icon(Icons.check, color: ThemeProvider.primaryGreen)
                : null,
            onTap: () => Navigator.pop(context, m),
          );
        }).toList(),
      ),
    );
  }

  void _schedule({int? interval, int? start, int? end}) {
    NotificationService().scheduleWaterReminders(
      enabled: _waterReminder,
      intervalMinutes: interval ?? _waterInterval,
      startHour: start ?? _startHour,
      endHour: end ?? _endHour,
    );
  }

  Future<void> _showRestorePurchasesDialog() async {
    final controller = TextEditingController();
    final orderId = await showAppBottomSheet<String?>(
      context: context,
      title: 'Восстановить покупки',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Введите номер заказа (Order ID), который вы получили после оплаты.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Номер заказа',
              hintText: 'Order ID',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Введите номер заказа')),
              );
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: const Text('Восстановить'),
        ),
      ],
    );
    controller.dispose();

    if (!mounted || orderId == null || orderId.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final outcome =
        await PurchaseVerificationService.restoreByOrderId(orderId);

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;
    if (outcome.success) {
      await AppMetricaService.reportEvent(AppMetricaEvents.purchaseRestored);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(outcome.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            child: const Text(
              'Настройки',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // --- Уведомления ---
                  _SettingsCard(
                    children: [
                      _SettingsSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: 'Напоминания о воде',
                        value: _waterReminder,
                        onChanged: (val) {
                          setState(() => _waterReminder = val);
                          _schedule();
                        },
                      ),
                      if (_waterReminder) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TimeRow(
                                label: 'Интервал',
                                value: '$_waterInterval мин',
                                onTap: () async {
                                  final picked = await _showIntervalPicker();
                                  if (picked != null) {
                                    setState(() => _waterInterval = picked);
                                    _schedule(interval: picked);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              _TimeRow(
                                label: 'Напоминать с',
                                value: '${_startHour.toString().padLeft(2, '0')}:00',
                                onTap: () async {
                                  final picked =
                                      await _showTimePickerDialog(_startHour);
                                  if (picked != null) {
                                    setState(() => _startHour = picked);
                                    _schedule(start: picked);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              _TimeRow(
                                label: 'Напоминать до',
                                value: '${_endHour.toString().padLeft(2, '0')}:00',
                                onTap: () async {
                                  final picked =
                                      await _showTimePickerDialog(_endHour);
                                  if (picked != null) {
                                    setState(() => _endHour = picked);
                                    _schedule(end: picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // --- Резервное копирование ---
                  _SettingsCard(
                    children: [
                      _SettingsButtonTile(
                        icon: Icons.save,
                        title: 'Создать файл',
                        onTap: _createBackup,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _SettingsButtonTile(
                        icon: Icons.file_download,
                        title: 'Восстановить из файла',
                        onTap: _restoreFromFile,
                      ),
                    ],
                  ),

                  // --- Действия (ПРЕМИУМ и прочее) ---
                  _SettingsCard(
                    children: [
                      SizedBox(
                        height: _kActionsBlockHeight,
                        child: Column(
                          children: [
                            Expanded(
                              child: _SettingsButtonTile(
                                icon: Icons.workspace_premium,
                                title: 'Купить ПРЕМИУМ',
                                fillHeight: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PremiumScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            Expanded(
                              child: _SettingsButtonTile(
                                icon: Icons.refresh,
                                title: 'Восстановить покупки',
                                fillHeight: true,
                                onTap: _showRestorePurchasesDialog,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            Expanded(
                              child: _SettingsButtonTile(
                                icon: Icons.share,
                                title: 'Поделиться приложением',
                                fillHeight: true,
                                onTap: _shareApp,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            Expanded(
                              child: _SettingsButtonTile(
                                icon: Icons.store,
                                title: 'Все приложения МойСофт.рф',
                                fillHeight: true,
                                onTap: _openAllApps,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            Expanded(
                              child: _SettingsButtonTile(
                                icon: Icons.info_outline,
                                title: 'О приложении',
                                fillHeight: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AboutScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Внутренние виджеты ────────────────────────────────────────────

const _kSettingsTileHeight = 48.0;
const _kActionsItemCount = 5;
const _kActionsDividerCount = 4;
const _kActionsBlockHeight =
    (_kSettingsTileHeight * _kActionsItemCount + _kActionsDividerCount) * 1.5;

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A27) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: ThemeProvider.primaryGreen, size: 22),
      activeTrackColor: ThemeProvider.primaryGreen,
      dense: true,
    );
  }
}

class _SettingsButtonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool fillHeight;

  const _SettingsButtonTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      children: [
        Icon(icon, color: ThemeProvider.primaryGreen, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Icon(
          Icons.chevron_right,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );

    if (fillHeight) {
      return InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: row,
          ),
        ),
      );
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: ThemeProvider.primaryGreen, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: ThemeProvider.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: ThemeProvider.primaryGreen,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}