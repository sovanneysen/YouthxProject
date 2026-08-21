enum GoalCategory { health, finance, career, learning, social, mindset, other }

class GoalModel {
  final String id;
  final String emoji;
  final String title;
  final GoalCategory category;
  final String? customCategoryLabel; // only used when category == other
  final String targetDate;
  final double progress; // manual 0.0–1.0, used when NOT numeric-tracked
  final bool hasReminder;
  final String? reminderTime;

  // --- Numeric tracking (NEW) ---
  // When targetAmount is set, this goal is tracked by a real number
  // (e.g. "Save $200/month" -> targetAmount: 200, unit: '$') instead of a
  // manually-set percentage. Progress is then DERIVED, never stored raw.
  final double? targetAmount;
  final double? currentAmount;
  final String? unit; // e.g. '$', 'km', 'pages', 'hrs'

  const GoalModel({
    required this.id,
    required this.emoji,
    required this.title,
    required this.category,
    this.customCategoryLabel,
    required this.targetDate,
    required this.progress,
    this.hasReminder = false,
    this.reminderTime,
    this.targetAmount,
    this.currentAmount,
    this.unit,
  });

  bool get isNumericTracked => targetAmount != null && targetAmount! > 0;

  double get effectiveProgress {
    if (isNumericTracked) {
      final ratio = (currentAmount ?? 0) / targetAmount!;
      return ratio.clamp(0.0, 1.0);
    }
    return progress.clamp(0.0, 1.0);
  }

  /// e.g. "$170 / $200" or "12 / 20 km" — null for non-numeric goals.
  String? get amountLabel {
    if (!isNumericTracked) return null;
    final u = unit ?? '';
    final current = _formatAmount(currentAmount ?? 0);
    final target = _formatAmount(targetAmount!);
    if (u == '\$' || u == '€' || u == '£') {
      return '$u$current / $u$target';
    }
    return u.isEmpty ? '$current / $target' : '$current / $target $u';
  }

  static String _formatAmount(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String get displayCategoryLabel {
    if (category == GoalCategory.other &&
        (customCategoryLabel?.trim().isNotEmpty ?? false)) {
      return customCategoryLabel!.trim();
    }
    return null ?? '';
  }

  GoalModel copyWith({
    String? emoji,
    String? title,
    GoalCategory? category,
    String? customCategoryLabel,
    String? targetDate,
    double? progress,
    bool? hasReminder,
    String? reminderTime,
    double? targetAmount,
    double? currentAmount,
    String? unit,
    bool clearNumericTracking = false,
  }) {
    return GoalModel(
      id: id,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      category: category ?? this.category,
      customCategoryLabel: customCategoryLabel ?? this.customCategoryLabel,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? this.progress,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      targetAmount: clearNumericTracking
          ? null
          : (targetAmount ?? this.targetAmount),
      currentAmount: clearNumericTracking
          ? null
          : (currentAmount ?? this.currentAmount),
      unit: clearNumericTracking ? null : (unit ?? this.unit),
    );
  }
}
