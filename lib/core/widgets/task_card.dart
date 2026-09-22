import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../modules/growth_center/models/task_model.dart';
import '../../modules/growth_center/utils/task_priority_style.dart';
import 'card_overflow_menu.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<bool?> onToggleComplete; // checkbox tapped
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Pull once, so we don't call these getters multiple times below
    final priorityLabel = TaskPriorityStyle.labelOf(task.priority);
    final priorityColor = TaskPriorityStyle.colorOf(task.priority);
    final priorityBg = TaskPriorityStyle.backgroundOf(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Checkbox (custom circle, not the default Flutter Checkbox,
          // to match your rounded-circle screenshot style) ---
          GestureDetector(
            onTap: () => onToggleComplete(!task.isCompleted),
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? Colors.green.shade500
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? Colors.green.shade500
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),

          // --- Title + badge + date ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: task.isCompleted
                        ? Colors.grey.shade400
                        : context.textPrimaryColor,
                    // strikethrough only when completed
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priorityLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    if (task.dueDate != 'No date') ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: context.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.dueDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // --- Reuse your existing overflow menu (Edit/Delete) ---
          CardOverflowMenu(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}
