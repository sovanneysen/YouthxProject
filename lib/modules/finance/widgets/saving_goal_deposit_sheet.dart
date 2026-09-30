import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';
import '../models/saving_goal_model.dart';
import 'saving_goal_card.dart';

/// Deposit entry sheet, shared by the goal detail screen and the goals list so
/// both offer the exact same input.
///
/// [show] resolves to the entered amount, or null when dismissed. It performs
/// no API call: the caller hands the amount to [FinanceController], which owns
/// the `POST /saving-goals/{id}/deposit` call.
class SavingGoalDepositSheet extends StatefulWidget {
  const SavingGoalDepositSheet({super.key, required this.goal});

  final SavingGoalModel goal;

  /// Opens the sheet and returns the confirmed amount, or null if dismissed.
  static Future<double?> show(
    BuildContext context,
    SavingGoalModel goal,
  ) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SavingGoalDepositSheet(goal: goal),
    );
  }

  /// Opens the sheet and, if an amount is confirmed, records the deposit
  /// through the shared [FinanceController]. Returns true when the deposit was
  /// accepted by the backend.
  static Future<bool> submit(
    BuildContext context,
    SavingGoalModel goal,
  ) async {
    final amount = await show(context, goal);
    if (amount == null) return false;

    final ctrl = Get.find<FinanceController>();
    final ok = await ctrl.depositToSavingGoal(goal, amount);
    if (!ok) {
      // Surface the failure once, then clear the shared error so the Finance
      // home is not left in its full-screen error state.
      ctrl.clearError();
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not record the deposit'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return ok;
  }

  @override
  State<SavingGoalDepositSheet> createState() =>
      _SavingGoalDepositSheetState();
}

class _SavingGoalDepositSheetState extends State<SavingGoalDepositSheet> {
  final _amountController = TextEditingController();
  static const List<double> _quickAmounts = [5, 10, 25, 50];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    // The backend requires the deposit amount to be strictly positive.
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an amount greater than zero'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add deposit to "${widget.goal.displayName}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Currently ${formatGoalMoney(widget.goal.currentAmount)} of '
              '${formatGoalMoney(widget.goal.targetAmount)}',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '\u0024',
                prefixStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondaryColor,
                ),
                filled: true,
                fillColor: context.cardBgAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final quick in _quickAmounts)
                  ActionChip(
                    label: Text('+${formatGoalMoney(quick)}'),
                    onPressed: () {
                      final current =
                          double.tryParse(_amountController.text.trim()) ?? 0;
                      setState(() {
                        _amountController.text =
                            (current + quick).toStringAsFixed(2);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add Deposit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
