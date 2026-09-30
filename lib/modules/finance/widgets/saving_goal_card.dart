import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/saving_goal_model.dart';

/// Money formatter shared by every Saving Goals surface so amounts, progress
/// and remaining values all read identically on the home card, the list and
/// the detail screen.
String formatGoalMoney(double value) =>
    '\u0024${NumberFormat('#,##0.00').format(value.abs())}';

/// Accent colour for a goal. Completed goals turn green so a finished goal is
/// readable at a glance without inventing any extra backend state.
Color goalAccent(SavingGoalModel goal) =>
    goal.isComplete ? AppColors.success : AppColors.violet;

/// Rounded progress bar driven by [SavingGoalModel.progressFraction], which is
/// already clamped to 0.0–1.0. `LinearProgressIndicator` asserts on an
/// out-of-range value, so the clamp is what keeps this safe.
class GoalProgressBar extends StatelessWidget {
  const GoalProgressBar({
    super.key,
    required this.goal,
    this.height = 8,
    this.accent,
  });

  final SavingGoalModel goal;
  final double height;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? goalAccent(goal);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: goal.progressFraction,
        minHeight: height,
        backgroundColor: context.cardBgAlt,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Goal card used by the Finance home Saving Goals section and the
/// "All saving goals" list. Tapping [onTap] opens the detail screen; the
/// trailing action is the deposit entry point.
class SavingGoalCard extends StatelessWidget {
  const SavingGoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onDeposit,
  });

  final SavingGoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onDeposit;

  @override
  Widget build(BuildContext context) {
    final accent = goalAccent(goal);
    final complete = goal.isComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark ? Border.all(color: context.borderColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  complete ? Icons.emoji_events : Icons.savings,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatGoalMoney(goal.currentAmount)} of '
                      '${formatGoalMoney(goal.targetAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PercentBadge(goal: goal, accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          GoalProgressBar(goal: goal, accent: accent),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  complete
                      ? 'Goal reached'
                      : '${formatGoalMoney(goal.remainingAmount)} to go',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: complete ? accent : context.textSecondaryColor,
                  ),
                ),
              ),
              if (onDeposit != null)
                ElevatedButton(
                  onPressed: onDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Add Deposit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (onTap != null) const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.goal, required this.accent});

  final SavingGoalModel goal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${goal.progressPercent.round()}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }
}
