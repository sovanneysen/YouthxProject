import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Followers list.
///
/// The backend has no follow graph, so there is no real data to show. The
/// screen states that plainly instead of listing invented people, and it
/// exposes no follow toggle, which would have nothing to persist.
class FollowersScreen extends StatelessWidget {
  const FollowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Followers'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 40, color: context.textSecondaryColor),
              const SizedBox(height: 14),
              Text(
                'No followers to show yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Following other members is not available yet, so there is '
                'nothing to list here.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: context.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
