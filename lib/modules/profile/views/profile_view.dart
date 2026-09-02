import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../story/views/story_viewer_view.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: Text(controller.user.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text('Community member', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(label: 'Posts', value: '12'),
                _Stat(label: 'Streak', value: '7d'),
                _Stat(label: 'Following', value: '84'),
              ],
            ),
          ],
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
              AppColors.primary,
              AppColors.accentPurple,
              AppColors.accentOrange,
              AppColors.accentRed,
              AppColors.primary,
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
