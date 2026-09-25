import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../models/goal_model.dart';
import '../../utils/category_style.dart';

class GoalDetailView extends StatefulWidget {
  final GoalModel goal;
  final ValueChanged<GoalModel>? onUpdate;

  const GoalDetailView({super.key, required this.goal, this.onUpdate});

  @override
  State<GoalDetailView> createState() => _GoalDetailViewState();
}

class _GoalDetailViewState extends State<GoalDetailView> {
  late GoalModel _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  Future<void> _openLogProgressSheet() async {
    final controller = TextEditingController();
    final added = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How much did you add towards "${_goal.title}"?',
                  style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: context.textPrimaryColor),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 20',
                    hintStyle: TextStyle(color: context.textSecondaryColor.withValues(alpha: 0.5)),
                    prefixText: _goal.unit == '\$' ? '\$ ' : null,
                    prefixStyle: TextStyle(color: context.textPrimaryColor),
                    suffixText: (_goal.unit != null && _goal.unit != '\$')
                        ? _goal.unit
                        : null,
                    suffixStyle: TextStyle(color: context.textPrimaryColor),
                    filled: true,
                    fillColor: context.cardBgAlt,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CategoryStyle.colorOf(_goal.category),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final value = double.tryParse(controller.text.trim());
                      Navigator.of(context).pop(value);
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (added == null) return; // cancelled or invalid input

    final updatedCurrent = (_goal.currentAmount ?? 0) + added;
    final reachedTarget =
        _goal.targetAmount != null && updatedCurrent >= _goal.targetAmount!;

    final updatedGoal = _goal.copyWith(currentAmount: updatedCurrent);

    setState(() => _goal = updatedGoal);
    widget.onUpdate?.call(updatedGoal);

    if (reachedTarget && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Goal reached — nice work!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final color = CategoryStyle.colorOf(goal.category);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        foregroundColor: context.textPrimaryColor,
        title: const Text('Goal Details'),
      ),
      floatingActionButton: goal.isNumericTracked
          ? FloatingActionButton.extended(
              onPressed: _openLogProgressSheet,
              backgroundColor: color,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Log Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(goal.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CategoryStyle.displayLabel(
                           goal.category,
                          goal.customCategoryLabel,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: context.isDark ? Border.all(color: context.borderColor) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: goal.effectiveProgress,
                      minHeight: 14,
                      backgroundColor: context.cardBgAlt,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(goal.effectiveProgress * 100).round()}% complete',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      if (goal.isNumericTracked)
                        Text(
                          goal.amountLabel!,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: context.isDark ? Border.all(color: context.borderColor) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Target date',
                    value: goal.targetDate,
                  ),
                  if (goal.hasReminder) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.notifications,
                      label: 'Reminder',
                      value: 'Daily ${goal.reminderTime ?? ''}',
                    ),
                  ],
                ],
              ),
            ),
            if (goal.isNumericTracked) const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.textSecondaryColor),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: context.textSecondaryColor)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
