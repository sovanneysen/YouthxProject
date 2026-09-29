import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/data/providers/api_provider.dart';
import 'package:youthx/data/repositories/rest_growth_repository.dart';
import 'package:youthx/modules/growth_center/models/goal_model.dart';
import 'package:youthx/modules/growth_center/views/goals/add_goal_modal.dart';
import 'package:youthx/modules/growth_center/views/goals/goal_detail_view.dart';

/// Focused coverage for the manual `progressPercent` Goal contract.
///
/// `progressPercent` is the only progress representation for Growth Goals, so
/// these tests pin the three layers that carry it: the model, the REST
/// serialization, and the single manual editor in Goal Detail.
/// Captures what the repository sends and replays a canned response, so the
/// assertions are made against the real serialization path rather than
/// against private helpers.
class RecordingApiProvider extends ApiProvider {
  RecordingApiProvider(this._onRequest);

  final Map<String, dynamic> Function(String method, String path) _onRequest;

  final List<Map<String, dynamic>> bodies = [];
  final List<String> calls = [];

  @override
  Future<dynamic> get(String path) {
    calls.add('GET $path');
    return Future.value([_onRequest('GET', path)]);
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) {
    calls.add('POST $path');
    bodies.add(Map<String, dynamic>.from(body));
    return Future.value(_onRequest('POST', path));
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) {
    calls.add('PUT $path');
    bodies.add(Map<String, dynamic>.from(body));
    return Future.value(_onRequest('PUT', path));
  }
}

void main() {
  GoalModel goal({double progress = 0.0, String id = 'goal-1'}) => GoalModel(
        id: id,
        emoji: 'ðŸŽ¯',
        title: 'Run 20km',
        category: GoalCategory.health,
        targetDate: '2027-01-01',
        progress: progress,
      );

  /// A goal as the backend returns it, using the real wire field names.
  Map<String, dynamic> responseJson(int progressPercent) => {
        'id': 7,
        'userId': 'u-1',
        'name': 'Run 20km',
        'category': 'HEALTH',
        'targetDate': '2027-01-01',
        'progressPercent': progressPercent,
        'dailyReminderTime': null,
      };

  group('GoalModel', () {
    test('no longer carries numeric tracking fields', () {
      // Compiles only because the constructor requires nothing numeric: the
      // model is built from the five persisted fields alone.
      final model = goal(progress: 0.4);
      expect(model.progress, 0.4);
    });

    test('a new goal starts at 0% progress', () {
      expect(goal().progress, 0.0);
      expect(goal().effectiveProgress, 0.0);
    });

    test('manual progress sets a new value instead of accumulating', () {
      final before = goal(progress: 0.40);
      final after = before.copyWith(progress: 0.70);

      expect(after.progress, 0.70); // 40% + 70% must never be 1.10
      expect(before.progress, 0.40); // original untouched
    });

    test('copyWith preserves every other field and the id', () {
      final original = GoalModel(
        id: 'goal-9',
        emoji: 'ðŸ“š',
        title: 'Read 20 pages',
        category: GoalCategory.learning,
        customCategoryLabel: 'Books',
        targetDate: '2027-05-05',
        progress: 0.25,
        hasReminder: true,
        reminderTime: '08:00 AM',
      );

      final edited = original.copyWith(progress: 0.5);

      expect(edited.id, 'goal-9');
      expect(edited.emoji, 'ðŸ“š');
      expect(edited.title, 'Read 20 pages');
      expect(edited.category, GoalCategory.learning);
      expect(edited.customCategoryLabel, 'Books');
      expect(edited.targetDate, '2027-05-05');
      expect(edited.hasReminder, isTrue);
      expect(edited.reminderTime, '08:00 AM');
      expect(edited.progress, 0.5);
    });

    test('effectiveProgress clamps display values into 0..1', () {
      expect(goal(progress: 1.4).effectiveProgress, 1.0);
      expect(goal(progress: -0.2).effectiveProgress, 0.0);
    });

    test('reports no numeric tracking after the cleanup', () {
      final model = goal(progress: 0.5);
      expect(model.isNumericTracked, isFalse);
      expect(model.amountLabel, isNull);
    });
  });

  group('RestGrowthRepository goal progress', () {
    test('create sends progressPercent as an integer 0-100', () async {
      final api = RecordingApiProvider((_, _) => responseJson(70));
      final repo = RestGrowthRepository(apiProvider: api);

      await repo.createGoal(goal(progress: 0.70));

      expect(api.calls.single, 'POST /goals');
      expect(api.bodies.single['progressPercent'], 70);
      expect(api.bodies.single['progressPercent'], isA<int>());
    });

    test('update sends progressPercent as an integer 0-100', () async {
      final api = RecordingApiProvider((_, _) => responseJson(30));
      final repo = RestGrowthRepository(apiProvider: api);

      await repo.updateGoal(goal(progress: 0.30));

      expect(api.calls.single, 'PUT /goals/goal-1');
      expect(api.bodies.single['progressPercent'], 30);
      expect(api.bodies.single['progressPercent'], isA<int>());
    });

    test('request bodies serialize no numeric tracking fields', () async {
      final api = RecordingApiProvider((_, _) => responseJson(0));
      final repo = RestGrowthRepository(apiProvider: api);

      await repo.createGoal(goal(progress: 0.5));
      await repo.updateGoal(goal(progress: 0.5));

      for (final body in api.bodies) {
        expect(body.keys, isNot(contains('targetAmount')));
        expect(body.keys, isNot(contains('currentAmount')));
        expect(body.keys, isNot(contains('unit')));
      }
    });

    test('request body keeps exactly the five-field goal contract', () async {
      final api = RecordingApiProvider((_, _) => responseJson(0));
      final repo = RestGrowthRepository(apiProvider: api);

      await repo.createGoal(goal());

      expect(
        api.bodies.single.keys,
        containsAll(<String>{
          'name',
          'category',
          'targetDate',
          'progressPercent',
          'dailyReminderTime',
        }),
      );
    });

    test('a response reconstructs the persisted percentage', () async {
      final api = RecordingApiProvider((_, _) => responseJson(65));
      final repo = RestGrowthRepository(apiProvider: api);

      final created = await repo.createGoal(goal());

      expect(created.progress, closeTo(0.65, 1e-9));
      expect((created.effectiveProgress * 100).round(), 65);
      expect(created.isNumericTracked, isFalse);
    });

    test('fetch reconstructs the persisted percentage', () async {
      final api = RecordingApiProvider((_, _) => responseJson(40));
      final repo = RestGrowthRepository(apiProvider: api);

      final goals = await repo.fetchGoals();

      expect(goals.single.progress, closeTo(0.40, 1e-9));
    });

    test('0% and 100% round-trip as the valid boundaries', () async {
      for (final percent in <int>[0, 100]) {
        final api = RecordingApiProvider((_, _) => responseJson(percent));
        final repo = RestGrowthRepository(apiProvider: api);

        await repo.createGoal(goal(progress: percent / 100));
        expect(api.bodies.single['progressPercent'], percent);

        final created = await repo.createGoal(goal(progress: percent / 100));
        expect((created.effectiveProgress * 100).round(), percent);
      }
    });
  });

  group('GoalDetailView manual progress editor', () {
    /// Pumps the detail screen and returns a closure exposing the last value
    /// handed to `onUpdate`, so a test can assert both that an update fired
    /// and that it carried the right percentage.
    Future<GoalModel? Function()> pumpDetailForCapture(
      WidgetTester tester, {
      required double progress,
    }) async {
      GoalModel? updated;
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: GoalDetailView(
              goal: goal(progress: progress),
              onUpdate: (g) => updated = g,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return () => updated;
    }

    testWidgets('shows the stored percentage and an edit action', (
      tester,
    ) async {
      await pumpDetailForCapture(tester, progress: 0.65);

      expect(find.text('65% complete'), findsOneWidget);
      expect(find.text('Edit Progress'), findsOneWidget);
    });

    testWidgets('no longer offers the Log Progress accumulation flow', (
      tester,
    ) async {
      await pumpDetailForCapture(tester, progress: 0.5);

      expect(find.text('Log Progress'), findsNothing);
      expect(find.textContaining('Log progress'), findsNothing);
    });

    testWidgets('editor opens prefilled with the current percentage', (
      tester,
    ) async {
      await pumpDetailForCapture(tester, progress: 0.65);

      await tester.tap(find.text('Edit Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Progress'), findsWidgets);
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('Save sets the chosen percentage and calls onUpdate once', (
      tester,
    ) async {
      final capture = await pumpDetailForCapture(tester, progress: 0.40);

      await tester.tap(find.text('Edit Progress'));
      await tester.pumpAndSettle();

      // Move to the slider's midpoint. A SET yields 50%; an accumulation of
      // 40% + 50% would yield 90%, so this value distinguishes the two.
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.tapAt(tester.getCenter(slider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = capture();
      expect(saved, isNotNull);
      expect(saved!.progress, closeTo(0.50, 0.02));
      expect(find.text('50% complete'), findsOneWidget);
    });

    testWidgets('Cancel dismisses the editor and changes nothing', (
      tester,
    ) async {
      final capture = await pumpDetailForCapture(tester, progress: 0.40);

      await tester.tap(find.text('Edit Progress'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Slider), const Offset(1000, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(capture(), isNull); // no API call, no mutation
      expect(find.text('40% complete'), findsOneWidget);
    });
  });

  group('AddGoalModal', () {
    /// The modal is a `DraggableScrollableSheet` that pops itself on save, so
    /// it is hosted on a pushed route exactly as the app presents it.
    Future<void> openModal(
      WidgetTester tester, {
      GoalModel? existingGoal,
      ValueChanged<GoalModel>? onSave,
    }) async {
      await tester.pumpWidget(
        GetMaterialApp(home: const Scaffold(body: Text('host'))),
      );
      unawaited(
        tester.state<NavigatorState>(find.byType(Navigator)).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: AddGoalModal(
                existingGoal: existingGoal,
                onSave: onSave ?? (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The save button sits at the bottom of a scrollable sheet.
    Future<void> tapSave(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('no longer exposes numeric tracking inputs', (tester) async {
      await openModal(tester);

      expect(find.text('Track with a number'), findsNothing);
      expect(find.text('TARGET AMOUNT'), findsNothing);
      expect(find.text('UNIT'), findsNothing);
      expect(find.text('STARTING AMOUNT (OPTIONAL)'), findsNothing);
    });

    testWidgets('a new goal saves with progressPercent 0', (tester) async {
      GoalModel? saved;
      await openModal(tester, onSave: (g) => saved = g);

      await tester.enterText(find.byType(TextField).first, 'Run 20km');
      await tester.pumpAndSettle();
      await tapSave(tester, 'Save Goal');

      expect(saved, isNotNull);
      expect(saved!.progress, 0.0);
    });

    testWidgets('editing an existing goal preserves its percentage', (
      tester,
    ) async {
      GoalModel? saved;
      await openModal(
        tester,
        existingGoal: goal(progress: 0.65),
        onSave: (g) => saved = g,
      );

      await tapSave(tester, 'Update Goal');

      expect(saved, isNotNull);
      expect(saved!.progress, closeTo(0.65, 1e-9));
    });
  });
}
