import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';
import '../models/saving_goal_model.dart';
import '../widgets/saving_goal_card.dart';

/// Create / Edit form for a saving goal.
///
/// Reuses the existing [FinanceController] and the existing backend
/// `POST /saving-goals` / `PUT /saving-goals/{id}` contract — no new fields.
/// Pass [existing] to switch into edit mode.
class SavingGoalFormPage extends StatefulWidget {
  const SavingGoalFormPage({super.key, this.existing});

  /// When set the page edits this goal instead of creating a new one.
  final SavingGoalModel? existing;

  @override
  State<SavingGoalFormPage> createState() => _SavingGoalFormPageState();
}

class _SavingGoalFormPageState extends State<SavingGoalFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    // The target is entered as a whole amount, so the stored double is
    // rendered without trailing ".0".
    final target = widget.existing?.targetAmount;
    _targetController = TextEditingController(
      text: target == null ? '' : _trimNumber(target),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  static String _trimNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());

    if (name.isEmpty) {
      _toast('Give your goal a name');
      return;
    }
    // The backend requires target_amount > 0.
    if (target == null || target <= 0) {
      _toast('Enter a target amount greater than zero');
      return;
    }

    final ctrl = Get.find<FinanceController>();
    setState(() => _saving = true);

    final existing = widget.existing;
    final bool ok;
    if (existing != null) {
      // Edit. The controller replaces the matching list entry, so the stored
      // current amount and progress are read back from the list rather than
      // guessed here.
      final stored = ctrl.savingGoals.firstWhereOrNull((g) => g.id == existing.id);
      ok = await ctrl.updateSavingGoal(
        SavingGoalModel(
          id: existing.id,
          name: name,
          targetAmount: target,
          currentAmount: stored?.currentAmount ?? existing.currentAmount,
          progressPercent: stored?.progressPercent ?? existing.progressPercent,
        ),
      );
    } else {
      // Create. A new goal always starts at zero.
      ok = await ctrl.createSavingGoal(
        SavingGoalModel(
          id: '',
          name: name,
          targetAmount: target,
          currentAmount: 0,
          progressPercent: 0,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // The controller writes a human-readable message into `error` on
      // failure; show our own toast, then clear it so an earlier failure
      // cannot flip the Finance home screen into its full-screen error state.
      ctrl.clearError();
      _toast(existing != null
          ? 'Could not update the goal'
          : 'Could not create the goal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: context.textPrimaryColor),
                    ),
                    Text(
                      _isEdit ? 'Edit Saving Goal' : 'New Saving Goal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // * Preview of the goal being created, so the user sees the
                // * progress treatment the new goal will get.
                if (!_isEdit)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.violet, AppColors.pink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NEW GOAL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nameController.text.trim().isEmpty
                              ? 'Your goal'
                              : _nameController.text.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _targetController.text.trim().isEmpty
                              ? 'Set a target to start tracking'
                              : 'Target ${formatGoalMoney(double.tryParse(_targetController.text.trim()) ?? 0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                _FieldLabel('Goal name'),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 60,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'e.g. New laptop',
                    filled: true,
                    fillColor: context.cardBgAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                _FieldLabel('Target amount'),
                TextField(
                  controller: _targetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '\u0024',
                    prefixStyle: TextStyle(
                      fontSize: 22,
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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_isEdit ? 'Save changes' : 'Create goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.textPrimaryColor,
        ),
      ),
    );
  }
}
