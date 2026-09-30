import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../story/views/story_viewer_view.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_data_controller.dart';
import '../mock_social_data.dart';
import '../../../core/theme/app_theme.dart';

/// Profile route reached from a community author's avatar.
/// never be attributed to somebody else.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final isSelf = Get.isRegistered<ProfileDataController>()
        ? Get.find<ProfileDataController>().userId == controller.user.id
        : false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Obx(() {
                final userStories = controller.activeStories;
                final avatar = UserAvatar(user: controller.user, size: 92);
                if (userStories.isEmpty) return avatar;
                // Instagram-style: a ring around the avatar signals the user
                // has live stories; tapping opens their story viewer.
                return _StoryRing(
                  onTap: () => Get.toNamed(
                    '/story/view',
                    arguments: StoryViewerArgs(groups: [userStories]),
                  ),
                  child: avatar,
                );
              }),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                controller.user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            const SizedBox(height: 2),
            Center(
              child: Text('@${controller.user.name.replaceAll(' ', '').toLowerCase()}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 16),
            _StatsRow(isSelf: isSelf),
            if (!isSelf) ...[
              const SizedBox(height: 20),
              _FollowButton(userId: controller.user.id),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final bool isSelf;
  const _StatsRow({required this.isSelf});

  @override
  Widget build(BuildContext context) {
    int postCount = 0;
    if (isSelf && Get.isRegistered<ProfileDataController>()) {
      postCount = Get.find<ProfileDataController>().postCount;
    } else {
      // Mock post count for other users
      postCount = (isSelf ? 0 : 3); // 3 is just a dummy demo number for others.
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(label: 'Posts', value: '$postCount'),
        _Stat(
          label: 'Followers',
          value: '—',
        ),
        _Stat(
          label: 'Following',
          value: '—',
        ),
      ],
    );
  }
}

class _FollowButton extends StatefulWidget {
  final String userId;
  const _FollowButton({required this.userId});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => isFollowing = !isFollowing),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isFollowing ? context.cardBgAlt : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: isFollowing ? Border.all(color: context.borderColor) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing ? AppColors.textPrimary : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _StoryRing extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _StoryRing({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFF5B5FEF), // primary
              Color(0xFF7C5CF0), // accentPurple
              Color(0xFFF59E0B), // accentOrange
              Color(0xFFEF4444), // accentRed
              Color(0xFF5B5FEF), // primary
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
