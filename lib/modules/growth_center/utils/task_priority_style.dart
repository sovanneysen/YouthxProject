import 'package:flutter/material.dart';
import '../models/task_model.dart';

// A "helper class" — it doesn't hold data, it just gives you
// answers based on a TaskPriority you pass in.
class TaskPriorityStyle {
  // static means: call this WITHOUT creating an object first.
  // e.g. TaskPriorityStyle.labelOf(TaskPriority.high) → "High"
  static String labelOf(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  // Text/icon color for the badge
  static Color colorOf(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade600;
      case TaskPriority.medium:
        return Colors.orange.shade700;
      case TaskPriority.low:
        return Colors.green.shade700;
    }
  }

  // Light background color for the badge pill
  static Color backgroundOf(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade50;
      case TaskPriority.medium:
        return Colors.orange.shade50;
      case TaskPriority.low:
        return Colors.green.shade50;
    }
  }
}
