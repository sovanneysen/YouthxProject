import 'package:flutter/material.dart';

class HabitModel {
  final String id;
  final String title;
  final String emoji;
  final String frequency; // "daily" / "weekly"
  final int streak;
  final bool completedToday;
  final Color accentColor;

  HabitModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.frequency,
    required this.streak,
    required this.completedToday,
    required this.accentColor,
  });
}
