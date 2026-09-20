import 'dart:math';

import '../../modules/finance/models/saving_goal_model.dart';
import '../../modules/finance/models/transaction_model.dart';

/// Finance data-access contract (verified against the Draft Backend REST
/// surface, same contract the Growth module follows).
///
/// Transactions:  GET /expense-categories, GET /expenses (paged,
///                `PageResponse<ExpenseResponse>`), POST/PUT/DELETE /expenses
/// Saving goals:  GET /saving-goals, POST /saving-goals,
///                POST /saving-goals/{id}/deposit, PUT/DELETE /saving-goals/{id}
abstract class FinanceRepository {
  Future<List<TransactionCategory>> fetchCategories();
  Future<List<TransactionModel>> fetchTransactions();
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);

  Future<List<SavingGoalModel>> fetchSavingGoals();
  Future<SavingGoalModel> createSavingGoal(SavingGoalModel goal);
  Future<SavingGoalModel> depositToSavingGoal(
      SavingGoalModel goal, double amount);
  Future<SavingGoalModel> updateSavingGoal(SavingGoalModel goal);
  Future<void> deleteSavingGoal(String id);
}

/// In-memory Finance repository — keeps the widget test harness offline and
/// provides the seeded data the finance screens need. Production uses the
/// REST-backed counterpart (same pattern as Growth).
///
/// NOTE: numeric saving-goal tracking is fully supported by the Draft Backend
/// (`SavingGoal` has `targetAmount` + `currentAmount` columns and a
/// `/deposit` endpoint that returns updated `progressPercent`), so unlike the
/// Growth module no numeric columns are lost here.
class MockFinanceRepository implements FinanceRepository {
  final Random _rand = Random();

  final List<TransactionCategory> _categories = [];
  final List<TransactionModel> _transactions = [];
  final List<SavingGoalModel> _savingGoals = [];

  MockFinanceRepository() {
    _seed();
  }

  void _seed() {
    _categories.addAll([...expenseCategories, ...incomeCategories]);

    final now = DateTime.now();
    DateTime d(int days) => now.subtract(Duration(days: days));

    _transactions.addAll([
      _tx('Salary', 'income', 830.00, note: 'Monthly salary', date: d(0)),
      _tx('Food', 'expense', -4.50, note: 'Morning coffee', date: d(0)),
      _tx('Transport', 'expense', -45.00, note: 'Bus pass', date: d(1)),
      _tx('Shopping', 'expense', -89.20, note: 'Groceries', date: d(2)),
      _tx('Education', 'expense', -67.00,
          note: 'Draft backend books', date: d(2)),
    ]);
  }

  TransactionModel _tx(String catName, String type, double amount,
      {String? note, required DateTime date}) {
    return TransactionModel(
      id: _newId(),
      type: type,
      category: _categoryByName(catName),
      amount: amount.abs(),
      note: note,
      date: date,
    );
  }

  TransactionCategory _categoryByName(String name) =>
      _categories.firstWhere((c) => c.name == name);

  String _newId() => 'f${_rand.nextInt(1 << 31)}';

  @override
  Future<List<TransactionCategory>> fetchCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<TransactionCategory>.from(_categories);
  }

  @override
  Future<List<TransactionModel>> fetchTransactions() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<TransactionModel>.from(_transactions);
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel t) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final created = TransactionModel(
      id: _newId(),
      type: t.type,
      category: t.category,
      amount: t.amount,
      note: t.note,
      date: t.date,
    );
    _transactions.insert(0, created);
    return created;
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel t) async {
    final index = _transactions.indexWhere((e) => e.id == t.id);
    if (index != -1) _transactions[index] = t;
    return t;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<SavingGoalModel>> fetchSavingGoals() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<SavingGoalModel>.from(_savingGoals);
  }

  @override
  Future<SavingGoalModel> createSavingGoal(SavingGoalModel goal) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final created = SavingGoalModel(
      id: _newId(),
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      progressPercent: goal.targetAmount <= 0
          ? 0
          : (goal.currentAmount / goal.targetAmount) * 100,
    );
    _savingGoals.add(created);
    return created;
  }

  @override
  Future<SavingGoalModel> depositToSavingGoal(
      SavingGoalModel goal, double amount) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final updated = SavingGoalModel(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount + amount,
      progressPercent: goal.targetAmount <= 0
          ? 0
          : ((goal.currentAmount + amount) / goal.targetAmount) * 100,
    );
    final index = _savingGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) _savingGoals[index] = updated;
    return updated;
  }

  @override
  Future<SavingGoalModel> updateSavingGoal(SavingGoalModel goal) async {
    final index = _savingGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) _savingGoals[index] = goal;
    return goal;
  }

  @override
  Future<void> deleteSavingGoal(String id) async {
    _savingGoals.removeWhere((g) => g.id == id);
  }
}
