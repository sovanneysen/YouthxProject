import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ==================================================================
// 6. NOTIFICATIONS SCREEN
// ==================================================================
class _NotificationItem {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String time;
  const _NotificationItem({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<_NotificationItem> today = [
    _NotificationItem(
      icon: Icons.local_fire_department,
      iconBackground: Color(0xFFFFE9DA),
      title: 'Streak saved',
      subtitle: '7-day streak kept alive',
      time: '12m ago',
    ),
    _NotificationItem(
      icon: Icons.favorite,
      iconBackground: Color(0xFFFFE1E6),
      title: 'Sophea liked your post',
      subtitle: 'Reading streak update',
      time: '45m ago',
    ),
    _NotificationItem(
      icon: Icons.savings,
      iconBackground: Color(0xFFE6F8EF),
      title: 'Budget alert',
      subtitle: 'Food is 80% of limit',
      time: '2h ago',
    ),
  ];

  static const List<_NotificationItem> earlier = [
    _NotificationItem(
      icon: Icons.track_changes,
      iconBackground: Color(0xFFFFE9DA),
      title: 'Goal reminder',
      subtitle: 'Learn UI design due in 2 days',
      time: '1d ago',
    ),
    _NotificationItem(
      icon: Icons.chat_bubble_outline,
      iconBackground: Color(0xFFF0F0F0),
      title: 'New comment',
      subtitle: 'On your Community post',
      time: '3d ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        foregroundColor: context.textPrimaryColor,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('TODAY', today, context),
          const SizedBox(height: 20),
          _buildSection('EARLIER', earlier, context),
        ],
      ),
    );
  }

  Widget _buildSection(
    String label,
    List<_NotificationItem> items,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondaryColor,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: context.isDark
                ? Border.all(color: context.borderColor)
                : null,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.iconBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 18, color: Colors.black87),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    trailing: Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, indent: 66, color: context.borderColor),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
