import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';
import '../models/saving_goal_model.dart';
import '../widgets/saving_goal_card.dart';
import '../widgets/saving_goal_deposit_sheet.dart';
import 'saving_goal_form_page.dart';
/// Detail screen for a single saving goal.
///
/// Holds no copy of the goal: it receives only [goalId] and reads the current
/// snapshot out of `FinanceController.savingGoals` inside an `Obx`. Every
/// mutation (deposit / edit / delete) is applied by the controller to that same
/// list, so this screen updates itself without any extra refresh call.
class SavingGoalDetailPage extends GetView<FinanceController> {
  const SavingGoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Obx(() {
          final goal = _find();
          return Text(
            goal?.displayName ?? 'Saving Goal',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
        actions: [
          Obx(() {
            final goal = _find();
            if (goal == null) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Edit goal',
              onPressed: () => _openEdit(context, goal),
              icon: Icon(Icons.edit, color: context.textPrimaryColor),
            );
          }),
          Obx(() {
            final goal = _find();
            if (goal == null) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Delete goal',
              onPressed: () => _confirmDelete(context, goal),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final goal = _find();
          // The goal was deleted (or its id never matched): nothing to show.
          if (goal == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 48,
                      color: context.textSecondaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This saving goal is no longer available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Back to Finance'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _DetailBody(
            goal: goal,
            onDeposit: () => _openDepositSheet(context, goal),
          );
        }),
      ),
    );
  }

  /// Current snapshot of the goal from the reactive list, or null once removed.
  SavingGoalModel? _find() {
    // `controller` is resolved through GetView and read inside Obx so the
    // lookup itself re-runs when `savingGoals` changes.
    return controller.savingGoals.firstWhereOrNull((g) => g.id == goalId);
  }

  Future<void> _openEdit(BuildContext context, SavingGoalModel goal) async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SavingGoalFormPage(existing: goal),
      ),
    );
    if (changed == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Goal updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDepositSheet(
    BuildContext context,
    SavingGoalModel goal,
  ) async {
    // The controller replaces the list entry, which rebuilds this screen.
    await SavingGoalDepositSheet.submit(context, goal);
  }

  Future<void> _confirmDelete(BuildContext context, SavingGoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.cardBg,
        title: const Text('Delete this goal?'),
        content: Text(
          '"${goal.displayName}" and its saved progress will be removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await controller.deleteSavingGoal(goal.id);
    if (!ok) {
      controller.clearError();
      if (!context.mounted) return;
      _toast(context, 'Could not delete the goal');
      return;
    }
    if (!context.mounted) return;
    _toast(context, 'Goal deleted');
    Navigator.of(context).pop();
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.goal, required this.onDeposit});

  final SavingGoalModel goal;
  final VoidCallback onDeposit;

  @override
  Widget build(BuildContext context) {
    final accent = goalAccent(goal);
    final complete = goal.isComplete;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // * Hero progress card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: complete
                  ? const [AppColors.success, AppColors.overviewAccent]
                  : const [AppColors.violet, AppColors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                complete ? 'GOAL REACHED' : 'SAVED SO FAR',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatGoalMoney(goal.currentAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'of ${formatGoalMoney(goal.targetAmount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: goal.progressFraction,
                  minHeight: 12,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${goal.progressPercent.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    complete
                        ? 'Target reached'
                        : '${formatGoalMoney(goal.remainingAmount)} to go',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // * Amount breakdown
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Current',
                value: formatGoalMoney(goal.currentAmount),
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Target',
                value: formatGoalMoney(goal.targetAmount),
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Remaining',
                value: formatGoalMoney(goal.remainingAmount),
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // * Primary action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onDeposit,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Deposit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // * Honest note: the backend exposes no deposit history endpoint, so
        // * there is nothing to list here. A disabled button would imply a
        // * missing feature, so this stays plain information.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardBgAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: context.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Every deposit is added to this goal. There is no separate '
                  'deposit history.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Finance'),
          style: TextButton.styleFrom(
            foregroundColor: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: context.isDark ? Border.all(color: context.borderColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

