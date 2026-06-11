import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_diet/screens/food_restrictions_screen.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран профиля — дизайн 1:1 из Figma
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenMethodologies;

  const ProfileScreen({super.key, this.onOpenMethodologies});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _loading = true;

  // Данные
  String _name = '';
  double _height = 0;
  double _weight = 0;
  double _targetWeight = 0;
  double _startWeight = 0;
  DateTime? _birthDate;
  File? _photoFile; // Фото профиля
  List<String> _earnedMedals = [];

  // Контроллеры для редактирования
  final _weightCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Публичный метод — вызвать при переключении на вкладку
  Future<void> refresh() => _load();

  Future<void> _load() async {
    final data = await ProfileService.load();
    final photo = await ProfileService.loadPhoto();
    final weightHistory = await ProfileService.loadWeightHistory();
    setState(() {
      _name = data['name'] as String;
      _height = data['height'] as double;
      _weight = data['weight'] as double;
      _targetWeight = data['targetWeight'] as double;
      _startWeight = data['startWeight'] as double;
      _birthDate = data['birthDate'] as DateTime?;
      _photoFile = photo;

      // Если startWeight не сохранился — берём первое значение из истории
      if (_startWeight <= 0 && weightHistory.isNotEmpty) {
        _startWeight = weightHistory.first;
      }
      // Если всё равно 0 — берём текущий
      if (_startWeight <= 0) _startWeight = _weight;

      _weightCtrl.text = _weight.toStringAsFixed(1);
      _targetCtrl.text = _targetWeight.toStringAsFixed(1);
      _heightCtrl.text = _height.toStringAsFixed(0);

      _earnedMedals = _calcMedals();
      _loading = false;
    });
  }

  List<String> _calcMedals() {
    final lost = _startWeight - _weight;
    if (lost <= 0) return [];
    final medals = <String>[];
    if (lost >= 0.999) medals.add('🥉');
    final totalToLose = _startWeight - _targetWeight;
    if (totalToLose > 0) {
      if (lost >= totalToLose * 0.25 - 0.001) medals.add('🥈');
      if (lost >= totalToLose * 0.5 - 0.001) medals.add('🥇');
    }
    if (_weight <= _targetWeight) medals.add('🏆');
    return medals;
  }

  double get _bmi {
    if (_height <= 0) return 0;
    final h = _height / 100;
    return _weight / (h * h);
  }

  Color _bmiColor() {
    final b = _bmi;
    if (b <= 0) return Colors.grey;
    if (b < 25) return Colors.green;
    if (b < 30) return Colors.orange;
    return Colors.red;
  }

  int get _age {
    if (_birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  void _startEditing() {
    setState(() => _editing = true);
  }

  Future<void> _saveEditing() async {
    final w = double.tryParse(_weightCtrl.text) ?? _weight;
    final t = double.tryParse(_targetCtrl.text) ?? _targetWeight;
    final h = double.tryParse(_heightCtrl.text) ?? _height;

    await ProfileService.updateWeight(w);
    await ProfileService.updateTarget(t);
    await ProfileService.updateHeight(h);
    await ProfileService.updateName(_name);

    setState(() {
      _weight = w;
      _targetWeight = t;
      _height = h;
      _editing = false;
    });
  }

  /// Выбрать фото из галереи, сохранить и обновить UI
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    await ProfileService.savePhoto(file);
    setState(() => _photoFile = file);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _targetCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppGradientBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return AppGradientBackground(
      child: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Профиль',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_earnedMedals.isNotEmpty)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            _earnedMedals.join(' '),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  'Твои данные и цели',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Фото у левого края (отступ 4 сверху и 4 слева)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _bmiColor(),
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: _photoFile != null
                            ? Image.file(_photoFile!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.white,
                                alignment: Alignment.center,
                                child: Text(
                                  _name.isNotEmpty
                                      ? _name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: _bmiColor(),
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_age лет • ${_height.toStringAsFixed(0)} см',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_startWeight > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Стартовый вес: ${_startWeight.toStringAsFixed(1)} кг',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Квадратик ИМТ — та же структура, что и фото
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _bmiColor(),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ИМТ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _bmiColor(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _bmi > 0 ? _bmi.toStringAsFixed(1) : '—',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _bmiColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Параметры
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: ThemeProvider.orange, width: 6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Параметры',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 116,
                            height: 32,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _editing
                                      ? _saveEditing
                                      : _startEditing,
                                  style: TextButton.styleFrom(
                                    foregroundColor: ThemeProvider.orange,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _editing
                                            ? Icons.save_outlined
                                            : Icons.edit_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _editing ? 'Сохранить' : 'Изменить',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SizedBox(
                          height: _ParamRow._rowHeight * 3,
                          child: Column(
                            children: [
                              _ParamRow(
                                label: 'Текущий вес',
                                value: '${_weight.toStringAsFixed(1)} кг',
                                editing: _editing,
                                controller: _weightCtrl,
                                suffix: 'кг',
                              ),
                              _ParamRow(
                                label: 'Целевой вес',
                                value:
                                    '${_targetWeight.toStringAsFixed(1)} кг',
                                editing: _editing,
                                controller: _targetCtrl,
                                suffix: 'кг',
                              ),
                              _ParamRow(
                                label: 'Рост',
                                value: '${_height.toStringAsFixed(0)} см',
                                editing: _editing,
                                controller: _heightCtrl,
                                suffix: 'см',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Выбор методики
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onOpenMethodologies,
                    icon: const Icon(Icons.auto_stories_outlined, size: 20),
                    label: const Text('Выбор методики'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ThemeProvider.orange,
                      side: const BorderSide(
                        color: ThemeProvider.orange,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Кнопка редактирования списка запрещённых продуктов
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FoodRestrictionsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.no_food_outlined, size: 20),
                    label: const Text(
                      'Редактирование\nсписка запрещённых мне продуктов',
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B0000),
                      side: const BorderSide(
                        color: Color(0xFF8B0000),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ParamRow extends StatelessWidget {
  static const _rowHeight = 36.0;
  static const _fieldBoxWidth = 56.0;
  static const _fieldHeight = 28.0;
  static const _suffixSlotWidth = 24.0;
  static const _valueWidth =
      _fieldBoxWidth + 4 + _suffixSlotWidth; // 84

  final String label;
  final String value;
  final bool editing;
  final TextEditingController? controller;
  final String? suffix;

  const _ParamRow({
    required this.label,
    required this.value,
    this.editing = false,
    this.controller,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return SizedBox(
      height: _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _valueWidth,
            height: _rowHeight,
            child: editing && controller != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: _fieldBoxWidth,
                        height: _fieldHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x20FF9800),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0x40FF9800),
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          maxLines: 1,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: valueStyle,
                          decoration: const InputDecoration(
                            isDense: true,
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: _suffixSlotWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            suffix ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
