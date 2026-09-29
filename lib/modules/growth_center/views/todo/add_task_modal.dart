import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/modal_header.dart';
import '../../widgets/primary_button.dart';
import '../../models/task_model.dart';
import '../../utils/task_priority_style.dart';

class AddTaskModal extends StatefulWidget {
  final ValueChanged<TaskModel> onSave;
  final TaskModel? existingTask; // null = Add mode, non-null = Edit mode

  const AddTaskModal({super.key, required this.onSave, this.existingTask});

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  late final _titleController = TextEditingController(
    text: widget.existingTask?.title ?? '',
  );
  late final _dateController = TextEditingController(
    text: widget.existingTask?.dueDate == 'No date'
        ? ''
        : widget.existingTask?.dueDate ?? '',
  );

  // Default a new task to Medium priority (matches a sensible default,
  // same way your Habit modal defaulted frequency to daily)
  late TaskPriority _selectedPriority =
      widget.existingTask?.priority ?? TaskPriority.medium;

  bool get _isEditing => widget.existingTask != null;

  // The picker is bounded to the same window the field has always used.
  static final DateTime _minPickerDate = DateTime(2020);
  static final DateTime _maxPickerDate = DateTime(2100);

  /// True when the task currently carries a due date.
  ///
  /// Mirrors how the field is seeded, so a task stored as `'No date'` counts as
  /// having no date and therefore shows no Clear action.
  bool get _hasDueDate => _dateController.text.trim().isNotEmpty;

  /// Midnight today, used as the picker's fallback opening date.
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The date the picker should open on.
  ///
  /// `showDatePicker` asserts that [initialDate] lies inside the first/last
  /// date window, so any out-of-range stored value is clamped rather than
  /// trusted. An absent or unparseable value opens on today, which is also the
  /// behaviour a freshly picked date gets when the picker is reopened.
  DateTime get _initialPickerDate {
    final today = _today;
    final parsed = DateTime.tryParse(_dateController.text.trim());
    if (parsed == null) return today;

    // Compare on whole days: the stored value is a date with no time.
    final candidate = DateTime(parsed.year, parsed.month, parsed.day);
    if (candidate.isBefore(_minPickerDate)) return _minPickerDate;
    if (candidate.isAfter(_maxPickerDate)) return _maxPickerDate;
    return candidate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _initialPickerDate,
      firstDate: _minPickerDate,
      lastDate: _maxPickerDate,
    );
    if (picked != null) {
      // yyyy-MM-dd, matches your screenshot format
      _dateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {}); // refresh so the field and Clear action update
    }
  }

  /// Empties the due-date field.
  ///
  /// Saving then falls through the path that already existed for a task with no
  /// date, so nothing downstream needs to know the value was cleared.
  void _clearDueDate() {
    _dateController.clear();
    setState(() {}); // hides the Clear action again
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty) return;

    widget.onSave(
      TaskModel(
        // preserve id on edit, generate a new one on add
        id:
            widget.existingTask?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        priority: _selectedPriority,
        dueDate: _dateController.text.isEmpty
            ? 'No date'
            : _dateController.text,
        // preserve completion status on edit — editing a task shouldn't un-complete it
        isCompleted: widget.existingTask?.isCompleted ?? false,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // pushes the modal above the keyboard when typing
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModalHeader(
              title: _isEditing ? 'Edit Task' : 'Add Task',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),

            LabeledTextField(
              label: 'WHAT NEEDS DOING?',
              controller: _titleController,
              hintText: 'e.g. Submit assignment by 11:59 PM',
              hint: '',
            ),
            const SizedBox(height: 20),

            Text(
              'PRIORITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),

            // --- Priority pill picker ---
            Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                final color = TaskPriorityStyle.colorOf(priority);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPriority = priority),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : context.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        TaskPriorityStyle.labelOf(priority),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? color : context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DUE DATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondaryColor,
                  ),
                ),
                // Only meaningful while a date is set, so it stays hidden
                // otherwise. Sized to the 48dp minimum tap target.
                if (_hasDueDate)
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: _clearDueDate,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Clear date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                // blocks manual keyboard typing, forces the date picker
                child: LabeledTextField(
                  label: '',
                  controller: _dateController,
                  hintText: 'Select a date',
                  hint: '',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Listening to the controller is what makes the button react the
            // moment the title changes: reading `_titleController.text` while
            // building would only ever see the value from the last build, so
            // typing would leave a stale enabled/disabled state behind.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _titleController,
              builder: (context, title, _) => PrimaryButton(
                label: _isEditing ? 'Update Task' : 'Save Task',
                onPressed: title.text.trim().isEmpty ? null : _handleSave,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
