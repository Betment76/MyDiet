import 'package:flutter/material.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/screens/food_restrictions_screen.dart';

/// Экран первого запуска — дизайн 1:1 из Figma (зелёный фон, белая карточка)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _saving = false;
  bool _formatting = false;

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
    // Авто-расстановка точек в дате
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
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Парсим дату из текстового поля
    final parts = _birthDateCtrl.text.trim().split('.');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    _birthDate = DateTime(year, month, day);

    setState(() => _saving = true);
    await ProfileService.save(
      name: _nameCtrl.text.trim(),
      height: double.parse(_heightCtrl.text),
      weight: double.parse(_weightCtrl.text),
      birthDate: _birthDate!,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FoodRestrictionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: ThemeProvider.headerGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(32),
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
                      // Иконка приложения
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
                      // Название приложения под иконкой
                      Text(
                        'Моя Диета',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Добро пожаловать!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Начните свой путь к здоровью',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Имя
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
                      const SizedBox(height: 16),

                      // Рост
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
                          if (n == null || n < 80 || n > 250) return 'Рост от 80 до 250 см';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Вес
                      TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _greenInput.copyWith(
                          labelText: 'Вес (кг)',
                          prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Введите вес';
                          final n = double.tryParse(v);
                          if (n == null || n < 30 || n > 300) return 'Вес от 30 до 300 кг';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Дата рождения — текстовый ввод дд.мм.гггг
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
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                          ),
                          onPressed: _saving ? null : _submit,
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
                                  style: TextStyle(fontSize: 17),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
