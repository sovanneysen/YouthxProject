import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/data/repositories/growth_repository.dart';
import 'package:youthx/modules/growth_center/controllers/growth_controller.dart';
import 'package:youthx/modules/growth_center/models/goal_model.dart';
import 'package:youthx/modules/growth_center/models/habit_model.dart';
import 'package:youthx/modules/growth_center/models/task_model.dart';

/// Batch 3C — Growth write-path correctness.
///
/// Covers the two defects fixed in [GrowthController]:
///
///  * `toggleHabit` re-locates the habit by id *after* the awaited repository
///    call instead of writing back to a position captured before the await.
///  * `toggleTask` preserves `TaskModel.scheduledHour` when it rebuilds the
///    updated task.
///
/// The repository below is a test double implementing the existing
/// [GrowthRepository] contract. It exists so a repository call can be held
/// open across a `Completer`, which is what makes it possible to mutate the
/// controller's list *while* `toggleHabit` is suspended on its `await` —
/// the exact interleaving the defect depended on. No production abstraction
/// is added or changed.
class _ControllableGrowthRepository implements GrowthRepository {
  final List<HabitModel> habitStore = [];

  /// Completed when `completeHabit`/`uncompleteHabit` is called; lets a test
  /// hold the controller mid-`await`.
  Completer<HabitModel>? pendingHabitToggle;

  Completer<TaskModel>? pendingTaskUpdate;

  /// When non-null, the matching call fails immediately with this error.
  Object? habitToggleError;
  Object? taskUpdateError;

  /// The last task handed to [updateTask], so a test can assert exactly what
  /// the controller persisted.
  TaskModel? lastTaskSent;

  int completeHabitCalls = 0;
  int updateTaskCalls = 0;

  @override
  Future<HabitModel> completeHabit(HabitModel habit) {
    completeHabitCalls++;
    final error = habitToggleError;
    if (error != null) return Future<HabitModel>.error(error);
    final completer = Completer<HabitModel>();
    pendingHabitToggle = completer;
    return completer.future;
  }

  @override
  Future<HabitModel> uncompleteHabit(HabitModel habit) {
    final error = habitToggleError;
    if (error != null) return Future<HabitModel>.error(error);
    final completer = Completer<HabitModel>();
    pendingHabitToggle = completer;
    return completer.future;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) {
    updateTaskCalls++;
    lastTaskSent = task;
    final error = taskUpdateError;
    if (error != null) return Future<TaskModel>.error(error);
    final completer = Completer<TaskModel>();
    pendingTaskUpdate = completer;
    return completer.future;
  }

  @override
  Future<List<HabitModel>> fetchHabits() async =>
      List<HabitModel>.from(habitStore);

  @override
  Future<HabitModel> createHabit(HabitModel habit) async => habit;

  @override
  Future<HabitModel> updateHabit(HabitModel habit) async => habit;

  @override
  Future<void> deleteHabit(String id) async {}

  // Unused by these tests, but required to satisfy the contract.
  @override
  Future<List<GoalModel>> fetchGoals() async => const [];
  @override
  Future<GoalModel> createGoal(GoalModel goal) async => goal;
  @override
  Future<GoalModel> updateGoal(GoalModel goal) async => goal;
  @override
  Future<void> deleteGoal(String id) async {}
  @override
  Future<List<TaskModel>> fetchTasks() async => const [];
  @override
  Future<TaskModel> createTask(TaskModel task) async => task;
  @override
  Future<void> deleteTask(String id) async {}
}

void main() {
  // `Get.snackbar` (reached via `GrowthController._showError`) runs an
  // AnimationController plus a dismiss Timer. Under `testWidgets` those live
  // in FakeAsync, so an undrained snackbar fails the test with
  // `!timersPending` — and because GetX's snackbar queue is global, it also
  // poisons whichever test runs next. `Get.testMode` plus an explicit settle
  // keeps the error paths under test without touching production code.
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.testMode = false;
  });

  /// Drains the animation and the dismiss `Timer` the error snackbar queued.
  ///
  /// `pumpAndSettle` alone is not enough: it returns as soon as no frame is
  /// scheduled, but the auto-dismiss is driven by a standalone `Timer`, which
  /// is then still pending when the tree is disposed. So FakeAsync is advanced
  /// past the snackbar's display window first.
  Future<void> settleSnackbars(WidgetTester tester) async {
    await tester.pump(); // let GetX's queue actually present the snackbar
    await tester.pump(const Duration(seconds: 4)); // fire the dismiss timer
    await tester.pumpAndSettle(); // drain the exit animation
  }

  HabitModel habit(String id, {int streak = 0, bool completed = false}) =>
      HabitModel(
        id: id,
        emoji: '✅',
        title: 'Habit $id',
        frequency: HabitFrequency.daily,
        streak: streak,
        color: const Color(0xFF6366F1),
        isCompletedToday: completed,
      );

  TaskModel task(String id, {int? scheduledHour, bool completed = false}) =>
      TaskModel(
        id: id,
        title: 'Task $id',
        priority: TaskPriority.medium,
        dueDate: '2026-06-25',
        isCompleted: completed,
        scheduledHour: scheduledHour,
      );

  /// The habit with [id] currently in the controller's list, or null.
  HabitModel? habitWithId(GrowthController controller, String id) {
    for (final h in controller.habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Pumps a bare Get app so `Get.snackbar` has an overlay to attach to.
  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Text('h'))));
  }

  group('toggleHabit writes by id, not by a stale index', () {
    testWidgets(
      'updates the matching habit when an earlier habit is removed mid-flight',
      (tester) async {
        await pumpHost(tester);
        final repository = _ControllableGrowthRepository();
        final controller = GrowthController(repository: repository);
        controller.habits.assignAll([
          habit('a'),
          habit('b'), // the one being toggled, index 1
          habit('c'),
        ]);

        // Start the toggle but do not await it: the repository call suspends
        // on its completer, so the controller is parked on the `await`.
        final pending = controller.toggleHabit('b', true);
        await tester.pump();
        expect(repository.completeHabitCalls, 1);
        expect(repository.pendingHabitToggle, isNotNull);

        // Mutate the list *while* the controller is suspended. Removing 'a'
        // shifts 'b' from index 1 to index 0 and leaves the captured index
        // pointing at 'c'.
        controller.habits.removeWhere((h) => h.id == 'a');
        expect(controller.habits.map((h) => h.id).toList(), ['b', 'c']);

        repository.pendingHabitToggle!
            .complete(habit('b', streak: 1, completed: true));
        await pending;
        await tester.pump();

        // The result landed on 'b', the habit that was actually toggled.
        expect(controller.habits.map((h) => h.id).toList(), ['b', 'c']);
        expect(habitWithId(controller, 'b')!.streak, 1);
        expect(habitWithId(controller, 'b')!.isCompletedToday, isTrue);

        // The neighbour was not written to, and no duplicate appeared.
        expect(habitWithId(controller, 'c')!.streak, 0);
        expect(habitWithId(controller, 'c')!.isCompletedToday, isFalse);
      },
    );

    testWidgets(
      'no-ops without touching a neighbour when the habit is gone on return',
      (tester) async {
        await pumpHost(tester);
        final repository = _ControllableGrowthRepository();
        final controller = GrowthController(repository: repository);
        controller.habits.assignAll([
          habit('a'),
          habit('b'), // toggled, index 1
          habit('c'),
          habit('d'), // the neighbour a stale index 1 would clobber
        ]);

        final pending = controller.toggleHabit('b', true);
        await tester.pump();
        expect(repository.pendingHabitToggle, isNotNull);

        // 'b' is removed while the call is in flight, and the list is left
        // long enough that the old `index < habits.length` guard would still
        // have passed.
        controller.habits.removeWhere((h) => h.id == 'a' || h.id == 'b');
        expect(controller.habits.map((h) => h.id).toList(), ['c', 'd']);

        repository.pendingHabitToggle!
            .complete(habit('b', streak: 1, completed: true));
        await expectLater(pending, completes);

        // Nothing was resurrected and no neighbour was overwritten.
        expect(controller.habits.map((h) => h.id).toList(), ['c', 'd']);
        expect(habitWithId(controller, 'c')!.streak, 0);
        expect(habitWithId(controller, 'd')!.streak, 0);
        expect(habitWithId(controller, 'b'), isNull);
      },
    );

    testWidgets('ignores an id that is not in the list at all',
        (tester) async {
      await pumpHost(tester);
      final repository = _ControllableGrowthRepository();
      final controller = GrowthController(repository: repository);
      controller.habits.assignAll([habit('a')]);

      await controller.toggleHabit('missing', true);

      expect(repository.completeHabitCalls, 0);
      expect(controller.habits.map((h) => h.id).toList(), ['a']);
    });
  });

  group('toggleTask preserves scheduledHour', () {
    testWidgets('keeps a non-null scheduledHour on the updated task',
        (tester) async {
      await pumpHost(tester);
      final repository = _ControllableGrowthRepository();
      final controller = GrowthController(repository: repository);
      controller.tasks.assignAll([task('t1', scheduledHour: 14)]);

      final pending = controller.toggleTask(task('t1', scheduledHour: 14), true);
      await tester.pump();

      // What the controller persists must still carry the hour.
      expect(repository.lastTaskSent!.scheduledHour, 14);
      expect(repository.lastTaskSent!.isCompleted, isTrue);

      repository.pendingTaskUpdate!.complete(repository.lastTaskSent!);
      await pending;
      await tester.pump();

      expect(controller.tasks.single.scheduledHour, 14);
      expect(controller.tasks.single.isCompleted, isTrue);
    });

    testWidgets('leaves a null scheduledHour null', (tester) async {
      await pumpHost(tester);
      final repository = _ControllableGrowthRepository();
      final controller = GrowthController(repository: repository);
      controller.tasks.assignAll([task('t1')]);

      final pending = controller.toggleTask(task('t1'), true);
      await tester.pump();
      expect(repository.lastTaskSent!.scheduledHour, isNull);

      repository.pendingTaskUpdate!.complete(repository.lastTaskSent!);
      await pending;

      expect(controller.tasks.single.scheduledHour, isNull);
    });
  });

  group('existing toggle behaviour is unchanged', () {
    testWidgets('toggleHabit success updates the toggled habit only',
        (tester) async {
      await pumpHost(tester);
      final repository = _ControllableGrowthRepository();
      final controller = GrowthController(repository: repository);
      controller.habits.assignAll([habit('a'), habit('b')]);

      final pending = controller.toggleHabit('b', true);
      await tester.pump();
      repository.pendingHabitToggle!
          .complete(habit('b', streak: 4, completed: true));
      await pending;
      await tester.pump();

      expect(habitWithId(controller, 'b')!.streak, 4);
      expect(habitWithId(controller, 'a')!.streak, 0);
    });

    testWidgets('toggleHabit failure is swallowed and leaves the list intact',
        (tester) async {
      await pumpHost(tester);
      final repository = _ControllableGrowthRepository()
        ..habitToggleError = Exception('backend down');
      final controller = GrowthController(repository: repository);
      controller.habits.assignAll([habit('a'), habit('b')]);

      await expectLater(controller.toggleHabit('b', true), completes);
      await settleSnackbars(tester);

      // No throw escaped, and nothing was written.
      expect(habitWithId(controller, 'b')!.streak, 0);
      expect(habitWithId(controller, 'b')!.isCompletedToday, isFalse);
    });

    testWidgets('toggleTask failure is swallowed and leaves the list intact',
        (tester) async {
      await pumpHost(tester);
      final repository = _ControllableGrowthRepository()
        ..taskUpdateError = Exception('backend down');
      final controller = GrowthController(repository: repository);
      controller.tasks.assignAll([task('t1')]);

      await expectLater(controller.toggleTask(task('t1'), true), completes);
      await settleSnackbars(tester);

      expect(controller.tasks.single.isCompleted, isFalse);
    });

    testWidgets('sibling updateTask still re-locates the task by id',
        (tester) async {
      // Regression guard: updateTask already used the id-lookup pattern that
      // toggleHabit now follows, so pin that it stays that way.
      await pumpHost(tester);
      final repository = _ControllableGrowthRepository();
      final controller = GrowthController(repository: repository);
      controller.tasks.assignAll([task('a'), task('b')]);

      final pending = controller.updateTask(task('b', completed: true));
      await tester.pump();
      controller.tasks.removeWhere((t) => t.id == 'a');

      repository.pendingTaskUpdate!.complete(repository.lastTaskSent!);
      await pending;
      await tester.pump();

      expect(controller.tasks.map((t) => t.id).toList(), ['b']);
      expect(controller.tasks.single.isCompleted, isTrue);
    });
  });
}
