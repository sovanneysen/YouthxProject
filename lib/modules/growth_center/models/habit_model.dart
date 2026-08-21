import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly }

class HabitModel {
  final String id;
  final String emoji;
  final String title;
  final HabitFrequency frequency;
  final int streak;
  final Color color;
  final bool isCompletedToday;
  final int?
  scheduledHour; // NEW — 0-23, null means "not scheduled on timeline"

  const HabitModel({
    required this.id,
    required this.emoji,
    required this.title,
    required this.frequency,
    required this.streak,
    required this.color,
    this.isCompletedToday = false,
    this.scheduledHour, // optional, defaults to null automatically
  });

  HabitModel copyWith({
    String? id,
    String? emoji,
    String? title,
    HabitFrequency? frequency,
    int? streak,
    Color? color,
    bool? isCompletedToday,
    int? scheduledHour,
  }) {
    return HabitModel(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      streak: streak ?? this.streak,
      color: color ?? this.color,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      scheduledHour: scheduledHour ?? this.scheduledHour,
    );
  }

  String get frequencyLabel =>
      frequency == HabitFrequency.daily ? 'Daily' : 'Weekly';
}
