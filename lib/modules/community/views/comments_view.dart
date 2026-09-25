import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../controllers/comments_controller.dart';
import 'widgets/comment_tile.dart';

class CommentsView extends StatefulWidget {
  final PostModel post;
  const CommentsView({super.key, required this.post});

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  late final String tag;
  late final CommentsController c;

  @override
  void initState() {
    super.initState();
    tag = 'comments_${widget.post.id}';
    c = Get.put(
      CommentsController(repository: Get.find<CommunityRepository>(), postId: widget.post.id),
      tag: tag,
    );
  }

  @override
  void dispose() {
    Get.delete<CommentsController>(tag: tag);
    super.dispose();
  }

  UserModel _me() {
    final user = Get.find<AuthController>().currentUser.value;
    return UserModel(
      id: user?.id ?? '',
      name: (user != null && user.fullName.isNotEmpty) ? user.fullName : 'You',
    );
  }

  void _confirmDelete(CommentsController controller, String commentId) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteComment(commentId);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _me();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ),
            Divider(height: 1, color: context.borderColor),
            Expanded(child: Obx(_buildList)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final target = c.replyingTo.value;
                      if (target == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Replying to ${target.author.name}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: c.cancelReply,
                              child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }),
                    Row(
                      children: [
                        UserAvatar(user: me, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Obx(() => TextField(
                                controller: c.inputController,
                                style: TextStyle(color: context.textPrimaryColor),
                                decoration: InputDecoration(
                                  hintText: c.replyingTo.value == null ? 'Write a comment...' : 'Write a reply…',
                                  hintStyle: TextStyle(color: context.textSecondaryColor),
                                  filled: true,
                                  fillColor: context.cardBgAlt,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onSubmitted: (_) => c.send(),
                              )),
                        ),
                        const SizedBox(width: 8),
                        Obx(() => IconButton(
                              onPressed: c.sending.value ? null : c.send,
                              icon: const Icon(Icons.send, color: AppColors.primary),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (c.loading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final loadError = c.error.value;
    if (loadError != null && c.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor)),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: c.load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (c.comments.isEmpty) {
      return Center(
        child: Text('Be the first to comment', style: TextStyle(color: context.textSecondaryColor)),
      );
    }
    final items = <Widget>[];
    for (final comment in c.topLevelComments) {
      items.add(CommentTile(
        comment: comment,
        onReply: () => c.startReply(comment),
        onDelete: _canDelete(comment) ? () => _confirmDelete(c, comment.id) : null,
      ));
      for (final reply in c.repliesTo(comment.id)) {
        items.add(CommentTile(
          comment: reply,
          isReply: true,
          onReply: () => c.startReply(reply),
          onDelete: _canDelete(reply) ? () => _confirmDelete(c, reply.id) : null,
        ));
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  bool _canDelete(CommentModel comment) {
    final currentUserId = c.currentUserId;
    return currentUserId.isNotEmpty && comment.author.id == currentUserId;
  }
}