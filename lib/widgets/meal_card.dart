import 'package:flutter/material.dart';
import 'package:my_diet/models/meal_entry.dart';

/// Карточка приёма пищи в дневнике
class MealCard extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback? onDelete;

  const MealCard({super.key, required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            entry.type.icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          entry.type.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(entry.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.calories.toInt()} ккал',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
                Text(
                  'Б: ${entry.protein.toInt()}  Ж: ${entry.fats.toInt()}  У: ${entry.carbs.toInt()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Colors.red.shade300),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
