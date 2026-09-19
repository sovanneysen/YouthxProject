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
}
