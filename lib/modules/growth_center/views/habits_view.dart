import 'package:flutter/material.dart';
import 'package:youthx/core/widgets/confirm_delete_dialog.dart';
import 'package:youthx/modules/growth_center/views/habits/add_habit_modal.dart';
import '../models/habit_model.dart';
import '../widgets/habit_card.dart';
import '../widgets/goal_progress_bar.dart';

class HabitsView extends StatelessWidget {
  final List<HabitModel> habits;
  final ValueChanged<HabitModel> onAdd;
  final ValueChanged<HabitModel> onUpdate;
  final ValueChanged<HabitModel> onDelete;
  final void Function(String id, bool value) onToggle;

  const HabitsView({
    super.key,
    required this.habits,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggle,
  });

  void _openEditHabit(BuildContext context, HabitModel habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddHabitModal(existingHabit: habit, onSave: onUpdate),
    );
  }

  Future<void> _handleDeleteHabit(
    BuildContext context,
    HabitModel habit,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      message: 'This habit will be permanently deleted.',
    );
    if (confirmed) onDelete(habit);
  }

  int get _completedCount => habits.where((h) => h.isCompletedToday).length;
  double get _progress => habits.isEmpty ? 0 : _completedCount / habits.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Habits',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_completedCount/${habits.length} done today 💪',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddHabitModal(onSave: onAdd),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GoalProgressBar(
            progress: _progress,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return HabitCard(
                habit: habit,
                onToggleComplete: (value) => onToggle(habit.id, value),
                onEdit: () => _openEditHabit(context, habit),
                onDelete: () => _handleDeleteHabit(context, habit),
              );
            },
          ),
        ),
      ],
    );
  }
}
