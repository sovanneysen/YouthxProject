import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Settings sub-page opened from the Profile menu.
///
/// Only settings that are genuinely implemented appear here. The Language,
/// Currency, Account security, and Storage rows were removed because their tap
/// handlers were empty TODOs, so they looked selectable while doing nothing and
/// the Currency row advertised a hardcoded British-pound label that no code
/// reads. They
/// are intentionally absent until real support exists; do not re-add a row
/// without a working destination. The working light/dark toggle stays in the
/// Profile menu where `ThemeController` is already wired up.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: cardDecoration(context),
            child: _tile(context, Icons.info_outline, 'About', 'v1.0.0'),
          ),
        ],
      ),
    );
  }

  /// Display-only row. There is no `onTap` and no trailing chevron, so the row
  /// does not advertise a detail screen that does not exist.
  Widget _tile(BuildContext context, IconData icon, String title, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(title, style: TextStyle(fontSize: 13.5, color: context.textPrimaryColor)),
      trailing: Text(
        value,
        style: TextStyle(fontSize: 12.5, color: context.textSecondaryColor),
      ),
    );
  }
}
