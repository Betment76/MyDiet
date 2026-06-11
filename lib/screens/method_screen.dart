import 'package:flutter/material.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран «О методике» — принципы и правила
class MethodScreen extends StatelessWidget {
  const MethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ExpressGradientBackground(
        child: Column(
          children: [
            const MethodologyFixedHeader(
              title: 'О методике',
              subtitle: 'Обязательно к прочтению',
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                // Главный блок — без иконки, текст на всю ширину
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'О диете быстрой',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Диета быстрая разработана прежде всего для молодых '
                        'здоровых людей, не имеющих серьёзных хронических '
                        'заболеваний. Если ваш лишний вес составляет от 5 '
                        'до 10 кг — можете смело приступать. Если килограммов '
                        'десять и больше — лучше сначала обратиться к '
                        'врачу-диетологу и худеть под его контролем.\n\n'
                        'Рассчитана на 1–2 месяца и состоит из трёх '
                        'последовательных этапов: подготовительный (вход в '
                        'кетоз, 2 недели), основной (активное жиросжигание, '
                        'до 6 недель) и завершающий (плавный выход, 4+ '
                        'недели).\n\n'
                        'Главный принцип — резкое ограничение углеводов (до '
                        '40–60 г/день) при достаточном потреблении белка (до '
                        '400 г/день) и жиров (80–100 г/день). Это переводит '
                        'организм в состояние кетоза — он начинает сжигать '
                        'собственные жировые запасы вместо глюкозы.\n\n'
                        'Обязательные условия: утренняя ходьба 40–60 минут '
                        'натощак (самый важный элемент!), отруби 50 г/день '
                        'для нормальной работы кишечника, вода 30 мл/кг '
                        'веса, последний приём пищи за 3–4 часа до сна.\n\n'
                        'Нутриентная поддержка: L-карнитин по 1500 мг до и '
                        'после ходьбы, альфа-липоевая кислота, хром '
                        '(пиколинат) для снижения тяги к сладкому, '
                        'витаминно-минеральный комплекс. Взвешивание — раз '
                        'в неделю в одно и то же время. Полный отказ от '
                        'алкоголя на всех этапах.',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _PrincipleCard(
                  emoji: '🥩',
                  title: 'Белок — основа рациона',
                  desc:
                      'До 400 г мяса, птицы или рыбы в день. Яйца, творог, '
                      'кефир — ежедневно. Белок сохраняет мышцы и даёт сытость.',
                ),
                const SizedBox(height: 8),
                _PrincipleCard(
                  emoji: '🥦',
                  title: 'Минимум углеводов',
                  desc:
                      'Полное исключение сахара, мучного, круп на первых '
                      'этапах. Овощи — только низкоуглеводные (огурцы, капуста, '
                      'кабачки, зелень).',
                ),
                const SizedBox(height: 8),
                _PrincipleCard(
                  emoji: '🚶',
                  title: 'Ходьба — обязательно!',
                  desc:
                      '40–60 минут утренней ходьбы до завтрака — самый '
                      'важный элемент методики. Жиросжигание натощак в разы '
                      'эффективнее.',
                ),
                const SizedBox(height: 8),
                _PrincipleCard(
                  emoji: '💊',
                  title: 'Поддержка нутриентами',
                  desc:
                      'L-карнитин, альфа-липоевая кислота, хром (пиколинат) '
                      'и витаминно-минеральный комплекс ускоряют результат '
                      'и облегчают адаптацию.',
                ),

                const SizedBox(height: 24),

                _SectionCard(
                  icon: Icons.water_drop_outlined,
                  iconColor: Colors.blue,
                  title: 'Водный режим',
                  content:
                      '30 мл на 1 кг веса — ваша дневная норма воды. Вода '
                      'ускоряет метаболизм и помогает выводить продукты '
                      'жиросжигания (кетоны). Пейте равномерно в течение дня.',
                ),

                const SizedBox(height: 8),

                _SectionCard(
                  icon: Icons.bedtime_outlined,
                  iconColor: const Color(0xFF6A1B9A),
                  title: 'Режим сна',
                  content:
                      'Сон 6–8 часов, ложиться до 23:00. Качественный сон '
                      'нормализует уровень грелина и лептина — гормонов голода '
                      'и сытости, что значительно облегчает соблюдение диеты.',
                ),

                const SizedBox(height: 8),

                _SectionCard(
                  icon: Icons.fitness_center_outlined,
                  iconColor: const Color(0xFFFF5722),
                  title: 'Физическая активность',
                  content:
                      'Утренняя ходьба — необходимое условие. В течение дня '
                      'полезна любая активность: лёгкий бег, плавание, '
                      'велосипед. Силовые тренировки — умеренно, без '
                      'перегрузок. Активный отдых в выходные приветствуется.',
                ),

                const SizedBox(height: 32),

                // Противопоказания
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade400, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Кому нельзя применять эту диету',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Начинать диету нельзя в следующих случаях:\n\n'
                        '• любые хронические заболевания в стадии обострения\n'
                        '• камни в желчном пузыре или почках\n'
                        '• подагра\n'
                        '• беременность и первые полгода после родов\n'
                        '• возраст до 18 лет\n'
                        '• гиперурикемия (повышенный уровень мочевой кислоты)\n'
                        '• хроническая почечная недостаточность\n'
                        '• заболевания печени\n'
                        '• атеросклероз, инсульт или инфаркт в анамнезе\n'
                        '• период грудного вскармливания',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Дисклеймер
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Данная методика является ознакомительной. '
                          'Перед началом диеты проконсультируйтесь с врачом.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка-раздел с иконкой и текстом
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Лёгкая карточка-принцип
class _PrincipleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _PrincipleCard({
    required this.emoji,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _iconColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _iconColor {
    switch (emoji) {
      case '🥩':
        return const Color(0xFFE53935);
      case '🥦':
        return const Color(0xFF2E7D32);
      case '🚶':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9C27B0);
    }
  }
}
