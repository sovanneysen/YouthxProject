import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../data/models/post_model.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isReply;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    this.onAvatarTap,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8, left: isReply ? 40 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(user: comment.author, size: isReply ? 26 : 34, onTap: onAvatarTap),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.author.name, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(comment.text, style: AppTextStyles.body),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Row(
                    children: [
                      Text(timeago.format(comment.createdAt, locale: 'en_short'), style: AppTextStyles.small),
                      if (onReply != null) ...[
                        const SizedBox(width: 14),
                        InkWell(
                          onTap: onReply,
                          child: Text(
                            'Reply',
                            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
