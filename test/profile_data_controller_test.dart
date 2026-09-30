import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:youthx/auth/controllers/auth_controller.dart';
import 'package:youthx/core/network/token_store.dart';
import 'package:youthx/core/storage/local_profile_store.dart';
import 'package:youthx/data/models/auth_user_model.dart';
import 'package:youthx/data/models/post_model.dart';
import 'package:youthx/data/models/user_model.dart';
import 'package:youthx/data/repositories/auth_repository.dart';
import 'package:youthx/data/repositories/community_repository.dart';
import 'package:youthx/data/repositories/growth_repository.dart';
import 'package:youthx/modules/community/controllers/community_controller.dart';
import 'package:youthx/modules/growth_center/controllers/growth_controller.dart';
import 'package:youthx/modules/growth_center/models/goal_model.dart';
import 'package:youthx/modules/growth_center/models/habit_model.dart';
import 'package:youthx/modules/profile/controllers/profile_data_controller.dart';
import 'package:youthx/data/models/local_profile_model.dart';

/// Stores nothing and hands back a fixed profile, so persistence itself can
/// be asserted separately from the controller's in-memory behaviour.
class SpyLocalProfileStore implements LocalProfileStore {
  final Map<String, LocalProfile> entries = <String, LocalProfile>{};
  final List<String> cleared = <String>[];

  @override
  Future<LocalProfile?> read(String userId) async =>
      userId.isEmpty ? null : entries[userId];

  @override
  Future<void> write(String userId, LocalProfile profile) async {
    if (userId.isEmpty) return;
    entries[userId] = profile;
  }

  @override
  Future<void> clear(String userId) async {
    cleared.add(userId);
    entries.remove(userId);
  }
}

/// Offline auth stub: these tests set `currentUser` directly, so no HTTP is
/// ever needed.
class FakeAuthRepository extends AuthRepository {
  @override
  Future<AuthUserModel> fetchMe() async => userWith('u-me');

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async =>
      LoginResponseModel(token: 'jwt', user: userWith('u-me'));

  @override
  Future<AuthUserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async =>
      userWith('u-me');
}

AuthUserModel userWith(String id, {String? createdAt}) => AuthUserModel(
      id: id,
      email: '$id@university.edu',
      fullName: 'Alex Johnson',
      createdAt: createdAt == null ? null : DateTime.parse(createdAt),
    );

PostModel postBy(String id, String authorId, {DateTime? at, bool saved = false, bool shared = false}) =>
    PostModel(
      id: id,
      author: UserModel(id: authorId, name: 'Alex Johnson'),
      createdAt: at ?? DateTime(2026, 1, 1),
      caption: 'caption $id',
      savedByMe: saved,
      sharedByMe: shared,
    );

void main() {
  late SpyLocalProfileStore store;
  late AuthController auth;
  late CommunityController community;
  late GrowthController growth;
  late ProfileDataController profile;

  const me = 'u-me';
  const other = 'u-other';

  void registerAuth(String userId, {String? createdAt}) {
    auth = AuthController(
      authRepository: FakeAuthRepository(),
      tokenStore: MemoryTokenStore(),
    );
    Get.put<AuthController>(auth, permanent: true);
    auth.currentUser.value = userWith(userId, createdAt: createdAt);
  }

  void registerCommunity(List<PostModel> posts) {
    community = CommunityController(repository: MockCommunityRepository());
    Get.put<CommunityController>(community, permanent: true);
    community.posts.assignAll(posts);
    community.loading.value = false;
  }

  void registerGrowth({List<GoalModel>? goals, List<HabitModel>? habits}) {
    growth = GrowthController(repository: MockGrowthRepository());
    Get.put<GrowthController>(growth, permanent: true);
    growth
      ..goals.assignAll(goals ?? const <GoalModel>[])
      ..habits.assignAll(habits ?? const <HabitModel>[])
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

  setUp(() {
    Get.reset();
    store = SpyLocalProfileStore();
  });

  tearDown(Get.reset);

  ProfileDataController buildProfile() {
    profile = ProfileDataController(store: store);
    Get.put<ProfileDataController>(profile, permanent: true);
    return profile;
  }

  group('real identity', () {
    test('name, email, and member date come from the session', () {
      registerAuth(me, createdAt: '2025-03-04');
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();

      expect(p.displayName, 'Alex Johnson');
      expect(p.email, '$me@university.edu');
      expect(p.memberSince, DateTime(2025, 3, 4));
      expect(p.initials, 'AJ');
    });

    test('initials fall back for a single-word name', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile()..displayName;

      expect(p.initials, 'AJ');
      expect(p.userId, me);
    });

    test('no invented values when there is no session', () {
      final p = buildProfile();

      expect(p.userId, '');
      expect(p.displayName, '');
      expect(p.email, '');
      expect(p.memberSince, isNull);
      expect(p.initials, '');
    });

    test('missing createdAt stays null rather than a fake date', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();

      expect(buildProfile().memberSince, isNull);
    });
  });

  group('my posts', () {
    test('are filtered to the signed-in author', () {
      registerAuth(me);
      registerCommunity([
        postBy('p1', me),
        postBy('p2', other),
        postBy('p3', me),
      ]);
      registerGrowth();

      final p = buildProfile();
      expect(p.myPosts.map((e) => e.id), ['p1', 'p3']);
      expect(p.postCount, 2);
    });

    test('are sorted newest first', () {
      registerAuth(me);
      registerCommunity([
        postBy('old', me, at: DateTime(2026, 1, 1)),
        postBy('new', me, at: DateTime(2026, 6, 1)),
      ]);
      registerGrowth();

      expect(buildProfile().myPosts.map((e) => e.id), ['new', 'old']);
    });

    test('update when the community list changes', () {
      registerAuth(me);
      registerCommunity([postBy('p1', me)]);
      registerGrowth();
      final p = buildProfile();
      expect(p.postCount, 1);

      community.posts.add(postBy('p2', me));

      expect(p.postCount, 2);
    });

    test('are empty when another user is signed in', () {
      registerAuth(other);
      registerCommunity([postBy('p1', me)]);
      registerGrowth();

      expect(buildProfile().myPosts, isEmpty);
    });
  });

  group('saved and shared', () {
    test('reflect only the session-local flags', () {
      registerAuth(me);
      registerCommunity([
        postBy('p1', me, saved: true),
        postBy('p2', me, shared: true),
        postBy('p3', other, saved: true),
      ]);
      registerGrowth();
      final p = buildProfile();

      expect(p.savedPosts.map((e) => e.id), ['p1', 'p3']);
      expect(p.sharedPosts.map((e) => e.id), ['p2']);
    });

    test('are empty rather than populated when nothing is flagged', () {
      registerAuth(me);
      registerCommunity([postBy('p1', me)]);
      registerGrowth();
      final p = buildProfile();

      expect(p.savedPosts, isEmpty);
      expect(p.sharedPosts, isEmpty);
    });
  });

  group('goals and streak', () {
    test('count real goals', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth(goals: [goal('g1'), goal('g2'), goal('g3')]);
      final p = buildProfile();

      expect(p.goalCount, 3);
      expect(p.growthLoading, isFalse);
    });

    test('streak is the longest real habit streak', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth(habits: [habit('h1', 4), habit('h2', 11), habit('h3', 2)]);

      expect(buildProfile().streakDays, 11);
    });

    test('report zero when no growth data is loaded', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();

      final p = buildProfile();
      expect(p.goalCount, 0);
      expect(p.streakDays, 0);
    });

    test('flag loading while the request is in flight', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      buildProfile();

      growth.loading.value = true;

      expect(profile.growthLoading, isTrue);
    });
  });

  group('local profile persistence', () {
    test('saves fields for the signed-in user id', () async {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();

      await p.saveLocalProfile(
        displayName: 'Alex J',
        bio: 'CS student',
        location: 'London',
      );

      expect(store.entries[me]?.bio, 'CS student');
      expect(store.entries[me]?.location, 'London');
      expect(p.bio, 'CS student');
      expect(p.location, 'London');
      expect(p.hasLocalName, isTrue);
    });

    test('a local name overrides the session name', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();

      p.localProfile.value = const LocalProfile(displayName: 'Local Name');

      expect(p.displayName, 'Local Name');
    });

    test('blank name restores the real session name', () {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();

      p.localProfile.value = const LocalProfile(displayName: 'Local Name');
      p.localProfile.value = const LocalProfile(displayName: '   ');

      expect(p.displayName, 'Alex Johnson');
      expect(p.hasLocalName, isFalse);
    });

    test('whitespace-only input is normalised away', () async {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();

      await p.saveLocalProfile(bio: '   ', location: '  ');

      expect(p.bio, '');
      expect(p.location, '');
      expect(store.cleared, contains(me));
    });

    test('one account never sees another account values', () async {
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();
      await p.saveLocalProfile(bio: 'Mine', location: 'Here');

      await p.loadLocalProfile();
      expect(p.bio, 'Mine');

      // Switching sessions must not surface the previous account's fields.
      auth.currentUser.value = userWith(other);
      await Future<void>.delayed(Duration.zero);

      expect(p.bio, '');
      expect(p.location, '');
      expect(store.entries.containsKey(other), isFalse);
      expect(store.entries[me]?.bio, 'Mine');
    });

    test('writes are skipped when signed out', () async {
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();

      await p.saveLocalProfile(bio: 'Nowhere');

      expect(store.entries, isEmpty);
      expect(p.bio, 'Nowhere');
    });

    test('reloads a stored profile on init', () async {
      store.entries[me] =
          const LocalProfile(bio: 'Stored bio', location: 'Stored place');
      registerAuth(me);
      registerCommunity(const []);
      registerGrowth();
      final p = buildProfile();
      await p.loadLocalProfile();

      expect(p.bio, 'Stored bio');
      expect(p.location, 'Stored place');
    });
  });
}
