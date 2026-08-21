import 'package:flutter/material.dart';
import 'package:youthx/modules/growth_center/widgets/labeled_text_field.dart';
import 'package:youthx/modules/growth_center/widgets/modal_header.dart';
import 'package:youthx/modules/growth_center/widgets/primary_button.dart';
import 'package:youthx/modules/growth_center/widgets/selectable_grid.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/color_picker_row.dart';
import '../../models/habit_model.dart';

class AddHabitModal extends StatefulWidget {
  final ValueChanged<HabitModel> onSave;
  final HabitModel? existingHabit; // NEW
  const AddHabitModal({super.key, required this.onSave, this.existingHabit});

  @override
  State<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends State<AddHabitModal> {
  // final _nameController = TextEditingController();

  static const _emojiOptions = [
    '📓',
    '💧',
    '🌙',
    '🏋️',
    '🥗',
    '📵',
    '🧘',
    '🚶',
    '💊',
    '📖',
    '🎨',
    '🎵',
  ];
  // String _selectedEmoji = _emojiOptions.first;

  // HabitFrequency _frequency = HabitFrequency.daily;

  late final _nameController = TextEditingController(
    text: widget.existingHabit?.title ?? '',
  );

  late String _selectedEmoji =
      widget.existingHabit?.emoji ?? _emojiOptions.first;

  late HabitFrequency _frequency =
      widget.existingHabit?.frequency ?? HabitFrequency.daily;

  late Color _selectedColor =
      widget.existingHabit?.color ?? _colorOptions.first;

  bool get _isEditing => widget.existingHabit != null;

  static const _colorOptions = [
    Color(0xFF6366F1),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFFA855F7),
  ];
  // Color _selectedColor = _colorOptions.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) return;
    widget.onSave(
      HabitModel(
        id:
            widget.existingHabit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        emoji: _selectedEmoji,
        title: _nameController.text.trim(),
        frequency: _frequency,
        streak: widget.existingHabit?.streak ?? 0, // preserve streak on edit
        color: _selectedColor,
        isCompletedToday: widget.existingHabit?.isCompletedToday ?? false,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final emojiItems = _emojiOptions
        .map(
          (e) => SelectableGridItem<String>(value: e, emoji: e),
        ) // label omitted → no text row
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              ModalHeader(
                title: _isEditing ? 'Edit Habit' : 'Add New Habit',
                onClose: () => Navigator.of(context).pop(),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledTextField(
                        label: 'HABIT NAME',
                        hint: 'e.g. Drink 2L water',
                        controller: _nameController,
                        hintText: '',
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'PICK AN EMOJI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableGrid<String>(
                        items: emojiItems,
                        selectedValue: _selectedEmoji,
                        onSelected: (e) => setState(() => _selectedEmoji = e),
                        crossAxisCount: 6,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'FREQUENCY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedToggle<HabitFrequency>(
                        options: const [
                          SegmentedOption(
                            value: HabitFrequency.daily,
                            label: 'Daily',
                          ),
                          SegmentedOption(
                            value: HabitFrequency.weekly,
                            label: 'Weekly',
                          ),
                        ],
                        selectedValue: _frequency,
                        onSelected: (f) => setState(() => _frequency = f),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'COLOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ColorPickerRow(
                        colors: _colorOptions,
                        selectedColor: _selectedColor,
                        onSelected: (c) => setState(() => _selectedColor = c),
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameController,
                        builder: (context, value, _) {
                          return PrimaryButton(
                            label: _isEditing ? 'Update Habit' : 'Save Habit',
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
