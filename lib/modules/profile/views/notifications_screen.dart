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
      backgroundColor: AppColors.background,
      appBar: buildSimpleAppBar('Notifications'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Preferences',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: cardDecoration(),
            child: Column(
              children: [
                _switchTile('Likes on your posts', _likes, (v) => setState(() => _likes = v)),
                _divider(),
                _switchTile('Comments', _comments, (v) => setState(() => _comments = v)),
                _divider(),
                _switchTile('New followers', _newFollowers, (v) => setState(() => _newFollowers = v)),
                _divider(),
                _switchTile('Study reminders', _reminders, (v) => setState(() => _reminders = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: cardDecoration(),
            child: Column(
              children: [
                _notificationTile('Maria Chen liked your post', '2h ago'),
                _divider(),
                _notificationTile('Sam Patel started following you', '1d ago'),
                _divider(),
                _notificationTile('Reminder: Study group at 6 PM', '2d ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13.5))),
          Switch(value: value, activeColor: AppColors.primaryPurple, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _notificationTile(String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: Color(0xFFE6E9FE), shape: BoxShape.circle),
            child: const Icon(Icons.notifications, size: 16, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200, indent: 14, endIndent: 14);
}