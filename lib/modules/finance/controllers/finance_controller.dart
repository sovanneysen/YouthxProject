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
      balance += t.type == 'income' ? t.amount.abs() : -t.amount.abs();
    }
    return balance;
  }

  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  double get totalExpense => transactions
      .where((t) => t.type != 'income')
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  List<TransactionModel> get recentTransactions => transactions.take(4).toList();

  // * Map category amount negative for display helper
  String _formatAmount(TransactionModel t) {
    final sign = t.type == 'income' ? '+' : '-';
    return '$sign\$${t.amount.abs().toStringAsFixed(2)}';
  }

  // * Map a backend category onto the first emoji-owning category in the
  // * filtered list (income vs expense) so tiles keep a stable icon.
  TransactionCategory _resolveCategory(TransactionModel t) {
    final pool = t.type == 'income' ? incomeCategories : expenseCategories;
    for (final c in pool) {
      if (c.id == t.category.id) return c;
    }
    return t.category;
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
      final updated =
          await repository.depositToSavingGoal(goal, amount);
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
