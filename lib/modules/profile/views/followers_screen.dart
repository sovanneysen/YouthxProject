import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Maps to a `followers` table: id, user_id, follower_id, created_at
class FollowerUser {
  final String name;
  final String initials;
  final String subtitle;
  bool isFollowingBack;

  FollowerUser({
    required this.name,
    required this.initials,
    required this.subtitle,
    this.isFollowingBack = false,
  });
}

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  // TODO: replace with data fetched from your backend (e.g. followers table).
  final List<FollowerUser> _followers = [
    FollowerUser(name: 'Maria Chen', initials: 'MC', subtitle: 'Computer Science'),
    FollowerUser(name: 'Sam Patel', initials: 'SP', subtitle: 'Business Admin', isFollowingBack: true),
    FollowerUser(name: 'Jordan Lee', initials: 'JL', subtitle: 'Mechanical Eng.'),
    FollowerUser(name: 'Priya Nair', initials: 'PN', subtitle: 'Psychology', isFollowingBack: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Followers (${_followers.length})'),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _followers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = _followers[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: cardDecoration(context),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.isDark
                      ? AppColors.primaryPurple.withOpacity(0.18)
                      : const Color(0xFFE6E9FE),
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
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                      Text(user.subtitle,
                          style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => user.isFollowingBack = !user.isFollowingBack),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: user.isFollowingBack
                        ? (context.isDark ? context.cardBgAlt : Colors.grey.shade100)
                        : AppColors.primaryPurple,
                    foregroundColor: user.isFollowingBack
                        ? (context.isDark ? context.textPrimaryColor : Colors.grey.shade700)
                        : Colors.white,
                    side: BorderSide(
                        color: user.isFollowingBack
                            ? (context.isDark ? context.borderColor : Colors.grey.shade300)
                            : Colors.transparent),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(user.isFollowingBack ? 'Following' : 'Follow',
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