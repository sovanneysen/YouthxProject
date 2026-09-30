// * Saving Goal — numeric goal with progress, mirrors backend SavingGoalResponse:
// *   id, userId, name, targetAmount(BigDecimal), currentAmount(BigDecimal),
// *   progressPercent(Integer), createdAt

/// A single saving goal shown in the Finance module. Backed by the real
/// Draft Backend `GET /saving-goals` and `POST /saving-goals/{id}/deposit`
/// (backend computes/returns `progressPercent` after the deposit).
class SavingGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double progressPercent;

  const SavingGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercent,
  });

  /// Parses a backend `SavingGoalResponse` JSON object.
  factory SavingGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingGoalModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Serializable body for `POST /saving-goals` (CreateSavingGoalRequest:
  /// `{ name, targetAmount }`).
  Map<String, dynamic> toCreateBody() => {
        'name': name,
        'targetAmount': targetAmount,
      };

  /// Serializable body for `POST /saving-goals/{id}/deposit`
  /// (DepositRequest: `{ amount }`).
  Map<String, dynamic> toDepositBody(double amount) => {'amount': amount};

  // ── Derived display values ──────────────────────────────────────────────
  // Computed only from the fields the backend already returns
  // (currentAmount / targetAmount / progressPercent). No extra data, no
  // history, no invented statistics.

  /// Progress as a 0.0–1.0 fraction, safe to hand straight to
  /// [LinearProgressIndicator].
  ///
  /// The backend computes `progressPercent` as `(current * 100 / target)`
  /// truncated to an int, so it can exceed 100 whenever a deposit overshoots
  /// the target. Clamping here keeps the indicator valid and never renders an
  /// over-full bar.
  double get progressFraction =>
      (progressPercent / 100).clamp(0.0, 1.0).toDouble();

  /// Amount still to save. Never negative, so an overshot goal reads as 0
  /// rather than as a negative number.
  double get remainingAmount {
    final left = targetAmount - currentAmount;
    return left > 0 ? left : 0.0;
  }

  /// True once the saved amount covers the target. Guarded on a positive
  /// target so a malformed `targetAmount` of 0 cannot mark a goal complete.
  bool get isComplete => targetAmount > 0 && currentAmount >= targetAmount;

  /// Non-empty label so a blank goal name never renders an empty header.
  String get displayName =>
      name.trim().isEmpty ? 'Untitled goal' : name.trim();
}
