import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';
import '../models/saving_goal_model.dart';
import '../widgets/saving_goal_card.dart';
import '../widgets/saving_goal_deposit_sheet.dart';
import 'saving_goal_detail_page.dart';
import 'saving_goal_form_page.dart';

/// Full list of every saving goal.
///
/// The Finance home shows a preview of the first goals; this page shows the
/// complete set. It reads the same reactive `savingGoals` list as the home
/// screen, so a deposit or edit made anywhere is reflected here immediately.
class AllSavingGoalsPage extends GetView<FinanceController> {
  const AllSavingGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text(
          'Saving Goals',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      body: SafeArea(
        child: Obx(() {
          final goals = controller.savingGoals;

          if (goals.isEmpty) {
            return _EmptyGoals(onCreate: () => _openCreate(context));
          }

          return RefreshIndicator(
            onRefresh: controller.loadAll,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = goals[index];
                return SavingGoalCard(
                  goal: goal,
                  onTap: () => _openDetail(context, goal),
                  onDeposit: () => _openDeposit(context, goal),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SavingGoalFormPage()),
    );
  }

  Future<void> _openDetail(BuildContext context, SavingGoalModel goal) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SavingGoalDetailPage(goalId: goal.id),
      ),
    );
  }

  Future<void> _openDeposit(
    BuildContext context,
    SavingGoalModel goal,
  ) async {
    // The card's action deposits straight from the list, without a detour
    // through the detail screen.
    await SavingGoalDepositSheet.submit(context, goal);
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 48,
              color: context.textSecondaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No saving goals yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a goal to start tracking what you are saving for.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondaryColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create your first goal'),
            ),
          ],
        ),
      ),
    );
  }
}
