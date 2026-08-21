import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/task_priority_style.dart';

class OverviewTodaySection extends StatelessWidget {
  final List<TaskModel> tasksDueOnSelectedDay;

  const OverviewTodaySection({super.key, required this.tasksDueOnSelectedDay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (tasksDueOnSelectedDay.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Nothing due this day 🎉',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          )
        else
          ...tasksDueOnSelectedDay.map((task) => _TodayItem(task: task)),
      ],
    );
  }
}

class _TodayItem extends StatelessWidget {
  final TaskModel task;

  const _TodayItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted
                  ? Colors.green.shade500
                  : Colors.grey.shade200,
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: task.isCompleted
                        ? Colors.grey.shade400
                        : const Color(0xFF1E1B2E),
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                Text(
                  '${TaskPriorityStyle.labelOf(task.priority)} priority',
                  style: TextStyle(
                    fontSize: 13,
                    color: TaskPriorityStyle.colorOf(task.priority),
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
