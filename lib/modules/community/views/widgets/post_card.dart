import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../data/models/feeling_model.dart';
import '../../../../data/models/post_model.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isOwner;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAuthorTap;

  const PostCard({
    super.key,
    required this.post,
    required this.isOwner,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
    required this.onAuthorTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(user: post.author, onTap: widget.onAuthorTap),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: widget.onAuthorTap,
                      child: Text(post.author.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    Text(
                      '${timeago.format(post.createdAt)} • ${post.visibility}'
                      '${_feeling != null ? " • feeling ${_feeling!.display}" : ""}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (widget.isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) {
                    if (value == 'edit') widget.onEdit();
                    if (value == 'delete') widget.onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                        SizedBox(width: 10),
                        Text('Edit Post'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.caption, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimary)),
          ],
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#$t',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
          if (post.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 11,
                child: _PostImages(
                  paths: post.imagePaths,
                  onPageChanged: (p) => setState(() => _page = p),
                ),
              ),
            ),
            if (post.imagePaths.length > 1) ...[
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < post.imagePaths.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i == _page ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _page ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionButton(
                icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.likedByMe ? AppColors.danger : AppColors.textSecondary,
                label: '${post.likeCount}',
                onTap: widget.onLike,
              ),
              const SizedBox(width: 20),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                color: AppColors.textSecondary,
                label: '${post.commentCount}',
                onTap: widget.onComment,
              ),
              const Spacer(),
              _ActionButton(
                icon: post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
                color: post.savedByMe ? AppColors.primary : AppColors.textSecondary,
                label: '',
                onTap: widget.onSave,
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.ios_share,
                color: post.sharedByMe ? AppColors.primary : AppColors.textSecondary,
                label: '',
                onTap: widget.onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  FeelingModel? get _feeling => widget.post.feelingId == null
      ? null
      : FeelingCatalog.all.firstWhere((f) => f.id == widget.post.feelingId);
}

class _PostImages extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<int> onPageChanged;

  const _PostImages({required this.paths, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: paths.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) => _PostImage(path: paths[index]),
    );
  }
}

class _PostImage extends StatelessWidget {
  final String path;
  const _PostImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.surfaceAlt,
          child: const Icon(
            Icons.image_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.surfaceAlt,
          child: const Icon(
            Icons.image_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.surfaceAlt,
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 40),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
