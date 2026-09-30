import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:youthx/auth/controllers/auth_controller.dart';
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
import 'package:youthx/data/repositories/growth_repository.dart';
import 'package:youthx/modules/community/controllers/community_controller.dart';
import 'package:youthx/modules/growth_center/controllers/growth_controller.dart';
import 'package:youthx/modules/growth_center/models/goal_model.dart';
import 'package:youthx/modules/growth_center/models/habit_model.dart';
import 'package:youthx/modules/profile/controllers/profile_data_controller.dart';
import 'package:youthx/modules/profile/views/profile_screen.dart';

/// Widget coverage for the Profile tab.
///
/// Verifies that the header identity, the statistics, and the post tabs are
/// rendered from the registered controllers rather than placeholder values, and
/// that the empty states stay honest instead of showing invented posts.
class FakeAuthRepository extends AuthRepository {
  @override
  Future<AuthUserModel> fetchMe() async => _user;

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async =>
      LoginResponseModel(token: 'jwt', user: _user);

  @override
  Future<AuthUserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async =>
      _user;

  static final _user = AuthUserModel(
    id: 'u-me',
    email: 'alex@university.edu',
    fullName: 'Alex Johnson',
    createdAt: DateTime(2025, 3, 4),
  );
}

/// Mock repositories simulate latency with `Future.delayed`, and widget tests
/// run on a fake clock, so the timers have to be advanced once after
/// registration. Awaiting the loaders directly would never resolve.
const _settleDelay = Duration(seconds: 1);

/// In-memory stores so widget tests never touch the secure-storage or
/// SharedPreferences plugin channels.
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
  const me = 'u-me';

  late CommunityController community;
  late GrowthController growth;
  late ProfileDataController profile;

  PostModel post(String id, String authorId, {bool saved = false, bool shared = false}) =>
      PostModel(
        id: id,
        author: UserModel(id: authorId, name: 'Alex Johnson'),
        createdAt: DateTime(2026, 1, 1),
        caption: 'caption $id',
        savedByMe: saved,
        sharedByMe: shared,
      );

  Future<void> boot(
    WidgetTester tester, {
    List<PostModel> posts = const [],
    List<GoalModel> goals = const [],
    List<HabitModel> habits = const [],
    bool signedIn = true,
  }) async {
    if (signedIn) {
      final auth = AuthController(
        authRepository: FakeAuthRepository(),
        tokenStore: MemoryTokenStore(),
      );
      Get.put<AuthController>(auth, permanent: true);
      // The header reads the session identity, so a signed-in test has to
      // actually be signed in.
      auth.currentUser.value = FakeAuthRepository._user;
    }
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<ApiProvider>(ApiProvider(tokenStore: MemoryTokenStore()),
        permanent: true);

    community = CommunityController(repository: MockCommunityRepository());
    Get.put<CommunityController>(community, permanent: true);

    growth = GrowthController(repository: MockGrowthRepository());
    Get.put<GrowthController>(growth, permanent: true);

    profile = ProfileDataController(store: _MemoryProfileStore());
    Get.put<ProfileDataController>(profile, permanent: true);

    // `Get.put` runs `onInit`, which starts the controllers' own loads. Flush
    // the fake clock so the test data set below is what the screen reads.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_settleDelay);

    community
      ..posts.assignAll(posts)
      ..loading.value = false;
    growth
      ..goals.assignAll(goals)
      ..habits.assignAll(habits)
      ..loading.value = false;
  }

  GoalModel goal(String id) => GoalModel(
        id: id,
        emoji: 'G',
        title: 'Goal $id',
        category: GoalCategory.learning,
        targetDate: '2026-12-31',
        progress: 0.5,
      );

  HabitModel habit(String id, int streak) => HabitModel(
        id: id,
        emoji: 'H',
        title: 'Habit $id',
        frequency: HabitFrequency.daily,
        streak: streak,
        color: const Color(0xFF6366F1),
      );

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: ProfileScreen()));
    await tester.pump();
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('shows the real name, email and member date', (tester) async {
    await boot(tester);
    await pumpProfile(tester);

    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('alex@university.edu'), findsOneWidget);
    expect(
      find.textContaining('Member since ${DateFormat.yMMM().format(DateTime(2025, 3, 4))}'),
      findsOneWidget,
    );
  });

  testWidgets('shows real post, goal and streak counts', (tester) async {
    await boot(
      tester,
      posts: [post('p1', me), post('p2', me), post('p3', 'someone-else')],
      goals: [goal('g1'), goal('g2')],
      habits: [habit('h1', 3), habit('h2', 9)],
    );
    await pumpProfile(tester);

    // Only the two posts authored by the signed-in user are counted.
    expect(find.text('2'), findsWidgets);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('lists only the signed-in user posts in My posts',
      (tester) async {
    await boot(tester, posts: [post('p1', me), post('p9', 'someone-else')]);
    await pumpProfile(tester);

    expect(find.text('caption p1'), findsOneWidget);
    expect(find.text('caption p9'), findsNothing);
  });

  testWidgets('shows an honest empty state with no posts', (tester) async {
    await boot(tester);
    await pumpProfile(tester);

    expect(find.text('No posts yet'), findsOneWidget);
    expect(find.textContaining('show up here'), findsOneWidget);
  });

  testWidgets('saved tab explains the session-only behaviour',
      (tester) async {
    await boot(tester, posts: [post('p1', me)]);
    await pumpProfile(tester);

    await tester.tap(find.text('Saved'));
    await tester.pump();

    expect(find.text('No saved posts'), findsOneWidget);
    expect(find.textContaining('this session only'), findsOneWidget);
  });

  testWidgets('shared tab explains the session-only behaviour',
      (tester) async {
    await boot(tester, posts: [post('p1', me)]);
    await pumpProfile(tester);

    await tester.tap(find.text('Shared'));
    await tester.pump();

    expect(find.text('No shared posts'), findsOneWidget);
    expect(find.textContaining('this session only'), findsOneWidget);
  });

  testWidgets('shows a saved post once it is flagged', (tester) async {
    await boot(tester, posts: [post('p1', me, saved: true)]);
    await pumpProfile(tester);

    await tester.tap(find.text('Saved'));
    await tester.pump();

    expect(find.text('caption p1'), findsOneWidget);
    expect(find.text('No saved posts'), findsNothing);
  });

  testWidgets('no placeholder follower or following counts remain',
      (tester) async {
    await boot(tester);
    await pumpProfile(tester);

    expect(find.text('Followers'), findsNothing);
    expect(find.text('Following'), findsNothing);
    expect(find.text('128'), findsNothing);
    expect(find.text('36'), findsNothing);
  });
}
