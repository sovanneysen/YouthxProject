import 'package:flutter/material.dart';
import 'app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildSimpleAppBar('Settings'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: cardDecoration(),
            child: Column(
              children: [
                _tile(context, Icons.language, 'Language', 'English'),
                _divider(),
                _tile(context, Icons.attach_money, 'Currency', 'GBP (£)'),
                _divider(),
                _tile(context, Icons.lock_outline, 'Account security', ''),
                _divider(),
                _tile(context, Icons.storage_outlined, 'Storage and data', ''),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: cardDecoration(),
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
      title: Text(title, style: const TextStyle(fontSize: 13.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(value, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: () {
        // TODO: navigate to a detail screen or open a picker for this setting.
      },
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200, indent: 14, endIndent: 14);
}