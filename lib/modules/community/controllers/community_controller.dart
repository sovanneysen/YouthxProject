import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/app_config.dart';
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
  String get currentUserId => AppConfig.currentUserId;

  @override
  void onInit() {
    super.onInit();
    loadFeed();
    loadStories();
  }

  // ── Feed loading ─────────────────────────────────────────────
  Future<void> loadFeed() async {
    loading.value = true;
    try {
      final data = await repository.fetchFeed();
      posts.assignAll(data);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadStories() async {
    final data = await repository.fetchStories();
    stories.assignAll(data);
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
  Future<void> toggleLike(PostModel post) async {
    await repository.toggleLike(post.id);
    // repository mutates the post object's fields in place;
    // .refresh() forces Obx listeners to rebuild since the
    // object reference itself didn't change.
    posts.refresh();
  }

  Future<void> deletePost(PostModel post) async {
    await repository.deletePost(post.id);
    posts.removeWhere((p) => p.id == post.id);
  }

  Future<void> toggleSave(PostModel post) async {
    await repository.toggleSave(post.id);
    posts.refresh();
  }

  Future<void> toggleShare(PostModel post) async {
    await repository.toggleShare(post.id);
    posts.refresh();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
