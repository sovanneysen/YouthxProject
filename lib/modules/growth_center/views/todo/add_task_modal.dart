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

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      // yyyy-MM-dd, matches your screenshot format
      _dateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {}); // refresh so the field visually updates
    }
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

            Text(
              'DUE DATE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textSecondaryColor,
              ),
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

            PrimaryButton(
              label: _isEditing ? 'Update Task' : 'Save Task',
              onPressed: _titleController.text.trim().isEmpty
                  ? null
                  : _handleSave,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
