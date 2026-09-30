import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/data/repositories/finance_repository.dart';
import 'package:youthx/modules/finance/controllers/finance_controller.dart';
import 'package:youthx/modules/finance/models/transaction_model.dart';

/// Repository double whose transaction list is fully controlled by the test,
/// so the breakdown assertions describe exact real arithmetic instead of
/// depending on whatever the mock happens to seed.
///
/// Extends the existing [MockFinanceRepository] so the saving-goal half of the
/// contract stays satisfied without being restated here.
class _StubFinanceRepo extends MockFinanceRepository {
  _StubFinanceRepo({this.failUpdate = false, this.failDelete = false});

  final bool failUpdate;
  final bool failDelete;

  final List<TransactionCategory> _categories = [
    const TransactionCategory(id: 1, name: 'Food', icon: '\u{1F354}'),
    const TransactionCategory(id: 2, name: 'Transport', icon: '\u{1F68C}'),
    const TransactionCategory(id: 3, name: 'Salary', icon: '\u{1F3E2}', isIncome: true),
  ];

  final List<TransactionModel> _transactions = [];
  int updateCalls = 0;
  int deleteCalls = 0;

  TransactionCategory category(int id) =>
      _categories.firstWhere((c) => c.id == id);

  void add(String type, int categoryId, double amount, {String? note}) {
    _transactions.add(
      TransactionModel(
        id: 't${_transactions.length}',
        type: type,
        category: category(categoryId),
        amount: amount,
        note: note,
        date: DateTime(2026, 3, 14),
      ),
    );
  }

  @override
  Future<List<TransactionCategory>> fetchCategories() async =>
      List<TransactionCategory>.from(_categories);

  @override
  Future<List<TransactionModel>> fetchTransactions() async =>
      List<TransactionModel>.from(_transactions);

  @override
  Future<TransactionModel> updateTransaction(TransactionModel t) async {
    updateCalls++;
    if (failUpdate) throw Exception('update rejected');
    final i = _transactions.indexWhere((e) => e.id == t.id);
    if (i != -1) _transactions[i] = t;
    return t;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    deleteCalls++;
    if (failDelete) throw Exception('delete rejected');
    _transactions.removeWhere((e) => e.id == id);
  }
}

FinanceController _loaded(_StubFinanceRepo repo) {
  final controller = FinanceController(repository: repo);
  return controller;
}

void main() {
  setUp(Get.reset);

  group('category breakdown from real transactions', () {
    test('sums counts and totals per expense category', () async {
      final repo = _StubFinanceRepo()
        ..add('expense', 1, 10)
        ..add('expense', 1, 15)
        ..add('expense', 2, 30);
      final controller = _loaded(repo);
      await controller.loadAll();

      final rows = controller.expenseTotals;

      // Sorted by total descending: Transport (30) leads, Food (25) follows.
      expect(rows.map((r) => r.category.name), ['Transport', 'Food']);
      expect(rows.first.count, 1);
      expect(rows.first.total, 30.0);
      expect(rows.last.count, 2);
      expect(rows.last.total, 25.0);
    });

    test('keeps income out of the expense rows and vice versa', () async {
      final repo = _StubFinanceRepo()
        ..add('expense', 1, 20)
        ..add('income', 3, 500);
      final controller = _loaded(repo);
      await controller.loadAll();

      expect(controller.expenseTotals.map((r) => r.category.name), ['Food']);
      expect(controller.incomeTotals.map((r) => r.category.name), ['Salary']);
      expect(controller.totalExpense, 20.0);
      expect(controller.totalIncome, 500.0);
    });

    test('shareOf is proportional and always inside 0.0-1.0', () async {
      final repo = _StubFinanceRepo()
        ..add('expense', 1, 25)
        ..add('expense', 2, 75);
      final controller = _loaded(repo);
      await controller.loadAll();

      final rows = controller.expenseTotals;
      final total = controller.totalExpense; // 100

      expect(rows.first.category.name, 'Transport');
      expect(rows.first.shareOf(total), closeTo(0.75, 1e-9));
      expect(rows.last.shareOf(total), closeTo(0.25, 1e-9));
    });

    test('shareOf returns 0 for an empty group instead of dividing by zero',
        () {
      const row = CategoryTotal(
        category: TransactionCategory(id: 1, name: 'Food', icon: 'x'),
        count: 0,
        total: 0,
      );

      expect(row.shareOf(0), 0.0);
    });

    test('is empty when there are no transactions', () async {
      final controller = _loaded(_StubFinanceRepo());
      await controller.loadAll();

      expect(controller.expenseTotals, isEmpty);
      expect(controller.incomeTotals, isEmpty);
    });

    test('resolves the icon-bearing category copy from the loaded list',
        () async {
      final repo = _StubFinanceRepo()..add('expense', 1, 10);
      final controller = _loaded(repo);
      await controller.loadAll();

      expect(controller.expenseTotals.single.category.icon, '\u{1F354}');
    });
  });

  group('transaction update', () {
    test('replaces the list entry so the Finance list reflects new values',
        () async {
      final repo = _StubFinanceRepo()..add('expense', 1, 10, note: 'Coffee');
      final controller = _loaded(repo);
      await controller.loadAll();
      final original = controller.transactions.single;

      final ok = await controller.updateTransaction(
        TransactionModel(
          id: original.id,
          type: 'expense',
          category: repo.category(2),
          amount: 99.5,
          note: 'Taxi',
          date: DateTime(2026, 4, 1),
        ),
      );

      expect(ok, isTrue);
      expect(repo.updateCalls, 1);
      expect(controller.transactions, hasLength(1));

      final updated = controller.transactions.single;
      expect(updated.amount, 99.5);
      expect(updated.note, 'Taxi');
      expect(updated.category.name, 'Transport');
    });

    test('reports failure and surfaces a message without dropping the entry',
        () async {
      final repo = _StubFinanceRepo(failUpdate: true)..add('expense', 1, 10);
      final controller = _loaded(repo);
      await controller.loadAll();

      final ok = await controller.updateTransaction(
        TransactionModel(
          id: controller.transactions.single.id,
          type: 'expense',
          category: repo.category(1),
          amount: 50,
          date: DateTime(2026, 4, 1),
        ),
      );

      expect(ok, isFalse);
      expect(controller.error.value, isNotNull);
      expect(controller.transactions.single.amount, 10.0);
    });

    test('switching type to income moves the row into the income breakdown',
        () async {
      final repo = _StubFinanceRepo()..add('expense', 1, 10);
      final controller = _loaded(repo);
      await controller.loadAll();
      final original = controller.transactions.single;

      await controller.updateTransaction(
        TransactionModel(
          id: original.id,
          type: 'income',
          category: repo.category(3),
          amount: 10,
          date: original.date,
        ),
      );

      expect(controller.expenseTotals, isEmpty);
      expect(controller.incomeTotals.single.category.name, 'Salary');
      expect(controller.totalIncome, 10.0);
      expect(controller.totalExpense, 0.0);
    });
  });

  group('transaction delete', () {
    test('removes the transaction from the visible list', () async {
      final repo = _StubFinanceRepo()
        ..add('expense', 1, 10)
        ..add('income', 3, 500);
      final controller = _loaded(repo);
      await controller.loadAll();
      final target = controller.transactions.firstWhere((t) => t.type == 'expense');

      final ok = await controller.deleteTransaction(target);

      expect(ok, isTrue);
      expect(repo.deleteCalls, 1);
      expect(
        controller.transactions.any((t) => t.id == target.id),
        isFalse,
      );
      expect(controller.totalExpense, 0.0);
    });

    test('keeps the transaction and reports failure when the backend rejects',
        () async {
      final repo = _StubFinanceRepo(failDelete: true)..add('expense', 1, 10);
      final controller = _loaded(repo);
      await controller.loadAll();
      final target = controller.transactions.single;

      final ok = await controller.deleteTransaction(target);

      expect(ok, isFalse);
      expect(controller.error.value, isNotNull);
      expect(controller.transactions, hasLength(1));
      expect(controller.totalExpense, 10.0);
    });
  });
}
