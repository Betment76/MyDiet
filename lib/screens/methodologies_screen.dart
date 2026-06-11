import 'package:flutter/material.dart';
import 'package:my_diet/data/methodologies_data.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/screens/express_methodology_screen.dart';
import 'package:my_diet/screens/fun_methodology_screen.dart';
import 'package:my_diet/screens/men_methodology_screen.dart';
import 'package:my_diet/screens/victory_methodology_screen.dart';
import 'package:my_diet/screens/gourmet_methodology_screen.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран выбора методики (главная вкладка и переход из профиля).
class MethodologiesScreen extends StatelessWidget {
  final VoidCallback? onOpenExpress;
  final VoidCallback? onOpenGourmets;
  final VoidCallback? onOpenFun;
  final VoidCallback? onOpenMen;
  final VoidCallback? onOpenVictory;
  final bool showBackButton;

  const MethodologiesScreen({
    super.key,
    this.onOpenExpress,
    this.onOpenGourmets,
    this.onOpenFun,
    this.onOpenMen,
    this.onOpenVictory,
    this.showBackButton = true,
  });

  Future<void> _onMethodologyTap(BuildContext context, MethodologyInfo item) async {
    if (!item.available) {
      await showAppBottomSheet<void>(
        context: context,
        title: item.title,
        body: 'Эта методика скоро будет доступна.',
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: ThemeProvider.primaryGreen,
            ),
            child: const Text('Понятно'),
          ),
        ],
      );
      return;
    }

    await ProfileService.setActiveMethodology(item.id);
    if (!context.mounted) return;

    if (item.id == 'express') {
      if (onOpenExpress != null) {
        onOpenExpress!();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ExpressMethodologyScreen(),
        ),
      );
      return;
    }
    if (item.id == 'gourmets') {
      if (onOpenGourmets != null) {
        onOpenGourmets!();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const GourmetMethodologyScreen(),
        ),
      );
      return;
    }
    if (item.id == 'fun') {
      if (onOpenFun != null) {
        onOpenFun!();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FunMethodologyScreen(),
        ),
      );
      return;
    }
    if (item.id == 'men') {
      if (onOpenMen != null) {
        onOpenMen!();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MenMethodologyScreen(),
        ),
      );
      return;
    }
    if (item.id == 'victory') {
      if (onOpenVictory != null) {
        onOpenVictory!();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const VictoryMethodologyScreen(),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + (showBackButton ? 8 : 16),
              bottom: 16,
              left: showBackButton ? 4 : 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBackButton)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Выбор методики',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  const Text(
                    'Привет! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Выберите методику для начала',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: MethodologySelectionList(
              onItemTap: (item) => _onMethodologyTap(context, item),
            ),
          ),
        ],
      ),
    );
  }
}

/// Список карточек методик.
class MethodologySelectionList extends StatelessWidget {
  final void Function(MethodologyInfo item) onItemTap;

  const MethodologySelectionList({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = MethodologiesData.items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Методики',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < items.length - 1 ? 8 : 0,
                      ),
                      child: MethodologyCard(
                        item: items[i],
                        onTap: () => onItemTap(items[i]),
                      ),
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

class MethodologyCard extends StatelessWidget {
  final MethodologyInfo item;
  final VoidCallback onTap;

  const MethodologyCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: item.accentColor, width: 6),
            ),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
