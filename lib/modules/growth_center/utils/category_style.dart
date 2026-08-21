import 'package:flutter/material.dart';
import '../models/goal_model.dart';

class CategoryStyle {
  static const Map<GoalCategory, Color> colors = {
    GoalCategory.health: Color(0xFF3B82F6),
    GoalCategory.finance: Color(0xFF10B981),
    GoalCategory.career: Color(0xFFF59E0B),
    GoalCategory.learning: Color(0xFF6366F1),
    GoalCategory.social: Color(0xFF06B6D4),
    GoalCategory.mindset: Color(0xFFA855F7),
    GoalCategory.other: Color(0xFF6B7280),
  };

  static const Map<GoalCategory, String> labels = {
    GoalCategory.health: 'Health',
    GoalCategory.finance: 'Finance',
    GoalCategory.career: 'Career',
    GoalCategory.learning: 'Learning',
    GoalCategory.social: 'Social',
    GoalCategory.mindset: 'Mindset',
    GoalCategory.other: 'Other',
  };

  static const Map<GoalCategory, String> emojis = {
    GoalCategory.health: '💪',
    GoalCategory.finance: '💰',
    GoalCategory.career: '💼',
    GoalCategory.learning: '📚',
    GoalCategory.social: '👥',
    GoalCategory.mindset: '🧘',
    GoalCategory.other: '✏️',
  };

  static Color colorOf(GoalCategory c) => colors[c]!;
  static String labelOf(GoalCategory c) => labels[c]!;
  static String emojiOf(GoalCategory c) => emojis[c]!;

  //* Resolves the label to show on a GoalCard —
  //* custom text if "Other" + user typed something, otherwise the standard label.
  static String displayLabel(GoalCategory category, String? customLabel) {
    if (category == GoalCategory.other &&
        (customLabel?.trim().isNotEmpty ?? false)) {
      return customLabel!.trim();
    }
    return labelOf(category);
  }
}
