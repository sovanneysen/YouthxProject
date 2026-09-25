import 'package:flutter/material.dart';
import 'app_colors.dart';

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
            child: Column(
              children: [
                _tile(context, Icons.language, 'Language', 'English'),
                _divider(context),
                _tile(context, Icons.attach_money, 'Currency', 'GBP (£)'),
                _divider(context),
                _tile(context, Icons.lock_outline, 'Account security', ''),
                _divider(context),
                _tile(context, Icons.storage_outlined, 'Storage and data', ''),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: cardDecoration(context),
            child: _tile(context, Icons.info_outline, 'About', 'v1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(title, style: TextStyle(fontSize: 13.5, color: context.textPrimaryColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(value, style: TextStyle(fontSize: 12.5, color: context.textSecondaryColor)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: context.textSecondaryColor),
        ],
      ),
      onTap: () {
        // TODO: navigate to a detail screen or open a picker for this setting.
      },
    );
  }

  Widget _divider(BuildContext context) => Divider(height: 1, color: context.borderColor, indent: 14, endIndent: 14);
}