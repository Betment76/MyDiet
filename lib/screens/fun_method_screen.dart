import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран «О методике» — Худеем интересно.
class FunMethodScreen extends StatelessWidget {
  const FunMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = MethodologyRegistry.get(MethodologyIds.fun);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MethodologyGradientBackground(
        gradient: config.backgroundGradient,
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                  _SectionCard(
                    title: 'Главная идея',
                    icon: Icons.restaurant_menu,
                    color: config.stageColors.first,
                    children: const [
                      _Bullet(
                        'Худеть нужно в кайф — снижение веса должно '
                        'приносить удовольствие, а не голод и скуку.',
                      ),
                      _Bullet(
                        'В методике собраны простые рецепты и примерный '
                        'график питания по дням — их можно комбинировать.',
                      ),
                      _Bullet(
                        'Базовые рецепты легко адаптировать под себя, '
                        'сохраняя вкус и пользу.',
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Три этапа',
                    icon: Icons.timeline,
                    color: config.stageColors[1],
                    children: const [
                      _Bullet(
                        '1. Подготовительный (2–3 недели) — отказ от быстрых '
                        'углеводов, овощная база, первый результат до 5 кг.',
                      ),
                      _Bullet(
                        '2. Основной — стабильное снижение веса до цели, '
                        '100–200 г в день, добавляются силовые нагрузки.',
                      ),
                      _Bullet(
                        '3. Завершающий (1–1,5 года) — удержание веса, '
                        'простые правила сочетания продуктов.',
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Углеводы',
                    icon: Icons.grain,
                    color: config.stageColors.last,
                    children: const [
                      _Bullet(
                        'Исключаем быстрые углеводы: сахар, мучное, '
                        'картофель, белый рис.',
                      ),
                      _Bullet(
                        'Медленные углеводы нужны: фрукты, каши, бобовые.',
                      ),
                      _Bullet(
                        'Редкие «отступления» не ломают систему — '
                        'не ругайте себя за маленький кусочек любимого блюда.',
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Обязательно каждый день',
                    icon: Icons.directions_walk,
                    color: config.stageColors.first,
                    children: const [
                      _Bullet('Ходьба — не менее 1 часа утром.'),
                      _Bullet('Вода — 4–5 стаканов (на 1-м этапе — от 1,5 л).'),
                      _Bullet('Отруби — 2–4 ст. л. в день.'),
                      _Bullet('Орехи — горсть ежедневно.'),
                      _Bullet('2 яичных белка перед сном.'),
                    ],
                  ),
                  _SectionCard(
                    title: 'Перед началом',
                    icon: Icons.medical_information_outlined,
                    color: const Color(0xFFC62828),
                    children: const [
                      _Bullet(
                        'Пройдите медосмотр и сдайте общие анализы.',
                      ),
                      _Bullet(
                        'При избыточном весе 40+ кг ведите программу '
                        'под контролем врача.',
                      ),
                    ],
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: theme.colorScheme.primary)),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
