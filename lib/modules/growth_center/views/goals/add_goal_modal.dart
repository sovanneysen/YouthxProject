import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../models/goal_model.dart';
import '../../utils/category_style.dart';
import '../../widgets/modal_header.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/selectable_grid.dart';
import '../../widgets/toggle_setting_row.dart';
import '../../widgets/tip_banner.dart';
import '../../widgets/primary_button.dart';

class AddGoalModal extends StatefulWidget {
  final ValueChanged<GoalModel> onSave;
  final GoalModel? existingGoal; // null = add mode, non-null = edit mode
  const AddGoalModal({super.key, required this.onSave, this.existingGoal});

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();

  final _customCategoryController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _unitController = TextEditingController();

  GoalCategory _selectedCategory = GoalCategory.health;

  bool _reminderEnabled = false;
  bool _numericTrackingEnabled = false;

  bool get _isEditing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    if (existing != null) {
      _nameController.text = existing.title;
      _dateController.text = existing.targetDate == 'No date'
          ? ''
          : existing.targetDate;
      _selectedCategory = existing.category;
      _customCategoryController.text = existing.customCategoryLabel ?? '';
      _reminderEnabled = existing.hasReminder;
      if (existing.isNumericTracked) {
        _numericTrackingEnabled = true;
        _targetAmountController.text = _trimZero(existing.targetAmount!);
        _currentAmountController.text = _trimZero(existing.currentAmount ?? 0);
        _unitController.text = existing.unit ?? '';
      }
    }
  }

  static String _trimZero(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _customCategoryController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(
        () => _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
      );
    }
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) return;

    final targetAmount = _numericTrackingEnabled
        ? double.tryParse(_targetAmountController.text.trim())
        : null;
    final currentAmount = _numericTrackingEnabled
        ? (double.tryParse(_currentAmountController.text.trim()) ?? 0)
        : null;

    // Numeric tracking only "counts" if a valid target > 0 was entered —
    // otherwise fall back to manual progress so we never divide by zero.
    final isValidNumeric = targetAmount != null && targetAmount > 0;

    widget.onSave(
      GoalModel(
        id:
            widget.existingGoal?.id ??
            DateTime.now().millisecondsSinceEpoch
                .toString(), // preserve id on edit
        emoji: CategoryStyle.emojiOf(_selectedCategory),
        title: _nameController.text.trim(),
        category: _selectedCategory,
        customCategoryLabel: _selectedCategory == GoalCategory.other
            ? _customCategoryController.text.trim()
            : null,
        targetDate: _dateController.text.isEmpty
            ? 'No date'
            : _dateController.text,
        progress:
            widget.existingGoal?.progress ?? 0.0, // preserve progress on edit
        hasReminder: _reminderEnabled,
        reminderTime: _reminderEnabled ? '8:00 AM' : null,
        targetAmount: isValidNumeric ? targetAmount : null,
        currentAmount: isValidNumeric ? currentAmount : null,
        unit: isValidNumeric ? _unitController.text.trim() : null,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = GoalCategory.values
        .map(
          (c) => SelectableGridItem(
            value: c,
            emoji: CategoryStyle.emojiOf(c),
            label: CategoryStyle.labelOf(c),
          ),
        )
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              ModalHeader(
                title: _isEditing ? 'Edit Goal' : 'Add New Goal',
                onClose: () => Navigator.of(context).pop(),
              ),
              Divider(height: 1, color: context.borderColor),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledTextField(
                        label: 'GOAL NAME',
                        hint: 'e.g. Read 30 minutes daily',
                        controller: _nameController,
                        hintText: '',
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'CATEGORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableGrid<GoalCategory>(
                        items: categoryItems,
                        selectedValue: _selectedCategory,
                        onSelected: (c) =>
                            setState(() => _selectedCategory = c),
                      ),
                      if (_selectedCategory == GoalCategory.other) ...[
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: 'CUSTOM CATEGORY',
                          hint: 'e.g. Sleep',
                          controller: _customCategoryController,
                          hintText: '',
                        ),
                      ],
                      const SizedBox(height: 22),
                      LabeledTextField(
                        label: 'TARGET DATE',
                        hint: 'Select a date',
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        hintText: '',
                      ),
                      const SizedBox(height: 18),
                      ToggleSettingRow(
                        title: 'Track with a number',
                        subtitle:
                            'e.g. "Save \$200" or "Run 20km" — progress updates automatically',
                        value: _numericTrackingEnabled,
                        onChanged: (v) =>
                            setState(() => _numericTrackingEnabled = v),
                      ),
                      if (_numericTrackingEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'TARGET AMOUNT',
                                hint: '200',
                                controller: _targetAmountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                hintText: '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'UNIT',
                                hint: '\$, km, pages...',
                                controller: _unitController,
                                hintText: '',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: 'STARTING AMOUNT (OPTIONAL)',
                          hint: '0',
                          controller: _currentAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          hintText: '',
                        ),
                      ],
                      const SizedBox(height: 18),
                      ToggleSettingRow(
                        title: 'Daily Reminder',
                        subtitle: 'Get notified at 8:00 AM',
                        value: _reminderEnabled,
                        onChanged: (v) => setState(() => _reminderEnabled = v),
                      ),
                      const SizedBox(height: 18),
                      const TipBanner(
                        text:
                            'Break your goal into small weekly milestones to stay consistent!',
                      ),
                      const SizedBox(height: 22),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameController,
                        builder: (context, value, _) {
                          return PrimaryButton(
                            label: _isEditing ? 'Update Goal' : 'Save Goal',
                            onPressed: value.text.trim().isEmpty
                                ? null
                                : _handleSave,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
