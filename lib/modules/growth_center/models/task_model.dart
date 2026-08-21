// lib/modules/growth_center/models/task_model.dart

// An enum is a fixed list of choices. Since a task can ONLY be
// High, Medium, or Low (never anything else), enum is safer than
// using a plain String like 'high' — no risk of typos like 'Hihg'.
enum TaskPriority { high, medium, low }

class TaskModel {
  final String id;
  final String title;
  final TaskPriority priority;
  final String dueDate; // stored as text, e.g. "2026-06-25" or "No date"
  final bool isCompleted;
  final int? scheduledHour; // NEW

  TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false, // new tasks start unchecked by default
    this.scheduledHour,
  });
}
