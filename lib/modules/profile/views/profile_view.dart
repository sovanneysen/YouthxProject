import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../story/views/story_viewer_view.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_data_controller.dart';

/// Profile route reached from a community author's avatar.
///
/// The viewed user's identity and stories come from [ProfileController]. The
/// statistics row is only shown when this route is showing the signed-in
/// account, because posts, goals, and streaks belong to that account and must
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
            const Center(
              child: Text('Community member',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 24),
            if (isSelf) const _SelfStats() else const _OtherUserNote(),
          ],
        ),
      ),
    );
  }
}

/// Real Posts / Goals / Streak for the signed-in account.
///
/// A dash is shown while the growth lists are still loading, so an in-flight
/// request is never displayed as a zero.
class _SelfStats extends StatelessWidget {
  const _SelfStats();

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileDataController>();
    return Obx(() {
      final growthLoading = profile.growthLoading;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(label: 'Posts', value: '${profile.postCount}'),
          _Stat(
            label: 'Goals',
            value: growthLoading ? '—' : '${profile.goalCount}',
          ),
          _Stat(
            label: 'Streak',
            value: growthLoading ? '—' : '${profile.streakDays}',
          ),
        ],
      );
    });
  }
}

/// States plainly that another user's numbers are not available, instead of
/// showing placeholder counts.
class _OtherUserNote extends StatelessWidget {
  const _OtherUserNote();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Posts, goals, and streaks are only shown on your own profile.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
