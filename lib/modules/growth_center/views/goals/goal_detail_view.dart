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

  /// The single manual progress editor. [initialPercent] is pre-filled with the
  /// goal's stored percentage. A returned value means Save was tapped; null
  /// means Cancel, in which case nothing is mutated and no API call is made.
  Future<int?> _openEditProgressSheet(int initialPercent) {
    var draft = initialPercent.clamp(0, 100);
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final color = CategoryStyle.colorOf(_goal.category);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: BoxDecoration(
            color: sheetContext.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: sheetContext.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$draft%',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: sheetContext.textPrimaryColor,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(sheetContext).copyWith(
                      activeTrackColor: color,
                      thumbColor: color,
                      overlayColor: color.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: draft.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$draft%',
                      onChanged: (v) => setSheetState(() => draft = v.round()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: sheetContext.textSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(draft),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Sets progress to the value chosen in the editor (0-100). This is a manual
  /// SET, never an accumulation. On Save the goal flows through the existing
  /// `onUpdate` -> `GrowthController.updateGoal` -> `RestGrowthRepository
  /// .updateGoal` -> PUT /goals/{id} path, and the controller replaces the
  /// list entry with the server response.
  Future<void> _handleEditProgress() async {
    final saved = await _openEditProgressSheet(
      (_goal.effectiveProgress * 100).round(),
    );
    if (saved == null || !mounted) return; // cancelled — nothing changes

    final updated = _goal.copyWith(progress: (saved / 100).clamp(0.0, 1.0));
    setState(() => _goal = updated);
    widget.onUpdate?.call(updated);
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
      floatingActionButton: null,
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
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleEditProgress,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Progress'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
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
