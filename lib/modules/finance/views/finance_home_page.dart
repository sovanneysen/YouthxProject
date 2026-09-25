import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_indicator.dart';
import '../controllers/finance_controller.dart';
import 'add_transaction_page.dart';
import 'all_transactions_page.dart';
import '../models/transaction_model.dart';
import '../../../core/theme/app_theme.dart';
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

                      // Spending breakdown
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
                              'Spending Breakdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SpendingBreakdown(categories: c.expenseCategories),
                          ],
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
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllTransactionsPage(),
                                ),
                              );
                              controller.loadAll();
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: c.transactions.isEmpty
                            ? const _EmptyTransactions()
                            : ListView.separated(
                                itemCount: c.recentTransactions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final tx = c.recentTransactions[index];
                                  return _TransactionTile(
                                    tx: tx,
                                    category: c.resolveCategory(tx),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddTransactionPage(),
                                        ),
                                      );
                                      controller.loadAll();
                                    },
                                  );
                                },
                              ),
                      ),
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

class _SpendingBreakdown extends StatelessWidget {
  const _SpendingBreakdown({required this.categories});

  final List<TransactionCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text(
        'No categories yet. Add a transaction to get started.',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }
    final visible = categories.take(4).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final cat in visible)
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[100],
                child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 6),
              Text(
                cat.name,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
      ],
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
    final amount =
        '\u0024${NumberFormat('#,##0.00').format(tx.amount.toDouble())}';
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
