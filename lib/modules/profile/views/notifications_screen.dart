import 'package:flutter/material.dart';
import 'app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // TODO: load/save these from a `notification_preferences` table per user.
  bool _likes = true;
  bool _comments = true;
  bool _newFollowers = true;
  bool _reminders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Notifications'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Preferences',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: cardDecoration(context),
            child: Column(
              children: [
                _switchTile(context, 'Likes on your posts', _likes, (v) => setState(() => _likes = v)),
                _divider(context),
                _switchTile(context, 'Comments', _comments, (v) => setState(() => _comments = v)),
                _divider(context),
                _switchTile(context, 'New followers', _newFollowers, (v) => setState(() => _newFollowers = v)),
                _divider(context),
                _switchTile(context, 'Study reminders', _reminders, (v) => setState(() => _reminders = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: cardDecoration(context),
            child: Column(
              children: [
                _notificationTile(context, 'Maria Chen liked your post', '2h ago'),
                _divider(context),
                _notificationTile(context, 'Sam Patel started following you', '1d ago'),
                _divider(context),
                _notificationTile(context, 'Reminder: Study group at 6 PM', '2d ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(BuildContext context, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 13.5, color: context.textPrimaryColor))),
          Switch(value: value, activeColor: AppColors.primaryPurple, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _notificationTile(BuildContext context, String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.primaryPurple.withOpacity(0.18) : const Color(0xFFE6E9FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications, size: 16, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: context.textPrimaryColor))),
          Text(time, style: TextStyle(fontSize: 11, color: context.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(height: 1, color: context.borderColor, indent: 14, endIndent: 14);
}