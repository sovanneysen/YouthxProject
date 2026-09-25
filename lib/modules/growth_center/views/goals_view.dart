import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import 'goals/add_goal_modal.dart';
import 'goals/goal_detail_view.dart';
import '../models/goal_model.dart';
import '../widgets/goal_card.dart';

class GoalsView extends StatelessWidget {
  final List<GoalModel> goals;
  final ValueChanged<GoalModel> onAdd;
  final ValueChanged<GoalModel> onUpdate;
  final ValueChanged<GoalModel> onDelete;

  const GoalsView({
    super.key,
    required this.goals,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  void _openEditGoal(BuildContext context, GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGoalModal(
        existingGoal: goal,
        onSave: onUpdate, // just forward straight to the parent callback
      ),
    );
  }

  Future<void> _handleDeleteGoal(BuildContext context, GoalModel goal) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      message: 'This goal will be permanently deleted.',
    );
    if (confirmed) onDelete(goal);
  }

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
                    Text(
                      'My Goals',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${goals.length} active goal${goals.length == 1 ? '' : 's'} this season 🔥',
                      style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddGoalModal(onSave: onAdd),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: goals.length,
            itemBuilder: (context, index) => GoalCard(
              goal: goals[index],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GoalDetailView(goal: goals[index], onUpdate: onUpdate),
                ),
              ),
              onEdit: () => _openEditGoal(context, goals[index]),
              onDelete: () => _handleDeleteGoal(context, goals[index]),
            ),
          ),
        ),
      ],
    );
  }
}
