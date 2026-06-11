import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/purchase_verification_service.dart';
import 'package:my_diet/services/stage_unlock_service.dart';
import 'package:my_diet/widgets/unlock_dialogs.dart';

/// Список из трёх этапов методики с замками.
class MethodologyStageCards extends StatefulWidget {
  final String methodologyId;
  final void Function(int stageIndex) onOpenStage;

  const MethodologyStageCards({
    super.key,
    required this.methodologyId,
    required this.onOpenStage,
  });

  @override
  State<MethodologyStageCards> createState() => MethodologyStageCardsState();
}

class MethodologyStageCardsState extends State<MethodologyStageCards> {
  List<bool> _stageUnlocked = const [true, false, false];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final states =
        await StageUnlockService.loadStageUnlockStates(widget.methodologyId);
    if (mounted) {
      setState(() {
        _stageUnlocked = states;
        _loading = false;
      });
    }
    await PurchaseVerificationService.verifyBeforeAccess(widget.methodologyId);
    final updated =
        await StageUnlockService.loadStageUnlockStates(widget.methodologyId);
    if (mounted) setState(() => _stageUnlocked = updated);
  }

  Future<void> _onStageTap(int index) async {
    if (_loading) return;

    await refresh();
    if (!mounted) return;

    if (!_stageUnlocked[index]) {
      await showStageLockedDialog(
        context,
        methodologyId: widget.methodologyId,
        stageIndex: index,
      );
      return;
    }

    widget.onOpenStage(index);
  }

  @override
  Widget build(BuildContext context) {
    final config = MethodologyRegistry.get(widget.methodologyId);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Этапы методики',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          _MethodologyStageCard(
            emoji: config.stageEmojis[i],
            name: config.stageCardNames[i],
            duration: config.stageDurations[i],
            color: config.stageColors[i],
            isLocked: !_stageUnlocked[i],
            onTap: () => _onStageTap(i),
          ),
      ],
    );
  }
}

class _MethodologyStageCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String duration;
  final Color color;
  final bool isLocked;
  final VoidCallback onTap;

  const _MethodologyStageCard({
    required this.emoji,
    required this.name,
    required this.duration,
    required this.color,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        color: isLocked
            ? theme.colorScheme.surface.withValues(alpha: 0.75)
            : theme.colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 6)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 36,
                    color: isLocked ? Colors.grey : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked ? Colors.grey.shade600 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey : color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLocked ? Icons.lock : Icons.timer_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLocked ? 'Закрыто' : duration,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock_outline : Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
