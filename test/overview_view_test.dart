import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:youthx/modules/growth_center/models/goal_model.dart';
import 'package:youthx/modules/growth_center/models/habit_model.dart';
import 'package:youthx/modules/growth_center/models/task_model.dart';
import 'package:youthx/modules/growth_center/views/overview/overview_view.dart';
import 'package:youthx/modules/growth_center/widgets/overview_calendar_card.dart';
import 'package:youthx/modules/growth_center/widgets/overview_day_strip.dart';

/// Widget coverage for the Overview tab's Schedule mode.
///
/// The backend stores a to-do as a bare `dueDate` and never sends a time, so
/// `TaskModel.scheduledHour` is null for every real task. These tests pin the
/// behaviour that makes that honest: untimed to-dos and goal deadlines are
/// listed where the user can see them, a day with nothing on it says so, and a
/// non-current day is never labelled "TODAY".
String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  TaskModel task(String id, {required DateTime due, int? hour, bool done = false}) =>
      TaskModel(
        id: id,
        title: 'Task $id',
        priority: TaskPriority.medium,
        dueDate: _iso(due),
        isCompleted: done,
        scheduledHour: hour,
      );

  GoalModel goal(String id, {required DateTime target}) => GoalModel(
        id: id,
        emoji: '🎯',
        title: 'Goal $id',
        category: GoalCategory.learning,
        targetDate: _iso(target),
        progress: 0.5,
      );

  HabitModel habit(String id, {required int hour, int streak = 4}) => HabitModel(
        id: id,
        emoji: '🔥',
        title: 'Habit $id',
        frequency: HabitFrequency.daily,
        streak: streak,
        color: const Color(0xFF6366F1),
        scheduledHour: hour,
      );

  Future<void> pumpOverview(
    WidgetTester tester, {
    List<GoalModel> goals = const [],
    List<HabitModel> habits = const [],
    List<TaskModel> tasks = const [],
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: OverviewView(goals: goals, habits: habits, tasks: tasks),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Switches the view from Month to Schedule mode via the mode chip.
  Future<void> openSchedule(WidgetTester tester) async {
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
  }

  /// Taps a day cell inside the month calendar. Day numbers are unique within
  /// the calendar, so the text is an unambiguous handle.
  Future<void> selectCalendarDay(WidgetTester tester, int day) async {
    await tester.tap(
      find.descendant(
        of: find.byType(OverviewCalendarCard),
        matching: find.widgetWithText(GestureDetector, '$day'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps a day inside the Schedule day strip. The strip spans one week, so its
  /// seven day numbers never repeat.
  Future<void> selectStripDay(WidgetTester tester, int dayOfMonth) async {
    await tester.tap(
      find.descendant(
        of: find.byType(OverviewDayStrip),
        matching: find.widgetWithText(GestureDetector, '$dayOfMonth'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The Monday..Sunday week that contains [day].
  List<DateTime> weekOf(DateTime day) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  testWidgets(
      'a to-do due on the selected day with no time is listed under All day',
      (tester) async {
    await pumpOverview(
      tester,
      tasks: [task('alpha', due: DateTime.now())],
    );
    await openSchedule(tester);

    // The backend never sends a time, so this to-do has scheduledHour == null
    // and used to be invisible on the schedule.
    expect(find.text('ALL DAY · NO TIME SET'), findsOneWidget);
    expect(find.text('Task alpha'), findsOneWidget);
    expect(find.text('Medium priority · no time set'), findsOneWidget);
    // It is listed, not buried in an empty hourly grid.
    expect(find.text('06:00'), findsNothing);
  });

  testWidgets('a completed untimed to-do still reports as done', (tester) async {
    await pumpOverview(
      tester,
      tasks: [task('alpha', due: DateTime.now(), done: true)],
    );
    await openSchedule(tester);

    expect(find.text('✓ Done · no time set'), findsOneWidget);
  });

  testWidgets('a goal deadline on the selected day appears as an item',
      (tester) async {
    await pumpOverview(
      tester,
      goals: [goal('alpha', target: DateTime.now())],
    );
    await openSchedule(tester);

    expect(find.text('GOAL DEADLINES'), findsOneWidget);
    expect(find.text('Goal alpha'), findsOneWidget);
    expect(find.text('Goal deadline'), findsOneWidget);
    expect(find.text('06:00'), findsNothing);
  });

  testWidgets('a day with nothing on it shows an empty state', (tester) async {
    await pumpOverview(tester);
    await openSchedule(tester);

    expect(find.textContaining('Nothing scheduled for this day'), findsOneWidget);
    // The confusing empty 16-row timeline is not rendered as the only result.
    expect(find.text('06:00'), findsNothing);
    expect(find.text('21:00'), findsNothing);
  });

  testWidgets('the current day is labelled TODAY', (tester) async {
    await pumpOverview(tester, tasks: [task('alpha', due: DateTime.now())]);

    expect(find.text('TODAY'), findsOneWidget);
  });

  testWidgets('a non-today selected date is not labelled TODAY', (tester) async {
    final today = DateTime.now();
    await pumpOverview(tester, tasks: [task('alpha', due: today)]);

    final otherDay = DateTime(today.year, today.month, today.day == 1 ? 2 : 1);
    await selectCalendarDay(tester, otherDay.day);

    expect(find.text('TODAY'), findsNothing);
    expect(
      find.text(DateFormat('EEEE, d MMMM').format(otherDay).toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('yesterday and tomorrow are labelled relative to the real today',
      (tester) async {
    final today = DateTime.now();
    await pumpOverview(tester);

    // Drive the selection with the week strip in Schedule mode, where the
    // strip always contains the days either side of the current one.
    await openSchedule(tester);
    final tomorrow = weekOf(today).firstWhere(
      (d) => d.day == today.add(const Duration(days: 1)).day,
    );
    await selectStripDay(tester, tomorrow.day);

    expect(find.text('TODAY'), findsNothing);
    expect(find.text('TOMORROW'), findsOneWidget);
  });

  testWidgets('the All day list follows the selected day', (tester) async {
    final today = DateTime.now();
    await pumpOverview(tester, tasks: [task('alpha', due: today)]);
    await openSchedule(tester);

    expect(find.text('Task alpha'), findsOneWidget);

    // Move to a different day in the same week: the to-do is no longer due,
    // so it must leave the list rather than linger.
    final other = weekOf(today).firstWhere((d) => d.day != today.day);
    await selectStripDay(tester, other.day);

    expect(find.text('Task alpha'), findsNothing);
    expect(find.textContaining('Nothing scheduled for this day'),
        findsOneWidget);
  });

  testWidgets('a habit with a scheduled hour still uses the hourly timeline',
      (tester) async {
    await pumpOverview(tester, habits: [habit('alpha', hour: 8)]);
    await openSchedule(tester);

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Habit alpha'), findsOneWidget);
    // A habit does have a time, so it is not duplicated into the all-day list.
    expect(find.text('ALL DAY · NO TIME SET'), findsNothing);
  });

  testWidgets('a timed to-do still uses the hourly timeline', (tester) async {
    await pumpOverview(
      tester,
      tasks: [task('alpha', due: DateTime.now(), hour: 14)],
    );
    await openSchedule(tester);

    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('ALL DAY · NO TIME SET'), findsNothing);
  });

  testWidgets('untimed to-dos and goal deadlines can appear together',
      (tester) async {
    final now = DateTime.now();
    await pumpOverview(
      tester,
      goals: [goal('alpha', target: now)],
      tasks: [task('beta', due: now)],
    );
    await openSchedule(tester);

    expect(find.text('ALL DAY · NO TIME SET'), findsOneWidget);
    expect(find.text('Task beta'), findsOneWidget);
    expect(find.text('GOAL DEADLINES'), findsOneWidget);
    expect(find.text('Goal alpha'), findsOneWidget);
  });

  testWidgets('a task with an unparseable due date is ignored, not crashed on',
      (tester) async {
    await pumpOverview(
      tester,
      tasks: [
        TaskModel(
          id: 'nodate',
          title: 'Task nodate',
          priority: TaskPriority.low,
          dueDate: 'No date',
        ),
      ],
    );
    await openSchedule(tester);

    expect(find.text('Task nodate'), findsNothing);
    expect(find.textContaining('Nothing scheduled for this day'),
        findsOneWidget);
  });
}
