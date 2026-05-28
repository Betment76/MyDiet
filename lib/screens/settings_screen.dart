import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/services/notification_service.dart';

/// Экран настроек — дизайн 1:1 из Figma
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _waterReminder = false;
  int _waterInterval = 60;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Градиент-хедер (как в Figma: linear-gradient(135deg, #2E7D32, #81C784))
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: ThemeProvider.headerGradient,
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Настройки',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Управляй приложением',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Основной контент с mt: 3 = 16px
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Внешний вид
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Иконка + заголовок, mb: 2 = 16px
                        Row(
                          children: [
                            const Icon(Icons.dark_mode_outlined,
                                color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Внешний вид',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        // Switch слева, текст справа (FormControlLabel)
                        Row(
                          children: [
                            _MuiSwitch(
                              value: themeProvider.isDark,
                              onChanged: (_) => themeProvider.toggle(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Тёмная тема',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Уведомления
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_outlined,
                                color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Уведомления',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _MuiSwitch(
                              value: _waterReminder,
                              onChanged: (val) {
                                setState(() => _waterReminder = val);
                                NotificationService().scheduleWaterReminders(
                                  enabled: val,
                                  intervalMinutes: _waterInterval,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Напоминания о воде',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                          if (_waterReminder) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Интервал напоминаний: $_waterInterval минут',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _waterInterval.toDouble(),
                            min: 30,
                            max: 180,
                            divisions: 10,
                            label: '$_waterInterval мин',
                            onChanged: (val) =>
                                setState(() => _waterInterval = val.toInt()),
                            onChangeEnd: (val) {
                              NotificationService().scheduleWaterReminders(
                                enabled: _waterReminder,
                                intervalMinutes: val.toInt(),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // О приложении
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'О приложении',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _InfoRow(
                            label: 'Версия приложения', value: '1.0.0'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'Последнее обновление',
                            value: 'Май 2026'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Кастомный Switch как в MUI — тонкий трек, маленький кружок, без тени
class _MuiSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MuiSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: value ? const Color(0xFF81C784) : Colors.grey.shade300,
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? const Color(0xFF2E7D32) : Colors.white,
            border: value ? null : Border.all(color: Colors.grey.shade400),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
