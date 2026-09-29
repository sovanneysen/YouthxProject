import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/modules/growth_center/models/task_model.dart';
import 'package:youthx/modules/growth_center/views/todo/add_task_modal.dart';
import 'package:youthx/modules/growth_center/widgets/primary_button.dart';

/// Widget coverage for the Add/Edit Task modal.
///
/// Focuses on the three behaviours the modal owns: the Save button tracking
/// the title field, the date picker opening on the date the task already has,
/// and the ability to clear a due date again.
void main() {
  TaskModel taskWithTitle(String title) => TaskModel(
        id: 'task-1',
        title: title,
        priority: TaskPriority.high,
        dueDate: 'No date',
      );

  TaskModel taskWithDate({String dueDate = '2027-03-15'}) => TaskModel(
        id: 'task-1',
        title: 'Submit assignment',
        priority: TaskPriority.high,
        dueDate: dueDate,
        isCompleted: true,
      );

  /// Midnight today, the picker's fallback opening date.
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Hosts the modal on its own route so it behaves like the real
  /// `showModalBottomSheet` usage, including a working pop on save.
  Future<void> openModal(
    WidgetTester tester, {
    TaskModel? existingTask,
    ValueChanged<TaskModel>? onSave,
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: Text('host')),
      ),
    );
    unawaited(
      tester.state<NavigatorState>(find.byType(Navigator)).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: AddTaskModal(
              existingTask: existingTask,
              onSave: onSave ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The title field is the first text input in the modal.
  Finder titleField() => find.byType(TextField).first;

  /// The due-date field is the second text input. It sits inside an
  /// `AbsorbPointer` that forces the date picker, so the tappable widget is the
  /// `GestureDetector` wrapping it.
  Finder dateFieldTapTarget() => find
      .ancestor(
        of: find.byType(TextField).at(1),
        matching: find.byType(GestureDetector),
      )
      .first;

  /// Whether Save/Update is currently enabled, read through the shared button
  /// widget rather than its internals.
  bool saveEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed !=
      null;

  /// Types into the title field and settles the frame the listener schedules.
  Future<void> typeTitle(WidgetTester tester, String text) async {
    await tester.enterText(titleField(), text);
    // enterText leaves the rebuild scheduled; without a frame the button would
    // still report its previous state.
    await tester.pump();
  }

  String dueDateFieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text;

  /// Opens the picker and returns the date it opened on.
  Future<DateTime> openPicker(WidgetTester tester) async {
    await tester.tap(dateFieldTapTarget());
    await tester.pumpAndSettle();
    return tester
        .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
        .initialDate!;
  }

  group('Save button reacts to the title', () {
    testWidgets('Add mode starts disabled because the title is blank',
        (tester) async {
      await openModal(tester);

      expect(saveEnabled(tester), isFalse);
      expect(find.text('Save Task'), findsOneWidget);
    });

    testWidgets('Add mode enables as soon as a title is typed', (tester) async {
      await openModal(tester);
      expect(saveEnabled(tester), isFalse);

      await typeTitle(tester, 'Submit assignment');

      expect(saveEnabled(tester), isTrue);
    });

    testWidgets('Add mode disables again when the title is cleared',
        (tester) async {
      await openModal(tester);
      await typeTitle(tester, 'Submit assignment');
      expect(saveEnabled(tester), isTrue);

      await typeTitle(tester, '');

      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('a whitespace-only title keeps Save disabled', (tester) async {
      await openModal(tester);

      await typeTitle(tester, '   ');

      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('Edit mode starts enabled because the title already exists',
        (tester) async {
      await openModal(tester, existingTask: taskWithTitle('Submit assignment'));

      expect(saveEnabled(tester), isTrue);
      expect(find.text('Update Task'), findsOneWidget);
    });

    testWidgets('Edit mode disables when the existing title is cleared',
        (tester) async {
      await openModal(tester, existingTask: taskWithTitle('Submit assignment'));
      expect(saveEnabled(tester), isTrue);

      await typeTitle(tester, '');

      expect(saveEnabled(tester), isFalse);
    });
  });

  group('Clear date', () {
    testWidgets('is hidden when the task has no due date', (tester) async {
      await openModal(tester, existingTask: taskWithDate(dueDate: 'No date'));

      expect(find.text('Clear date'), findsNothing);
    });

    testWidgets('is hidden in Add mode until a date is chosen', (tester) async {
      await openModal(tester);

      expect(find.text('Clear date'), findsNothing);
    });

    testWidgets('appears when the task already has a due date', (tester) async {
      await openModal(tester, existingTask: taskWithDate());

      expect(find.text('Clear date'), findsOneWidget);
      expect(dueDateFieldText(tester), '2027-03-15');
    });

    testWidgets('clears the field and then hides itself', (tester) async {
      await openModal(tester, existingTask: taskWithDate());
      expect(find.text('Clear date'), findsOneWidget);

      await tester.tap(find.text('Clear date'));
      await tester.pumpAndSettle();

      expect(dueDateFieldText(tester), isEmpty);
      expect(find.text('Clear date'), findsNothing);
    });

    testWidgets('meets the 48dp minimum tap target', (tester) async {
      await openModal(tester, existingTask: taskWithDate());

      final size = tester.getSize(
        find.ancestor(
          of: find.text('Clear date'),
          matching: find.byType(TextButton),
        ),
      );

      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('saving after a clear uses the existing no-date path',
        (tester) async {
      TaskModel? saved;
      await openModal(
        tester,
        existingTask: taskWithDate(),
        onSave: (t) => saved = t,
      );

      await tester.tap(find.text('Clear date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update Task'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.dueDate, 'No date');
      // The rest of the task is untouched by clearing the date.
      expect(saved!.id, 'task-1');
      expect(saved!.title, 'Submit assignment');
      expect(saved!.isCompleted, isTrue);
    });
  });

  group('date picker opens on the right date', () {
    testWidgets('Add mode with no date opens on today', (tester) async {
      await openModal(tester);

      expect(await openPicker(tester), today());
    });

    testWidgets('Edit mode opens on the existing dueDate, not today',
        (tester) async {
      await openModal(tester, existingTask: taskWithDate(dueDate: '2027-03-15'));

      expect(await openPicker(tester), DateTime(2027, 3, 15));
    });

    testWidgets('reopens on the date that was just selected', (tester) async {
      await openModal(tester);

      final openedOn = await openPicker(tester);
      // Pick a day other than the one it opened on, so a stale opening date
      // cannot pass this test by coincidence.
      final targetDay = openedOn.day == 1 ? 2 : 1;
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text('$targetDay'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(dueDateFieldText(tester), isNotEmpty);
      final selected = DateTime.parse(dueDateFieldText(tester));
      expect(selected.day, targetDay);
      expect(selected, isNot(openedOn));

      expect(await openPicker(tester), selected);
    });

    testWidgets('a cleared date falls back to opening on today', (tester) async {
      await openModal(tester, existingTask: taskWithDate());

      await tester.tap(find.text('Clear date'));
      await tester.pumpAndSettle();

      expect(await openPicker(tester), today());
    });

    testWidgets('an out-of-range stored date is clamped to the window',
        (tester) async {
      // showDatePicker asserts its initial date is inside the 2020..2100
      // window, so a stored value outside it must be clamped, not thrown.
      await openModal(tester, existingTask: taskWithDate(dueDate: '1999-12-31'));

      expect(await openPicker(tester), DateTime(2020));
    });

    testWidgets('a date past the window is clamped to the last day',
        (tester) async {
      await openModal(tester, existingTask: taskWithDate(dueDate: '2500-01-01'));

      expect(await openPicker(tester), DateTime(2100));
    });

    testWidgets('an unparseable stored date falls back to today',
        (tester) async {
      await openModal(
        tester,
        existingTask: taskWithDate(dueDate: 'sometime next week'),
      );

      expect(await openPicker(tester), today());
    });

    testWidgets('cancelling the picker leaves the field unchanged',
        (tester) async {
      await openModal(tester, existingTask: taskWithDate());

      await tester.tap(dateFieldTapTarget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dueDateFieldText(tester), '2027-03-15');
    });
  });
}
