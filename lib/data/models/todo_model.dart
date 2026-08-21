import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TodoPriority { low, medium, high }

class TodoModel {
  final String id;
  final String title;
  final DateTime dueDate;
  final TodoPriority priority;
  final bool isDone;

  TodoModel({
    required this.id,
    required this.title,
    required dynamic dueDate,
    required this.priority,
    this.isDone = false,
  }) : dueDate = dueDate is DateTime
           ? dueDate
           : DateTime.parse(dueDate as String);

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      dueDate: json['dueDate'],
      priority: TodoPriority.values.firstWhere(
        (p) => p.name == (json['priority'] ?? 'medium'),
        orElse: () => TodoPriority.medium,
      ),
      isDone: json['isDone'] ?? false,
    );
  }

  TodoModel copyWith({bool? isDone}) {
    return TodoModel(
      id: id,
      title: title,
      dueDate: dueDate,
      priority: priority,
      isDone: isDone ?? this.isDone,
    );
  }

  String get priorityLabel => switch (priority) {
    TodoPriority.high => 'High',
    TodoPriority.medium => 'Medium',
    TodoPriority.low => 'Low',
  };

  static const Color _mediumColor = Color(0xFFFFB020);

  Color get priorityColor => switch (priority) {
    TodoPriority.high => AppColors.error,
    TodoPriority.medium => _mediumColor,
    TodoPriority.low => AppColors.textSecondary,
  };

  Color get priorityBg => switch (priority) {
    TodoPriority.high => AppColors.error.withOpacity(0.12),
    TodoPriority.medium => _mediumColor.withOpacity(0.12),
    TodoPriority.low => AppColors.textSecondary.withOpacity(0.12),
  };
}
