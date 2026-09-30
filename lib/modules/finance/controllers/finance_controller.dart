import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/finance_repository.dart';
import '../models/saving_goal_model.dart';
import '../models/transaction_model.dart';

/// Drives the Finance screens from the real Draft Backend repository (REST),
/// mirroring the exact `GrowthController` file:/controller pattern:
///
///   - categories + transactions + saving goals are loaded together
///   - every mutation goes through the repository (backend persistence)
///   - loading / error / retry / refresh are first-class UI states
///
/// The repository is resolved from the app's Get bindings, so the exact same
/// controller runs against the real Draft Backend in production and against
/// the offline mock in widget tests.
class FinanceController extends GetxController {
  final FinanceRepository repository;

  FinanceController({required this.repository});

  // * State: category lists (expense + income share the backend category id)
  final RxList<TransactionCategory> expenseCategories =
      <TransactionCategory>[].obs;
  final RxList<TransactionCategory> incomeCategories =
      <TransactionCategory>[].obs;

  // * State: real transactions (page merged in the repository)
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  // * State: saving goals
  final RxList<SavingGoalModel> savingGoals = <SavingGoalModel>[].obs;

  // * UI state
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  // * Load every finance list from the repository in one pass.
  Future<void> loadAll() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait<Object>([
        repository.fetchCategories(),
        repository.fetchTransactions(),
        repository.fetchSavingGoals(),
      ]);
      final cats = results[0] as List<TransactionCategory>;
      final txs = results[1] as List<TransactionModel>;
      final goals = results[2] as List<SavingGoalModel>;

      expenseCategories.assignAll(cats.where((c) => !c.isIncome).toList());
      incomeCategories.assignAll(cats.where((c) => c.isIncome).toList());
      // "Other" lives in expense_categories with isIncome=false (DB UNIQUE
      // constraint prevents two rows named "Other"). Inject the same row into
      // incomeCategories so both grids show it. resolveCategory() matches by
      // category.id, so income "Other" transactions resolve correctly.
      final otherCat = cats.firstWhereOrNull((c) => c.name == 'Other');
      if (otherCat != null) incomeCategories.add(otherCat);
      transactions.assignAll(txs);
      savingGoals.assignAll(goals);
      // small delay keeps the spinner visible on fast networks
      await Future<void>.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      error.value = 'Could not load your finance data.';
      debugPrint('FinanceController.loadAll error: $e');
    } finally {
      loading.value = false;
    }
  }

  // * Convenience: normalized balance from real transactions.
  double get totalBalance {
    var balance = 0.0;
    for (final t in transactions) {
      balance += t.type.toLowerCase() == 'income' ? t.amount.abs() : -t.amount.abs();
    }
    return balance;
  }

  double get totalIncome => transactions
      .where((t) => t.type.toLowerCase() == 'income')
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  double get totalExpense => transactions
      .where((t) => t.type.toLowerCase() != 'income')
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  List<TransactionModel> get recentTransactions =>
      transactions.take(4).toList();

  // * Map category amount negative for display helper
  // ignore: unused_element
  String _formatAmount(TransactionModel t) {
    final sign = t.type == 'income' ? '+' : '-';
    return '$sign\$${t.amount.abs().toStringAsFixed(2)}';
  }

  // * Map a backend category onto the first emoji-owning category in the
  // * filtered list (income vs expense) so tiles keep a stable icon.
  TransactionCategory resolveCategory(TransactionModel t) {
    final isIncome = t.type.toLowerCase() == 'income';
    final pool = isIncome ? incomeCategories : expenseCategories;
    for (final c in pool) {
      if (c.id == t.category.id) return c;
    }

    // Fallback: search the other pool in case of data mismatch (e.g. old mock IDs)
    final otherPool = isIncome ? expenseCategories : incomeCategories;
    for (final c in otherPool) {
      if (c.id == t.category.id) return c;
    }

    return t.category;
  }

  // ── Real category breakdown ─────────────────────────────────────────────
  // Totals are derived from the transactions already loaded from
  // `GET /expenses`. There is no extra endpoint, no extra state and no
  // fabricated percentage: the bar width is `total / totalExpense` (or
  // `totalIncome`) computed at render time.

  /// Expense totals per category, from the loaded transactions.
  List<CategoryTotal> get expenseTotals => _totalsFor(isIncome: false);

  /// Income totals per category, from the loaded transactions.
  List<CategoryTotal> get incomeTotals => _totalsFor(isIncome: true);

  List<CategoryTotal> _totalsFor({required bool isIncome}) {
    // The backend stores ONE shared category list; a transaction's `type`
    // column is what separates income from expense, so that is the grouping
    // key used here (never the display colour).
    final buckets = <String, _CategoryAccumulator>{};
    for (final t in transactions) {
      if ((t.type.toLowerCase() == 'income') != isIncome) continue;
      // Prefer the backend id; fall back to the name so a category row with
      // no id still groups together instead of splitting into duplicates.
      final key = t.category.id?.toString() ?? 'name:${t.category.name}';
      final bucket =
          buckets.putIfAbsent(key, () => _CategoryAccumulator(t.category));
      bucket.count++;
      bucket.total += t.amount.abs();
    }

    // Resolve each bucket through the loaded category list so the row shows
    // the icon-bearing copy rather than the transaction's minimal stub.
    final pool = isIncome ? incomeCategories : expenseCategories;
    final rows = buckets.values.map((bucket) {
      final resolved = pool.firstWhereOrNull(
            (c) => c.id != null && c.id == bucket.category.id,
          ) ??
          bucket.category;
      return CategoryTotal(
        category: resolved,
        count: bucket.count,
        total: bucket.total,
      );
    }).toList()
      // Largest contributor first; name breaks ties so the order is stable.
      ..sort((a, b) {
        final byTotal = b.total.compareTo(a.total);
        return byTotal != 0
            ? byTotal
            : a.category.name.compareTo(b.category.name);
      });
    return rows;
  }

  // * Create a transaction through the repository and refresh.
  Future<bool> addTransaction(TransactionModel tx) async {
    try {
      final created = await repository.createTransaction(tx);
      transactions.insert(0, created);
      return true;
    } catch (e) {
      error.value = 'Could not save the transaction.';
      debugPrint('FinanceController.addTransaction error: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel tx) async {
    try {
      final updated = await repository.updateTransaction(tx);
      final index = transactions.indexWhere((e) => e.id == updated.id);
      if (index != -1) transactions[index] = updated;
      return true;
    } catch (e) {
      error.value = 'Could not update the transaction.';
      debugPrint('FinanceController.updateTransaction error: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(TransactionModel tx) async {
    try {
      await repository.deleteTransaction(tx.id);
      transactions.removeWhere((e) => e.id == tx.id);
      return true;
    } catch (e) {
      error.value = 'Could not delete the transaction.';
      debugPrint('FinanceController.deleteTransaction error: $e');
      return false;
    }
  }

  Future<bool> createSavingGoal(SavingGoalModel goal) async {
    try {
      final created = await repository.createSavingGoal(goal);
      savingGoals.add(created);
      return true;
    } catch (e) {
      error.value = 'Could not create the saving goal.';
      debugPrint('FinanceController.createSavingGoal error: $e');
      return false;
    }
  }

  Future<bool> depositToSavingGoal(SavingGoalModel goal, double amount) async {
    try {
      final updated = await repository.depositToSavingGoal(goal, amount);
      final index = savingGoals.indexWhere((g) => g.id == updated.id);
      if (index != -1) savingGoals[index] = updated;
      return true;
    } catch (e) {
      error.value = 'Could not record the deposit.';
      debugPrint('FinanceController.depositToSavingGoal error: $e');
      return false;
    }
  }

  Future<bool> updateSavingGoal(SavingGoalModel goal) async {
    try {
      final updated = await repository.updateSavingGoal(goal);
      final index = savingGoals.indexWhere((g) => g.id == updated.id);
      if (index != -1) savingGoals[index] = updated;
      return true;
    } catch (e) {
      error.value = 'Could not update the saving goal.';
      debugPrint('FinanceController.updateSavingGoal error: $e');
      return false;
    }
  }

  Future<bool> deleteSavingGoal(String id) async {
    try {
      await repository.deleteSavingGoal(id);
      savingGoals.removeWhere((g) => g.id == id);
      return true;
    } catch (e) {
      error.value = 'Could not delete the saving goal.';
      debugPrint('FinanceController.deleteSavingGoal error: $e');
      return false;
    }
  }

  void clearError() => error.value = null;
}

/// One row of the category breakdown shown on the Finance screen.
///
/// Every value is a pure function of the transactions already loaded from the
/// backend, so the bar can be sized from real totals rather than a guess.
class CategoryTotal {
  final TransactionCategory category;
  final int count;
  final double total;

  const CategoryTotal({
    required this.category,
    required this.count,
    required this.total,
  });

  /// This category's share of [groupTotal] as a 0.0–1.0 fraction.
  ///
  /// Guarded on a positive group total so a category-less account renders an
  /// empty bar instead of dividing by zero, and clamped so rounding can never
  /// produce a bar wider than its track.
  double shareOf(double groupTotal) =>
      groupTotal <= 0 ? 0.0 : (total / groupTotal).clamp(0.0, 1.0);
}

/// Mutable counter used while folding the transaction list into rows.
class _CategoryAccumulator {
  final TransactionCategory category;
  int count = 0;
  double total = 0;

  _CategoryAccumulator(this.category);
}
