import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../mock_social_data.dart';
import 'app_colors.dart';

/// Followers list (Demo only).
class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final Set<String> _followingIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Followers'),
      body: ListView.builder(
        itemCount: MockSocialData.followers.length,
        itemBuilder: (context, index) {
          final user = MockSocialData.followers[index];
          final isFollowing = _followingIds.contains(user.id);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: UserAvatar(user: user, size: 48),
            title: Text(
              user.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            subtitle: Text(
              '@${user.name.replaceAll(' ', '').toLowerCase()}',
              style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
            ),
            trailing: _buildFollowButton(user.id, isFollowing),
            onTap: () => Get.toNamed('/profile', arguments: user),
          );
        },
      ),
    );
  }

  Widget _buildFollowButton(String userId, bool isFollowing) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isFollowing) {
            _followingIds.remove(userId);
          } else {
            _followingIds.add(userId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? context.cardBgAlt : AppColors.primaryPurple,
          borderRadius: BorderRadius.circular(8),
          border: isFollowing ? Border.all(color: context.borderColor) : null,
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing ? context.textPrimaryColor : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
