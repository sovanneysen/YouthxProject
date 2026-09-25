import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../../core/widgets/card_overflow_menu.dart';
import '../models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: habit.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${habit.frequencyLabel} · ',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Text('🔥 ', style: const TextStyle(fontSize: 13)),
                    Text(
                      '${habit.streak} streak',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: habit.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CompletionToggle(
            isCompleted: habit.isCompletedToday,
            color: habit.color,
            onTap: () => onToggleComplete(!habit.isCompletedToday),
          ),
          const SizedBox(width: 4),
          CardOverflowMenu(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _CompletionToggle extends StatelessWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  const _CompletionToggle({
    required this.isCompleted,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? color : Colors.transparent,
          border: Border.all(
            color: isCompleted ? color : context.borderColor,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
