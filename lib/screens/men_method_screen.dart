import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран «О методике» — Мужская диета.
class MenMethodScreen extends StatelessWidget {
  const MenMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = MethodologyRegistry.get(MethodologyIds.men);

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
                          icon: Icons.fitness_center,
                          color: config.stageColors.first,
                          children: const [
                            _Bullet(
                              'Клиническая диета для мужчин: без голода, '
                              'без подсчёта калорий и без контейнеров с едой '
                              'на работу.',
                            ),
                            _Bullet(
                              'Днём — фитомуцил с протеином, вечером — '
                              'полноценный ужин с мясом или рыбой.',
                            ),
                            _Bullet(
                              'Мотивация должна быть личной — худеть '
                              'можно только для себя.',
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: 'Три этапа',
                          icon: Icons.timeline,
                          color: config.stageColors[1],
                          children: const [
                            _Bullet(
                              '1. Подготовительный (2–3 дня) — только рис с '
                              'курагой при отёках, затем основной этап.',
                            ),
                            _Bullet(
                              '2. Основной — до достижения цели: '
                              '3–4 порции фитомуцила + вечерний ужин.',
                            ),
                            _Bullet(
                              '3. Завершающий — постепенная замена порций '
                              'салатом и яйцами, удержание результата.',
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: 'Основной этап',
                          icon: Icons.restaurant,
                          color: config.stageColors.last,
                          children: const [
                            _Bullet(
                              'Утро: вода, кофе/чай без сахара.',
                            ),
                            _Bullet(
                              'День: «Фитомуцил Слим Смарт» + изолят '
                              'протеина в 200 мл воды (3–4 раза).',
                            ),
                            _Bullet(
                              'Ужин 20:00–22:00: салат + 160 г мяса '
                              'или 180 г рыбы.',
                            ),
                            _Bullet(
                              'Сон до 23:00, вода 1,5 л (первые 2 недели).',
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: 'Движение и гормоны',
                          icon: Icons.directions_run,
                          color: config.stageColors.first,
                          children: const [
                            _Bullet(
                              'Физнагрузка активирует адреналин и '
                              'жиросжигающие гормоны — не ради калорий.',
                            ),
                            _Bullet(
                              'L-карнитин при утренней тренировке.',
                            ),
                            _Bullet(
                              'Следите за тестостероном — сдавайте анализы.',
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: 'Перед началом',
                          icon: Icons.medical_information_outlined,
                          color: const Color(0xFFC62828),
                          children: const [
                            _Bullet(
                              'Обязательны анализы крови, мочи, '
                              'биохимия и гормоны.',
                            ),
                            _Bullet(
                              'Без диагностики диета может быть опасна '
                              'при скрытых заболеваниях.',
                            ),
                            _Bullet(
                              'Повторяйте анализы раз в 2 месяца.',
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
