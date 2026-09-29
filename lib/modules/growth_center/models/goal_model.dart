enum GoalCategory { health, finance, career, learning, social, mindset, other }

class GoalModel {
  final String id;
  final String emoji;
  final String title;
  final GoalCategory category;
  final String? customCategoryLabel; // only used when category == other
  final String targetDate;

  /// Manual progress, stored as a 0.0–1.0 fraction of 100%. The backend keeps
  /// this as `progress_percent` (integer 0–100); the repository converts.
  final double progress;
  final bool hasReminder;
  final String? reminderTime;

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
  });

  /// Progress as a 0.0–1.0 fraction, always clamped for display.
  double get effectiveProgress => progress.clamp(0.0, 1.0);

  // --- Compatibility shims -------------------------------------------------
  // Numeric goal tracking (targetAmount/currentAmount/unit) was never
  // persisted by the backend, so it silently lost data on every round-trip
  // and has been removed. These three members remain only so that
  // `views/overview/overview_view.dart` and `auth/views/home_screen.dart`,
  // which are outside this batch's allowed scope, keep compiling. They carry
  // no numeric state: nothing is ever tracked, labelled, or derived.
  @Deprecated('Numeric goal tracking was removed; use progress instead.')
  bool get isNumericTracked => false;

  @Deprecated('Numeric goal tracking was removed; use progress instead.')
  String? get amountLabel => null;

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
    );
  }
}
