import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/socket_service.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/community_repository.dart';

class CommentsController extends GetxController {
  final CommunityRepository repository;
  final String postId;

  CommentsController({required this.repository, required this.postId});

  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxBool loading = true.obs;
  final RxBool sending = false.obs;

  /// Set while the composer is targeting a reply to a specific comment
  /// rather than a new top-level comment. Null = commenting on the post.
  final Rx<CommentModel?> replyingTo = Rx<CommentModel?>(null);
  final TextEditingController inputController = TextEditingController();
  StreamSubscription<CommentModel>? _sub;

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
    RealtimeSocketService.instance.connect();
    _load();
    // Subscribe so new comments (from this device or, on a real backend,
    // any other device) stream straight into the list - no manual refresh.
    _sub = repository.watchComments(postId).listen((comment) {
      if (comments.any((c) => c.id == comment.id)) return;
      comments.add(comment);
    });
  }

  Future<void> _load() async {
    loading.value = true;
    final initial = await repository.fetchComments(postId);
    comments.assignAll(initial);
    loading.value = false;
  }

  void startReply(CommentModel comment) => replyingTo.value = comment;

  void cancelReply() => replyingTo.value = null;

  Future<void> send() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    sending.value = true;
    inputController.clear();
    try {
      await repository.addComment(postId, text, parentId: replyingTo.value?.id);
    } finally {
      sending.value = false;
      replyingTo.value = null;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    inputController.dispose();
    super.onClose();
  }
}
