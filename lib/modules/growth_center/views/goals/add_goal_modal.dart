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
  final _reminderTimeController = TextEditingController();

  GoalCategory _selectedCategory = GoalCategory.health;

  bool _reminderEnabled = false;

  /// Time the daily reminder fires. 8:00 AM keeps the previous default, and an
  /// edited goal starts from the time already stored on the backend.
  static const _defaultReminder = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _reminderTime = _defaultReminder;

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
      final existingTime = _parseReminderTime(existing.reminderTime);
      if (existingTime != null) _reminderTime = existingTime;
    }
    _reminderTimeController.text = _formatReminderTime();
  }

  /// "08:00 AM" / "2:30 PM" (the repository's friendly form) -> [TimeOfDay].
  static TimeOfDay? _parseReminderTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$').firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? _defaultReminder.hour;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final suffix = match.group(3)?.toUpperCase();
    if (suffix == 'AM' && hour == 12) {
      hour = 0;
    } else if (suffix == 'PM' && hour != 12) {
      hour += 12;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// 12-hour friendly label the growth repository parses into the backend's
  /// 24-hour `dailyReminderTime`.
  String _formatReminderTime() {
    final period = _reminderTime.period == DayPeriod.am ? 'AM' : 'PM';
    final hour12 = _reminderTime.hourOfPeriod == 0
        ? 12
        : _reminderTime.hourOfPeriod;
    return '${hour12.toString().padLeft(2, '0')}:'
        '${_reminderTime.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _customCategoryController.dispose();
    _reminderTimeController.dispose();
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

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _reminderTime = picked;
      _reminderTimeController.text = _formatReminderTime();
    });
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) return;

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
        // A new goal starts at 0%. Progress is edited from Goal Detail, which
        // is the only place the manual progress editor lives. An edit must
        // not silently reset the stored percentage.
        progress: widget.existingGoal?.progress ?? 0.0,
        hasReminder: _reminderEnabled,
        reminderTime: _reminderEnabled ? _formatReminderTime() : null,
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
                        title: 'Daily Reminder',
                        subtitle: _reminderEnabled
                            ? 'Get notified at ${_formatReminderTime()}'
                            : 'Turn on to get a daily nudge',
                        value: _reminderEnabled,
                        onChanged: (v) => setState(() => _reminderEnabled = v),
                      ),
                      if (_reminderEnabled) ...[
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: 'REMINDER TIME',
                          hint: '8:00 AM',
                          controller: _reminderTimeController,
                          readOnly: true,
                          onTap: _pickReminderTime,
                          suffixIcon: const Icon(
                            Icons.access_time_outlined,
                            size: 18,
                          ),
                          hintText: '',
                        ),
                      ],
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
