import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Notification feed for the Profile tab.
///
/// The backend has no notification resource, so there is no real feed to
/// display. The screen states that plainly instead of listing invented people
/// and activity, and the preference switches were removed rather than left in
/// place implying settings that nothing saves.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Notifications'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: context.textSecondaryColor,
              ),
              const SizedBox(height: 14),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Notifications are not connected yet, so there is nothing to '
                'show here. Anything new will appear in this list once it is.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
