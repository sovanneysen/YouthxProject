import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/auth/controllers/auth_controller.dart';
import 'package:youthx/core/network/token_store.dart';
import 'package:youthx/data/models/auth_user_model.dart';
import 'package:youthx/data/models/post_model.dart';
import 'package:youthx/data/providers/api_provider.dart';
import 'package:youthx/data/repositories/auth_repository.dart';
import 'package:youthx/data/repositories/community_repository.dart';
import 'package:youthx/modules/community/controllers/community_controller.dart';

/// In-memory repository whose failure knobs can be flipped per test.
class _FlakyCommunityRepo extends MockCommunityRepository {
  ApiException? feedError;
  Exception? likeError;
  Exception? deleteError;
  int likeCalls = 0;

  @override
  Future<List<PostModel>> fetchFeed() async {
    final error = feedError;
    if (error != null) throw error;
    return super.fetchFeed();
  }

  @override
  Future<void> toggleLike(String postId) async {
    likeCalls += 1;
    final error = likeError;
    if (error != null) throw error;
    // Mirrors the real backend toggle: server-side state changes, but the
    // local PostModel instance is never mutated by the repository.
  }

  @override
  Future<void> deletePost(String postId) async {
    final error = deleteError;
    if (error != null) throw error;
    return super.deletePost(postId);
  }
}

class _SilentApiProvider extends ApiProvider {
  _SilentApiProvider() : super(tokenStore: MemoryTokenStore());

  @override
  Future<dynamic> get(String path) async => <String, dynamic>{};

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> delete(String path) async => null;
}

void main() {
  setUp(Get.reset);

  group('CommunityController feed', () {
    test('loads posts and clears any previous error', () async {
      final controller = CommunityController(repository: _FlakyCommunityRepo());
      controller.feedError.value = 'stale';

      await controller.loadFeed();

      expect(controller.posts, isNotEmpty);
      expect(controller.loading.value, isFalse);
      expect(controller.feedError.value, isNull);
    });

    test('exposes a friendly error when the feed fails', () async {
      final repo = _FlakyCommunityRepo()
        ..feedError = const ApiException(500, 'backend exploded');
      final controller = CommunityController(repository: repo);

      await controller.loadFeed();

      expect(controller.posts, isEmpty);
      expect(controller.loading.value, isFalse);
      expect(controller.feedError.value, 'backend exploded');
    });
  });

  group('CommunityController like', () {
    test('toggles optimistically and confirms through the backend', () async {
      final controller = CommunityController(repository: _FlakyCommunityRepo());
      await controller.loadFeed();
      final post = controller.posts.first;
      final before = post.likeCount;

      await controller.toggleLike(post);

      expect(post.likedByMe, isTrue);
      expect(post.likeCount, before + 1);
    });

    test('rolls back to the previous state when the backend fails', () async {
      final repo = _FlakyCommunityRepo();
      final controller = CommunityController(repository: repo);
      await controller.loadFeed();
      final post = controller.posts.first;
      final before = post.likeCount;
      repo.likeError = const ApiException(500, 'nope');

      await controller.toggleLike(post);

      expect(post.likedByMe, isFalse);
      expect(post.likeCount, before);
    });

    test('ignores duplicate taps while a like is in flight', () async {
      final repo = _FlakyCommunityRepo();
      final controller = CommunityController(repository: repo);
      await controller.loadFeed();
      final post = controller.posts.first;

      await Future.wait([
        controller.toggleLike(post),
        controller.toggleLike(post),
      ]);

      expect(repo.likeCalls, 1);
    });
  });

  group('CommunityController delete', () {
    test('removes the post from the feed after a successful delete', () async {
      final controller = CommunityController(repository: _FlakyCommunityRepo());
      await controller.loadFeed();
      final post = controller.posts.first;

      await controller.deletePost(post);

      expect(controller.posts.any((p) => p.id == post.id), isFalse);
    });

    test('keeps the post when delete is not permitted', () async {
      final repo = _FlakyCommunityRepo()
        ..deleteError = const ApiException(403, 'not yours');
      final controller = CommunityController(repository: repo);
      await controller.loadFeed();
      final post = controller.posts.first;

      await controller.deletePost(post);

      expect(controller.posts.any((p) => p.id == post.id), isTrue);
    });
  });

  group('CommunityController current user', () {
    test('comes from the authenticated session when one exists', () {
      Get.put<AuthController>(
        AuthController(
          authRepository: AuthRepository(apiProvider: _SilentApiProvider()),
          tokenStore: MemoryTokenStore(),
        )..currentUser.value = const AuthUserModel(
            id: 'user-1',
            email: 'user@youthx.dev',
            fullName: 'Draft User',
          ),
      );

      final controller = CommunityController(repository: _FlakyCommunityRepo());
      expect(controller.currentUserId, 'user-1');
    });

    test('falls back to an empty id without a session', () {
      final controller = CommunityController(repository: _FlakyCommunityRepo());
      expect(controller.currentUserId, '');
    });
  });
}