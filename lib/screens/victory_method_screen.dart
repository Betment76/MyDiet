import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран «О методике» — Победа над весом.
class VictoryMethodScreen extends StatelessWidget {
  const VictoryMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = MethodologyRegistry.get(MethodologyIds.victory);

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
                          icon: Icons.emoji_events,
                          color: config.stageColors.first,
                          children: const [
                            _Bullet(
                              'Комплексная методика: питание + ежедневная '
                              'ходьба + добавки. Без одного звена '
                              'программа неэффективна.',
                            ),
                            _Bullet(
                              'Не диета, а организация питания и образ '
                              'жизни на годы.',
                            ),
                            _Bullet(
                              'С организмом нужно «договариваться», а не '
                              '«ломать».',
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: 'Три этапа',
                          icon: Icons.timeline,
                          color: config.stageColors[1],
                          children: const [
                            _Bullet(
                              '1. Подготовительный (2–3 недели) — снятие '
                              'зависимости от быстрых углеводов, до −5 кг.',
                            ),
                            _Bullet(
                              '2. Основной — до оптимального веса, '
                              '100–200 г/день в среднем.',
                            ),
                            _Bullet(
                              '3. Завершающий (1–1,5 года) — удержание '
                              'результата, шагомер, разнообразное питание.',
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: 'Движение',
                          icon: Icons.directions_walk,
                          color: config.stageColors.last,
                          children: const [
                            _Bullet(
                              'Ходьба ежедневно — главное звено. Жир '
                              'сгорает только при аэробной нагрузке.',
                            ),
                            _Bullet(
                              'L-карнитин 1500 мг до и после ходьбы.',
                            ),
                            _Bullet(
                              'На 3-м этапе — от 10 000 шагов в день.',
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: 'Перед началом',
                          icon: Icons.medical_information_outlined,
                          color: const Color(0xFFC62828),
                          children: const [
                            _Bullet(
                              'Медосмотр, общие анализы, консультация '
                              'врача. При диабете — эндокринолог.',
                            ),
                            _Bullet(
                              'Женщинам — начинать после «критических '
                              'дней».',
                            ),
                            _Bullet(
                              'При избыточном весе 40+ кг — только под '
                              'контролем врача.',
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
