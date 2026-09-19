import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/community_repository.dart';

class CommentsController extends GetxController {
  final CommunityRepository repository;
  final String postId;

  CommentsController({required this.repository, required this.postId});

  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxBool loading = true.obs;
  final RxBool sending = false.obs;

  /// Friendly message shown instead of the list when loading failed.
  final RxnString error = RxnString();

  /// Set while the composer is targeting a reply to a specific comment
  /// rather than a new top-level comment. Null = commenting on the post.
  final Rx<CommentModel?> replyingTo = Rx<CommentModel?>(null);
  final TextEditingController inputController = TextEditingController();
  StreamSubscription<CommentModel>? _sub;

  String get currentUserId {
    if (!Get.isRegistered<AuthController>()) return '';
    return Get.find<AuthController>().currentUser.value?.id ?? '';
  }

  /// Top-level comments only, oldest first.
  List<CommentModel> get topLevelComments {
    final list = comments.where((c) => !c.isReply).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Replies to a given top-level comment, oldest first.
  List<CommentModel> repliesTo(String commentId) {
    final list = comments.where((c) => c.parentId == commentId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    load();
    // Subscribe so new comments (from this device or, on a realtime
    // backend, any other device) stream straight into the list.
    _sub = repository.watchComments(postId).listen((comment) {
      if (comments.any((c) => c.id == comment.id)) return;
      comments.add(comment);
    });
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final initial = await repository.fetchComments(postId);
      comments.assignAll(initial);
    } catch (e) {
      error.value = _message(e);
    } finally {
      loading.value = false;
    }
  }

  void startReply(CommentModel comment) => replyingTo.value = comment;

  void cancelReply() => replyingTo.value = null;

  Future<void> send() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    sending.value = true;
    inputController.clear();
    try {
      final created = await repository.addComment(
        postId,
        text,
        parentId: replyingTo.value?.id,
      );
      if (created != null && !comments.any((c) => c.id == created.id)) {
        comments.add(created);
      }
    } catch (e) {
      // Restore the text so the user can retry without retyping.
      inputController.text = text;
      _showError(e, 'Could not add your comment.');
    } finally {
      sending.value = false;
      replyingTo.value = null;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await repository.deleteComment(postId, commentId);
      comments.removeWhere((c) => c.id == commentId);
    } catch (e) {
      _showError(e, 'Could not delete this comment.');
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    inputController.dispose();
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