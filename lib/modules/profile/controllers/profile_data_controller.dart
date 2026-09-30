import 'package:get/get.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../core/storage/local_profile_store.dart';
import '../../../data/models/auth_user_model.dart';
import '../../../data/models/local_profile_model.dart';
import '../../../data/models/post_model.dart';
import '../../community/controllers/community_controller.dart';
import '../../growth_center/controllers/growth_controller.dart';
import '../../growth_center/models/habit_model.dart';

/// Profile data hub used by the Profile tab and the `/profile` route.
///
/// It owns the device-local profile fields and derives the header statistics
/// from the controllers that already hold the real data, so no Profile widget
/// calls a repository or an API directly and no data source is duplicated.
///
/// Every statistic is read from currently loaded state. Nothing here invents a
/// value: an unloaded or empty list is reported as `0`.
class ProfileDataController extends GetxController {
  ProfileDataController({required this.store});

  final LocalProfileStore store;

  /// Device-local fields for the signed-in account.
  final Rx<LocalProfile> localProfile = LocalProfile.empty.obs;
  final RxBool loadingLocalProfile = false.obs;

  /// Incremented on every load and save so a read that resolves late cannot
  /// overwrite a value that was written in the meantime.
  int _revision = 0;

  /// Re-reads the local fields whenever the session changes, so one account's
  /// values can never surface under another account.
  Worker? _sessionWorker;

  AuthController? get _auth =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  CommunityController? get _community => Get.isRegistered<CommunityController>()
      ? Get.find<CommunityController>()
      : null;

  GrowthController? get _growth =>
      Get.isRegistered<GrowthController>() ? Get.find<GrowthController>() : null;

  /// Authenticated account id, or '' when signed out.
  String get userId => _auth?.currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    loadLocalProfile();
    final auth = _auth;
    if (auth == null) return;
    _sessionWorker = ever<AuthUserModel?>(
      auth.currentUser,
      (_) => loadLocalProfile(),
    );
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    super.onClose();
  }

  // ---------------- device-local fields ----------------

  /// Loads the stored fields for the signed-in account, ignoring the
  /// result when the session changes while the read is in flight.
  Future<void> loadLocalProfile() async {
    final id = userId;
    final revision = ++_revision;
    if (id.isEmpty) {
      localProfile.value = LocalProfile.empty;
      return;
    }
    loadingLocalProfile.value = true;
    try {
      final stored = await store.read(id);
      // Discard the result when the session changed or a newer write landed
      // while this read was in flight.
      if (revision != _revision || userId != id) return;
      localProfile.value = stored ?? LocalProfile.empty;
    } finally {
      if (revision == _revision) loadingLocalProfile.value = false;
    }
  }

  /// Persists the edited fields for the signed-in account.
  ///
  /// The value is applied to [localProfile] first so the header updates without
  /// waiting on storage. Whitespace-only input is normalised away, and a fully
  /// blank profile clears the stored record instead of keeping an empty one.
  Future<void> saveLocalProfile({
    String? displayName,
    String bio = '',
    String location = '',
  }) async {
    final profile =
        LocalProfile(displayName: displayName, bio: bio, location: location)
            .normalized();
    // Invalidate any read still in flight so it cannot clobber this write.
    _revision++;
    localProfile.value = profile;

    final id = userId;
    if (id.isEmpty) return;
    if (profile.isEmpty) {
      await store.clear(id);
      return;
    }
    await store.write(id, profile);
  }

  // ---------------- real session identity ----------------

  /// The real account name, with the local override applied when one is set.
  String get displayName {
    final realName = _auth?.currentUser.value?.fullName ?? '';
    return localProfile.value.resolveName(realName);
  }

  /// True when a local display name is shadowing the account name.
  bool get hasLocalName => localProfile.value.localName != null;

  /// Email from the session, or '' when signed out or absent.
  String get email => _auth?.currentUser.value?.email ?? '';

  /// Registration date from the session; null when the API omitted it.
  DateTime? get memberSince => _auth?.currentUser.value?.createdAt;

  String get bio => localProfile.value.trimmedBio;
  String get location => localProfile.value.trimmedLocation;

  /// Avatar initials derived from the real name. Returns '' when no name is
  /// available so the view can render its own neutral placeholder.
  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '';
    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  // ---------------- real statistics ----------------

  /// Real posts written by the signed-in account, newest first.
  List<PostModel> get myPosts {
    final id = userId;
    if (id.isEmpty) return const <PostModel>[];
    return _newestFirst(
      (_community?.posts ?? const <PostModel>[]).where((p) => p.author.id == id),
    );
  }

  /// Posts toggled as saved during this app session.
  ///
  /// The backend has no save persistence: `savedByMe` only reflects saves made
  /// while the app is running, so this list is intentionally session-scoped
  /// and the view says so.
  List<PostModel> get savedPosts => _newestFirst(
        (_community?.posts ?? const <PostModel>[]).where((p) => p.savedByMe),
      );

  /// Posts toggled as shared during this app session. Session-scoped for the
  /// same reason as [savedPosts].
  List<PostModel> get sharedPosts => _newestFirst(
        (_community?.posts ?? const <PostModel>[]).where((p) => p.sharedByMe),
      );

  /// Number of the account's real posts.
  int get postCount => myPosts.length;

  /// Number of real goals loaded by the Growth controller.
  int get goalCount => _growth?.goals.length ?? 0;

  /// Longest streak across the account's real habits, 0 when there are none.
  int get streakDays {
    final habits = _growth?.habits ?? const <HabitModel>[];
    var best = 0;
    for (final habit in habits) {
      if (habit.streak > best) best = habit.streak;
    }
    return best;
  }

  /// True while the community feed has not completed its first load.
  bool get communityLoading => _community?.loading.value ?? false;

  /// True while the growth lists have not completed their first load.
  bool get growthLoading => _growth?.loading.value ?? false;

  List<PostModel> _newestFirst(Iterable<PostModel> posts) {
    final list = posts.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
