import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../../core/widgets/card_overflow_menu.dart';
import '../models/goal_model.dart';
import '../utils/category_style.dart';
import 'goal_progress_bar.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback?
  onTap; // FIXED — simple VoidCallback, and saved as a field
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap, // FIXED — optional, not required, matches onEdit/onDelete style
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.colorOf(goal.category);

    return GestureDetector(
      // NEW — wraps the whole card so tapping anywhere (not the ⋮ menu) fires onTap
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: context.isDark ? Border.all(color: context.borderColor) : null,
          boxShadow: context.isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(goal.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CategoryStyle.displayLabel(goal.category, goal.customCategoryLabel)} · ${goal.targetDate}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                CardOverflowMenu(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
            const SizedBox(height: 14),
            GoalProgressBar(progress: goal.effectiveProgress, color: color),
            if (goal.hasReminder) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 16,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Daily ${goal.reminderTime ?? ''}',
                    style: TextStyle(
                        fontSize: 13, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
