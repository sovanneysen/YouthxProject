import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/core/network/api_client.dart';
import 'package:youthx/data/models/post_model.dart';
import 'package:youthx/data/models/user_model.dart';
import 'package:youthx/data/repositories/community_repository.dart';
import 'package:youthx/modules/community/controllers/comments_controller.dart';

class _FlakyCommentsRepo extends MockCommunityRepository {
  bool failLoad = false;
  bool failSend = false;
  ApiException? deleteError;

  @override
  Future<List<CommentModel>> fetchComments(String postId) async {
    if (failLoad) throw const ApiException(500, 'comments unavailable');
    return super.fetchComments(postId);
  }

  @override
  Future<CommentModel?> addComment(
    String postId,
    String text, {
    String? parentId,
  }) async {
    if (failSend) throw const ApiException(400, 'comment rejected');
    return super.addComment(postId, text, parentId: parentId);
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final error = deleteError;
    if (error != null) throw error;
    return super.deleteComment(postId, commentId);
  }
}

void main() {
  setUp(Get.reset);

  // The mock repository only lets comments target posts it already owns;
  // addComment looks up the post (like the real comments route does).
  Future<String> seedPost(_FlakyCommentsRepo repo) async {
    final post = await repo.createPost(PostModel(
      id: 'p1',
      author: UserModel(id: 'u1', name: 'Author'),
      createdAt: DateTime.now(),
      caption: 'a post',
    ));
    return post.id;
  }

  CommentsController controllerFor(_FlakyCommentsRepo repo, String postId) =>
      CommentsController(repository: repo, postId: postId);

  group('CommentsController load', () {
    test('loads existing comments from the repository', () async {
      final repo = _FlakyCommentsRepo();
      final postId = await seedPost(repo);
      await repo.addComment(postId, 'first comment');
      final controller = controllerFor(repo, postId);

      await controller.load();

      expect(controller.loading.value, isFalse);
      expect(controller.comments, hasLength(1));
      expect(controller.comments.first.text, 'first comment');
    });

    test('exposes a friendly error when loading fails', () async {
      final repo = _FlakyCommentsRepo()..failLoad = true;
      final postId = await seedPost(repo);
      final controller = controllerFor(repo, postId);

      await controller.load();

      expect(controller.loading.value, isFalse);
      expect(controller.error.value, 'comments unavailable');
      expect(controller.comments, isEmpty);
    });
  });

  group('CommentsController send', () {
    test('inserts the comment returned by the backend', () async {
      final repo = _FlakyCommentsRepo();
      final postId = await seedPost(repo);
      final controller = controllerFor(repo, postId);
      controller.inputController.text = 'new comment';

      await controller.send();

      expect(controller.sending.value, isFalse);
      expect(controller.comments, hasLength(1));
      expect(controller.comments.first.text, 'new comment');
      expect(controller.inputController.text, isEmpty);
    });

    test('restores the typed text when the backend rejects the comment',
        () async {
      final repo = _FlakyCommentsRepo()..failSend = true;
      final postId = await seedPost(repo);
      final controller = controllerFor(repo, postId);
      controller.inputController.text = 'keep me';

      await controller.send();

      expect(controller.sending.value, isFalse);
      expect(controller.inputController.text, 'keep me');
      expect(controller.comments, isEmpty);
    });
  });

  group('CommentsController delete', () {
    test('removes the comment after a successful delete', () async {
      final repo = _FlakyCommentsRepo();
      final postId = await seedPost(repo);
      await repo.addComment(postId, 'to delete');
      final controller = controllerFor(repo, postId);
      await controller.load();
      final comment = controller.comments.first;

      await controller.deleteComment(comment.id);

      expect(controller.comments, isEmpty);
    });

    test('keeps the comment when delete is not permitted', () async {
      final repo = _FlakyCommentsRepo()
        ..deleteError = const ApiException(403, 'not yours');
      final postId = await seedPost(repo);
      await repo.addComment(postId, 'sticky');
      final controller = controllerFor(repo, postId);
      await controller.load();
      final comment = controller.comments.first;

      await controller.deleteComment(comment.id);

      expect(controller.comments, hasLength(1));
    });

    test('exposes the authenticated user id only when a session exists', () {
      final controller = CommentsController(
        repository: _FlakyCommentsRepo(),
        postId: 'p1',
      );
      expect(controller.currentUserId, '');
    });
  });
}