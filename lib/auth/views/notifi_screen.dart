import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ==================================================================
// 6. NOTIFICATIONS SCREEN
// ==================================================================

/// Notification feed reachable from the Home bell icon.
///
/// The backend exposes no notification resource, so this screen renders an
/// honest empty state rather than a fabricated feed. The previous list of
/// invented people, likes, comments, and alerts was removed instead of being
/// replaced with different sample data, and "Mark all read" was dropped because
/// there is no unread state to act on.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
      ),
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
