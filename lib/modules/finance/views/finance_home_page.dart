import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_indicator.dart';
import '../controllers/finance_controller.dart';
import 'add_transaction_page.dart';
import 'all_transactions_page.dart';
import 'all_saving_goals_page.dart';
import 'saving_goal_detail_page.dart';
import 'saving_goal_form_page.dart';
import 'transaction_detail_page.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/saving_goal_card.dart';
import '../widgets/saving_goal_deposit_sheet.dart';
import '../models/transaction_model.dart';
import '../../../core/theme/app_theme.dart';
// ignore: duplicate_import
import '../models/transaction_model.dart';

/// Finance home — real data driven by [FinanceController].
///
/// State handling (GetX / reactive):
///  * `loading`  -> centered spinner
///  * `error`    -> error card with Retry button
///  * empty data -> friendly empty state
///  * otherwise  -> balance card + spending breakdown + recent transactions
class FinanceHomePage extends GetView<FinanceController> {
  const FinanceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Scaffold(
      backgroundColor: context.isDark ? context.bg : const Color(0xFFF0F3FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Finance',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTransactionPage(),
                        ),
                      );
                      // Refresh after a transaction is created/edited.
                      controller.loadAll();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Obx(() {
                  if (controller.loading.value) {
                    return const LoadingIndicator();
                  }
                  if (controller.error.value != null) {
                    return ErrorStateWidget(
                      message: controller.error.value!,
                      onRetry: controller.loadAll,
                    );
                  }
                  final balance = controller.totalBalance;
                  final income = controller.totalIncome;
                  final expense = controller.totalExpense;

                  // The page is a single scroll view rather than a Column
                  // with an Expanded transaction list. Adding the Saving Goals
                  // strip made the fixed content taller than the space left
                  // by the bottom nav on short screens, which overflowed.
                  // `recentTransactions` is capped at 4 items, so rendering
                  // them inline costs nothing.
                  return ListView(
                    children: [
                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A6CF7), Color(0xFF7B4AF7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL BALANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _money(balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _balanceStat(
                                    '↗ Income',
                                    _money(income),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _balanceStat(
                                    '↘ Expenses',
                                    '-\u0024' +
                                        NumberFormat(
                                          '#,##0.00',
                                        ).format(expense).replaceAll('-', ''),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category breakdown — totals computed from the real
                      // loaded transactions via FinanceController.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category Breakdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CategoryBreakdown(
                              expenseRows: c.expenseTotals,
                              incomeRows: c.incomeTotals,
                              totalExpense: c.totalExpense,
                              totalIncome: c.totalIncome,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Saving goals — a preview of the first few goals.
                      // Reads the same reactive list the goals list and detail
                      // screens use, so deposits made here or elsewhere show
                      // up without a manual refresh.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saving Goals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllSavingGoalsPage(),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: c.savingGoals.isEmpty
                            ? _EmptySavingGoals(
                                onCreate: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SavingGoalFormPage(),
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: c.savingGoals.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final goal = c.savingGoals[index];
                                  return SizedBox(
                                    width: 280,
                                    child: SavingGoalCard(
                                      goal: goal,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SavingGoalDetailPage(
                                              goalId: goal.id,
                                            ),
                                          ),
                                        );
                                      },
                                      onDeposit: () async {
                                        await SavingGoalDepositSheet.submit(
                                          context,
                                          goal,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              // No reload on return: edits and deletes made in
                              // the detail screen are already applied to the
                              // reactive `transactions` list, so a reload here
                              // would only add a loading flash.
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllTransactionsPage(),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (c.transactions.isEmpty)
                        const _EmptyTransactions()
                      else
                        ...c.recentTransactions.asMap().entries.map((entry) {
                          final tx = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _TransactionTile(
                              tx: tx,
                              category: c.resolveCategory(tx),
                              onTap: () async {
                                // Open the real detail flow (view / edit /
                                // delete). Edit and delete mutate the same
                                // `transactions` list this page observes, so
                                // the tile and the totals above it update
                                // without an extra reload.
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionDetailPage(
                                      transactionId: tx.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _money(double amount) {
    final v = amount.abs();
    final s = NumberFormat('#,##0.00').format(v);
    return amount < 0 ? '-\u0024$s' : '\u0024$s';
  }

  Widget _balanceStat(String label, String amount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder shown in the home Saving Goals strip when the user has no
/// goals yet, so the section is never a blank gap.
class _EmptySavingGoals extends StatelessWidget {
  const _EmptySavingGoals({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    // Kept as a single compact row: the strip this sits in is height-constrained,
    // so a stacked empty state would overflow.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No saving goals yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Track what you are saving for.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.tx,
    required this.category,
    this.onTap,
  });

  final TransactionModel tx;
  final TransactionCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {

    final isIncome = tx.type == 'income' || tx.type == 'INCOME';
    final sign = isIncome ? '+' : '-';
    // ignore: unused_local_variable
    final amount =
        '\u0024${NumberFormat('#,##0.00').format(tx.amount.toDouble())}';
    // ignore: unused_local_variable
    final label = _typeLabel(tx.type);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[100],
        child: Text(category.icon),
      ),
      title: Text(
        tx.note?.isNotEmpty == true ? tx.note! : category.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${category.name} · ${_dateLabel(tx.date)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '$sign\u0024${NumberFormat('#,##0.00').format(tx.amount.toDouble())}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isIncome ? Colors.green : context.textPrimaryColor,
        ),
      ),
    );
  }

  String _typeLabel(String t) =>
      (t == 'income' || t == 'INCOME') ? 'Income' : 'Expense';

  String _dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🧾', style: TextStyle(fontSize: 48)),
          SizedBox(height: 8),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Tap Add to record your first transaction.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
