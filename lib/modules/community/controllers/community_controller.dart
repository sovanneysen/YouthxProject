import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';

class CommunityController extends GetxController {
  final CommunityRepository repository;
  CommunityController({required this.repository});

  // ── Feed state ──────────────────────────────────────────────
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxBool loading = false.obs;

  /// Friendly message shown instead of the feed when the last load failed.
  final RxnString feedError = RxnString();

  // ── Stories ──────────────────────────────────────────────────
  final RxList<StoryModel> stories = <StoryModel>[].obs;

  // ── Search & filter ─────────────────────────────────────────
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString activeFilter = 'All'.obs;
  final List<String> filters = const ['All', 'Goals', 'Finance', 'Community', 'Reading'];

  // ── People search results ──────────────────────────────────
  final RxList<UserModel> peopleResults = <UserModel>[].obs;

  /// True while the search box has text — the feed swaps to people results.
  bool get isSearching => searchQuery.value.trim().isNotEmpty;

  // ── Current user ─────────────────────────────────────────────

  /// The id of the account currently in the authenticated session. Empty
  /// when no session exists (e.g. during tests or after logout).
  String get currentUserId {
    if (!Get.isRegistered<AuthController>()) return '';
    return Get.find<AuthController>().currentUser.value?.id ?? '';
  }

  // Guards against parallel like requests for the same post.
  final Set<String> _likeInFlight = <String>{};

  @override
  void onInit() {
    super.onInit();
    loadFeed();
    loadStories();
  }

  // ── Feed loading ─────────────────────────────────────────────
  Future<void> loadFeed() async {
    loading.value = true;
    feedError.value = null;
    try {
      final data = await repository.fetchFeed();
      posts.assignAll(data);
    } catch (e) {
      posts.clear();
      feedError.value = _message(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadStories() async {
    try {
      final data = await repository.fetchStories();
      stories.assignAll(data);
    } catch (_) {
      stories.clear();
    }
  }

  // ── Derived / filtered list used by the view ────────────────
  List<PostModel> get filteredPosts {
    var result = posts.toList();

    if (activeFilter.value != 'All') {
      result = result.where((p) => p.tags.contains(activeFilter.value)).toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((p) {
        return p.caption.toLowerCase().contains(query) ||
            p.author.name.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  void setSearch(String value) {
    searchController.text = value;
    searchQuery.value = value;
    searchPeople(value.trim());
  }

  /// Clears the search box and hides people results (used after a profile
  /// is opened from a search result).
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    peopleResults.clear();
  }

  Future<void> searchPeople(String query) async {
    if (query.isEmpty) {
      peopleResults.clear();
      return;
    }
    peopleResults.assignAll(await repository.searchUsers(query));
  }

  void setFilter(String value) => activeFilter.value = value;

  // ── Post actions ─────────────────────────────────────────────

  /// Optimistic like/unlike with safe rollback: the UI flips immediately,
  /// the backend toggle is applied afterwards, and on failure the previous
  /// state is restored. Duplicate taps during an active request are ignored.
  Future<void> toggleLike(PostModel post) async {
    if (_likeInFlight.contains(post.id)) return;
    _likeInFlight.add(post.id);

    final wasLiked = post.likedByMe;
    final wasCount = post.likeCount;
    final nextCount = wasCount + (wasLiked ? -1 : 1);
    post
      ..likedByMe = !wasLiked
      ..likeCount = nextCount < 0 ? 0 : nextCount;
    posts.refresh();

    try {
      await repository.toggleLike(post.id);
    } catch (e) {
      post
        ..likedByMe = wasLiked
        ..likeCount = wasCount;
      posts.refresh();
      _showError(e, 'Could not update the like.');
    } finally {
      _likeInFlight.remove(post.id);
    }
  }

  Future<void> deletePost(PostModel post) async {
    try {
      await repository.deletePost(post.id);
      posts.removeWhere((p) => p.id == post.id);
    } catch (e) {
      _showError(e, 'Could not delete this post.');
    }
  }

  Future<void> toggleSave(PostModel post) async {
    final previous = post.savedByMe;
    post.savedByMe = !previous;
    posts.refresh();
    try {
      await repository.toggleSave(post.id);
    } catch (e) {
      post.savedByMe = previous;
      posts.refresh();
      _showError(e, 'Could not save this post.');
    }
  }

  Future<void> toggleShare(PostModel post) async {
    final previous = post.sharedByMe;
    post.sharedByMe = !previous;
    posts.refresh();
    try {
      await repository.toggleShare(post.id);
    } catch (e) {
      post.sharedByMe = previous;
      posts.refresh();
      _showError(e, 'Could not share this post.');
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  void _showError(Object error, String fallback) {
    if (!_canShowSnackbar()) return;
    Get.snackbar(
      'Something went wrong',
      error is ApiException ? error.message : fallback,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }

  // Get.context throws while no widget binding exists (pure unit tests).
  // Runtime callers always have a bound context, so the snackbar still
  // appears in the app; it is skipped only in isolated logic tests.
  bool _canShowSnackbar() {
    try {
      return Get.context != null;
    } catch (_) {
      return false;
    }
  }
}