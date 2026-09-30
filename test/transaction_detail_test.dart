import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/data/repositories/finance_repository.dart';
import 'package:youthx/modules/finance/controllers/finance_controller.dart';
import 'package:youthx/modules/finance/models/transaction_model.dart';
import 'package:youthx/modules/finance/views/transaction_detail_page.dart';

/// Widget coverage for the transaction detail flow: the real field values are
/// rendered, deleting asks for confirmation and removes the row, and a deleted
/// transaction resolves to a usable state instead of an endless spinner.
void main() {
  late FinanceController controller;
  late FinanceRepository repo;

  /// Registers the controller and lets `onInit` finish loading.
  ///
  /// The repository simulates latency with `Future.delayed`, and widget tests
  /// run on a fake clock, so the clock has to be advanced explicitly before the
  /// transaction list can be read — awaiting `loadAll()` directly would block
  /// forever.
  Future<void> bootController(WidgetTester tester) async {
    controller = FinanceController(repository: repo);
    Get.put<FinanceController>(controller);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpDetail(WidgetTester tester, String transactionId) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: TransactionDetailPage(transactionId: transactionId),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Runs a controller mutation and advances the fake clock so the repository's
  /// simulated latency can resolve. Awaiting such a future directly would
  /// deadlock, because the timers never elapse without a pump.
  Future<bool> mutate(WidgetTester tester, Future<bool> work) async {
    await tester.pump(const Duration(seconds: 1));
    return work;
  }

  setUp(() {
    Get.reset();
    repo = MockFinanceRepository();
  });

  testWidgets('renders type, amount, category, note and date from the model',
      (tester) async {
    await bootController(tester);
    // The mock seeds a "Morning coffee" expense of 4.50 under Food.
    final tx = controller.transactions
        .firstWhere((t) => t.note == 'Morning coffee');

    await pumpDetail(tester, tx.id);

    expect(find.text('EXPENSE'), findsOneWidget);
    expect(find.text('-\$4.50'), findsWidgets);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Morning coffee'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(find.text('Delete Transaction'), findsOneWidget);
  });

  testWidgets('an income transaction is labelled as income', (tester) async {
    await bootController(tester);
    final tx =
        controller.transactions.firstWhere((t) => t.type == 'income');

    await pumpDetail(tester, tx.id);

    expect(find.text('INCOME'), findsOneWidget);
    expect(find.textContaining(r'+$'), findsWidgets);
    expect(find.text('EXPENSE'), findsNothing);
  });

  testWidgets('a transaction without a note says so explicitly',
      (tester) async {
    await bootController(tester);
    final tx = await mutate(
      tester,
      controller.addTransaction(
        TransactionModel(
          id: '',
          type: 'expense',
          category: controller.expenseCategories.first,
          amount: 12,
          note: null,
          date: DateTime(2026, 5, 1),
        ),
      ),
    );
    expect(tx, isTrue);

    final created = controller.transactions.first;
    await pumpDetail(tester, created.id);

    expect(find.text('No note added'), findsOneWidget);
  });

  testWidgets('a long note wraps instead of overflowing', (tester) async {
    await bootController(tester);
    final longNote = 'A' * 600;
    await mutate(
      tester,
      controller.addTransaction(
        TransactionModel(
          id: '',
          type: 'expense',
          category: controller.expenseCategories.first,
          amount: 12,
          note: longNote,
          date: DateTime(2026, 5, 1),
        ),
      ),
    );

    await pumpDetail(tester, controller.transactions.first.id);

    expect(find.text(longNote), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete asks for confirmation and cancels without removing',
      (tester) async {
    await bootController(tester);
    final id = controller.transactions.first.id;
    await pumpDetail(tester, id);

    await tester.tap(find.text('Delete Transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this transaction?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this transaction?'), findsNothing);
    expect(controller.transactions.any((t) => t.id == id), isTrue);
  });

  testWidgets('confirmed delete removes the row', (tester) async {
    await bootController(tester);
    final id = controller.transactions.first.id;
    final before = controller.transactions.length;
    await pumpDetail(tester, id);

    await tester.tap(find.text('Delete Transaction'));
    await tester.pumpAndSettle();
    // The dialog's own Delete button is the last one on screen.
    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await tester.pumpAndSettle();

    expect(controller.transactions.any((t) => t.id == id), isFalse);
    expect(controller.transactions.length, before - 1);
  });

  testWidgets('a deleted transaction falls back to a usable empty state',
      (tester) async {
    await bootController(tester);
    final id = controller.transactions.first.id;
    await pumpDetail(tester, id);

    // Remove it behind the screen's back: the observed list no longer has it.
    await controller.deleteTransaction(
      controller.transactions.firstWhere((t) => t.id == id),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This transaction is no longer available.'),
      findsOneWidget,
    );
    expect(find.text('Back to Finance'), findsOneWidget);
    // No spinner left spinning forever.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an unknown id resolves to a usable empty state',
      (tester) async {
    await bootController(tester);

    await pumpDetail(tester, 'does-not-exist');

    expect(
      find.text('This transaction is no longer available.'),
      findsOneWidget,
    );
    expect(find.text('Back to Finance'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
