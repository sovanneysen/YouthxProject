import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Maps to a `following` table: id, user_id, followed_user_id, created_at
class FollowedUser {
  final String name;
  final String initials;
  final String subtitle;
  bool isFollowing;

  FollowedUser({
    required this.name,
    required this.initials,
    required this.subtitle,
    this.isFollowing = true,
  });
}

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  // TODO: replace with data fetched from your backend (e.g. following table).
  final List<FollowedUser> _following = [
    FollowedUser(name: 'Coach Danny', initials: 'CD', subtitle: 'Fitness & Wellness'),
    FollowedUser(name: 'Emma Wright', initials: 'EW', subtitle: 'UX Design'),
    FollowedUser(name: 'Study Hub', initials: 'SH', subtitle: 'Community page'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildSimpleAppBar('Following (${_following.length})'),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _following.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = _following[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: cardDecoration(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE6E9FE),
                  child: Text(user.initials,
                      style: const TextStyle(
                          color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(user.subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => user.isFollowing = !user.isFollowing),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: user.isFollowing ? Colors.grey.shade100 : AppColors.primaryPurple,
                    foregroundColor: user.isFollowing ? Colors.grey.shade700 : Colors.white,
                    side: BorderSide(color: user.isFollowing ? Colors.grey.shade300 : Colors.transparent),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(user.isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}