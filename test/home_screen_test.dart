import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/auth/controllers/auth_controller.dart';
import 'package:youthx/auth/views/home_screen.dart';
import 'package:youthx/core/network/token_store.dart';
import 'package:youthx/core/storage/local_profile_store.dart';
import 'package:youthx/core/theme/theme_controller.dart';
import 'package:youthx/data/models/auth_user_model.dart';
import 'package:youthx/data/models/local_profile_model.dart';
import 'package:youthx/data/models/post_model.dart';
import 'package:youthx/data/models/user_model.dart';
import 'package:youthx/data/providers/api_provider.dart';
import 'package:youthx/data/repositories/auth_repository.dart';
import 'package:youthx/data/repositories/community_repository.dart';
import 'package:youthx/data/repositories/finance_repository.dart';
import 'package:youthx/data/repositories/growth_repository.dart';
import 'package:youthx/modules/community/controllers/community_controller.dart';
import 'package:youthx/modules/finance/controllers/finance_controller.dart';
import 'package:youthx/modules/growth_center/controllers/growth_controller.dart';
import 'package:youthx/modules/growth_center/models/goal_model.dart';
import 'package:youthx/modules/growth_center/models/habit_model.dart';
import 'package:youthx/modules/profile/controllers/profile_data_controller.dart';

/// Widget coverage for the Home tab.
///
/// Home is a pure view over the controllers that already own the data, so
/// these tests drive those controllers directly and assert that what renders
/// is their real state — and that the placeholder values the screen used to
/// hardcode are gone.
class _StubAuthRepository extends AuthRepository {
  static final user = AuthUserModel(
    id: 'u-me',
    email: 'alex@university.edu',
    fullName: 'Alex Johnson',
    createdAt: DateTime(2025, 3, 4),
  );

  @override
  Future<AuthUserModel> fetchMe() async => user;

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async =>
      LoginResponseModel(token: 'jwt', user: user);

  @override
  Future<AuthUserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async =>
      user;
}

/// Mock repositories simulate latency with `Future.delayed`, and widget tests
/// run on a fake clock, so the timers must be advanced once after registration.
const _settleDelay = Duration(seconds: 1);

class _MemoryProfileStore implements LocalProfileStore {
  final Map<String, LocalProfile> _entries = <String, LocalProfile>{};

  @override
  Future<LocalProfile?> read(String userId) async =>
      userId.isEmpty ? null : _entries[userId];

  @override
  Future<void> write(String userId, LocalProfile profile) async {
    if (userId.isEmpty) return;
    _entries[userId] = profile;
  }

  @override
  Future<void> clear(String userId) async => _entries.remove(userId);
}

void main() {
  late CommunityController community;
  late GrowthController growth;
  late FinanceController finance;
  late ProfileDataController profile;

  HabitModel habit(String id, {int streak = 3, bool done = false, int? hour}) =>
      HabitModel(
        id: id,
        emoji: 'H',
        title: 'Habit $id',
        frequency: HabitFrequency.daily,
        streak: streak,
        color: const Color(0xFF6366F1),
        isCompletedToday: done,
        scheduledHour: hour,
      );

  GoalModel goal(String id) => GoalModel(
        id: id,
        emoji: 'G',
        title: 'Goal $id',
        category: GoalCategory.learning,
        targetDate: '2026-12-31',
        progress: 0.5,
      );

  PostModel post(String id, String authorId, String caption) => PostModel(
        id: id,
        author: UserModel(id: authorId, name: 'Priya Sharma'),
        createdAt: DateTime(2026, 1, 1),
        caption: caption,
      );

  /// Registers the real controllers over the in-memory repositories, then
  /// replaces their contents with an explicit data set so assertions never
  /// depend on what a mock happened to seed.
  Future<void> boot(
    WidgetTester tester, {
    List<HabitModel> habits = const [],
    List<GoalModel> goals = const [],
    List<PostModel> posts = const [],
    LocalProfile? localProfile,
    bool growthLoading = false,
  }) async {
    final auth = AuthController(
      authRepository: _StubAuthRepository(),
      tokenStore: MemoryTokenStore(),
    );
    Get.put<AuthController>(auth, permanent: true);
    // The header reads the session identity, so Home has to be signed in.
    auth.currentUser.value = _StubAuthRepository.user;

    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<ApiProvider>(ApiProvider(tokenStore: MemoryTokenStore()),
        permanent: true);

    community = CommunityController(repository: MockCommunityRepository());
    Get.put<CommunityController>(community, permanent: true);

    growth = GrowthController(repository: MockGrowthRepository());
    Get.put<GrowthController>(growth, permanent: true);

    finance = FinanceController(repository: MockFinanceRepository());
    Get.put<FinanceController>(finance, permanent: true);

    profile = ProfileDataController(store: _MemoryProfileStore());
    Get.put<ProfileDataController>(profile, permanent: true);

    // `Get.put` runs `onInit`, which starts the controllers' own loads. Flush
    // the fake clock so the explicit data set below is what the screen reads.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_settleDelay);

    community
      ..posts.assignAll(posts)
      ..loading.value = false
      ..feedError.value = null;
    growth
      ..habits.assignAll(habits)
      ..goals.assignAll(goals)
      ..tasks.clear()
      ..error.value = null
      ..loading.value = growthLoading;
    if (localProfile != null) profile.localProfile.value = localProfile;
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: HomeScreen()));
    await tester.pump();
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  group('identity', () {
    testWidgets('greets the signed-in account by its real name', (tester) async {
      await boot(tester);
      await pumpHome(tester);

      expect(find.text('Alex Johnson'), findsOneWidget);
      expect(find.textContaining('Good '), findsOneWidget);
      // The greeting line opens with the real first name.
      expect(find.textContaining('Alex,'), findsOneWidget);
    });

    testWidgets('uses the Batch 2C local display-name override', (tester) async {
      await boot(
        tester,
        localProfile: LocalProfile(displayName: 'Alex Rivers'),
      );
      await pumpHome(tester);

      expect(find.text('Alex Rivers'), findsOneWidget);
      expect(find.text('Alex Rivers, '), findsNothing);
      // Initials follow the overridden name too.
      expect(find.text('AR'), findsOneWidget);
      expect(find.text('Alex Johnson'), findsNothing);
    });
  });

  group('statistics', () {
    testWidgets('show the real longest streak and goal count', (tester) async {
      await boot(
        tester,
        habits: [
          habit('a', streak: 12, done: true),
          habit('b', streak: 5),
        ],
        goals: [goal('g1'), goal('g2'), goal('g3')],
      );
      await pumpHome(tester);

      // Longest real habit streak, not the old hardcoded 7.
      expect(find.text('12'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('Goals Active'), findsOneWidget);
    });

    testWidgets('show a real zero when the account has nothing yet',
        (tester) async {
      await boot(tester);
      // The mock repository seeds transactions on construction; drop them so
      // this case really is an account with no money recorded yet.
      finance.transactions.clear();
      await pumpHome(tester);

      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('\$0.00'), findsOneWidget);
    });

    testWidgets('show a dash while the data is still loading', (tester) async {
      await boot(tester, growthLoading: true);
      await pumpHome(tester);

      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('balance comes from the loaded transactions', (tester) async {
      await boot(tester);
      await pumpHome(tester);

      // MockFinanceRepository seeds 830.00 income and 205.70 of expenses.
      expect(find.text('\$624.30'), findsOneWidget);
    });
  });

  group("today's progress", () {
    testWidgets('counts the habits actually completed today', (tester) async {
      await boot(
        tester,
        habits: [
          habit('a', done: true),
          habit('b', done: true),
          habit('c'),
        ],
      );
      await pumpHome(tester);

      expect(find.text('2 of 3 habits done today'), findsOneWidget);
      expect(find.text('2 of 3 habits done'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('says so plainly when every habit is done', (tester) async {
      await boot(tester, habits: [habit('a', done: true)]);
      await pumpHome(tester);

      expect(find.text('All 1 habits done today 🎉'), findsOneWidget);
    });

    testWidgets('invites the user to create something when there is nothing',
        (tester) async {
      await boot(tester);
      await pumpHome(tester);

      expect(find.text('No habits or to-dos yet'), findsOneWidget);
      expect(
        find.text('Add one in the Growth Center to start tracking.'),
        findsOneWidget,
      );
      // No bar is drawn when there is no real progress to show.
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group("today's habits", () {
    testWidgets('lists the real habits and keeps the view-all shortcut',
        (tester) async {
      await boot(
        tester,
        habits: [habit('a', streak: 4, done: true), habit('b', streak: 2)],
      );
      await pumpHome(tester);

      expect(find.text('Habit a'), findsOneWidget);
      expect(find.text('Habit b'), findsOneWidget);
      expect(find.text('1/2 done'), findsOneWidget);
      expect(find.text('View all habits →'), findsOneWidget);
    });

    testWidgets('scheduled habits are previewed before unscheduled ones',
        (tester) async {
      await boot(
        tester,
        habits: [
          habit('late', hour: 21),
          habit('early', hour: 7),
          habit('anytime'),
        ],
      );
      await pumpHome(tester);

      final titles = tester
          .widgetList<Text>(find.textContaining('Habit '))
          .map((t) => t.data)
          .toList();
      expect(titles, ['Habit early', 'Habit late', 'Habit anytime']);
    });

    testWidgets('caps the preview and says how many were left out',
        (tester) async {
      await boot(
        tester,
        habits: [
          habit('a', hour: 6),
          habit('b', hour: 7),
          habit('c', hour: 8),
          habit('d', hour: 9),
        ],
      );
      await pumpHome(tester);

      expect(find.text('+ 1 more'), findsOneWidget);
    });

    testWidgets('tapping a habit toggles it through the Growth controller',
        (tester) async {
      await boot(tester, habits: [habit('a'), habit('b')]);
      await pumpHome(tester);

      expect(find.text('0/2 done'), findsOneWidget);

      await tester.tap(find.text('Habit a'));
      // The repository round-trip is delayed, so advance the fake clock.
      await tester.pump(_settleDelay);
      await tester.pump();

      expect(growth.habits.firstWhere((h) => h.title == 'Habit a').isCompletedToday,
          isTrue);
      expect(find.text('1/2 done'), findsOneWidget);
    });

    testWidgets('shows an empty state instead of invented habits',
        (tester) async {
      await boot(tester);
      await pumpHome(tester);

      expect(
        find.text('No habits yet. Add your first one in the Growth Center.'),
        findsOneWidget,
      );
    });

    testWidgets('the view-all button calls the shell callback', (tester) async {
      var tapped = false;
      await boot(tester, habits: [habit('a')]);
      await tester.pumpWidget(
        GetMaterialApp(
          home: HomeScreen(onViewAllHabits: () => tapped = true),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('View all habits →'));
      expect(tapped, isTrue);
    });
  });

  group('recent activity', () {
    testWidgets('renders real transactions with signed amounts', (tester) async {
      await boot(tester);
      await pumpHome(tester);

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
      expect(find.text('Morning coffee'), findsOneWidget);
      expect(find.text('+\$830.00'), findsOneWidget);
      expect(find.text('-\$4.50'), findsOneWidget);
      // A transaction with no note falls back to its real category name.
      expect(find.text('Bus pass'), findsOneWidget);
    });
  });

  group('community highlights', () {
    testWidgets('renders real post captions with the see-all shortcut',
        (tester) async {
      await boot(
        tester,
        posts: [
          post('p1', 'u-1', 'Ran my first 5k this morning'),
          post('p2', 'u-2', 'Started a study group for finals'),
        ],
      );
      await pumpHome(tester);

      expect(find.text('Community Highlights'), findsOneWidget);
      expect(find.text('Ran my first 5k this morning'), findsOneWidget);
      expect(find.text('Started a study group for finals'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
    });

    testWidgets('shows an empty state when the feed has no posts',
        (tester) async {
      await boot(tester);
      await pumpHome(tester);

      expect(
        find.text('No posts yet. Start the conversation in Community.'),
        findsOneWidget,
      );
    });

    testWidgets('the see-all button calls the shell callback', (tester) async {
      var tapped = false;
      await boot(tester, posts: [post('p1', 'u-1', 'A real caption')]);
      await tester.pumpWidget(
        GetMaterialApp(
          home: HomeScreen(onSeeAllCommunity: () => tapped = true),
        ),
      );
      await tester.pump();

      // The Community section sits below the fold on the default test surface.
      await tester.ensureVisible(find.text('See All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See All'));
      expect(tapped, isTrue);
    });
  });

  group('no placeholder data', () {
    testWidgets('none of the old hardcoded values are rendered',
        (tester) async {
      await boot(
        tester,
        habits: [habit('a', done: true), habit('b')],
        goals: [goal('g1')],
        posts: [post('p1', 'u-1', 'A real caption')],
      );
      await pumpHome(tester);

      expect(find.textContaining('1.2k'), findsNothing);
      expect(find.text('68%'), findsNothing);
      expect(find.text('Morning meditation'), findsNothing);
      expect(find.text('Drink 8 glasses of water'), findsNothing);
      expect(find.text('Read for 30 minutes'), findsNothing);
      expect(find.text('25 tasks'), findsNothing);
      expect(find.text('17 done'), findsNothing);
    });
  });
}
