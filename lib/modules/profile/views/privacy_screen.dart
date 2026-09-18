import 'package:flutter/material.dart';
import 'app_colors.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // TODO: load/save these from a `privacy_settings` table per user.
  bool _privateAccount = false;
  bool _showActivity = true;
  bool _allowTagging = true;
  bool _showLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildSimpleAppBar('Privacy'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: cardDecoration(),
            child: Column(
              children: [
                _switchTile(
                  'Private account',
                  'Only approved followers can see your posts',
                  _privateAccount,
                  (v) => setState(() => _privateAccount = v),
                ),
                _divider(),
                _switchTile(
                  'Show activity status',
                  'Let others see when you\'re active',
                  _showActivity,
                  (v) => setState(() => _showActivity = v),
                ),
                _divider(),
                _switchTile(
                  'Allow tagging',
                  'Others can tag you in posts',
                  _allowTagging,
                  (v) => setState(() => _allowTagging = v),
                ),
                _divider(),
                _switchTile(
                  'Share location',
                  'Show your city on your profile',
                  _showLocation,
                  (v) => setState(() => _showLocation = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: cardDecoration(),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: const Icon(Icons.download_outlined, color: AppColors.primaryPurple),
              title: const Text('Download your data', style: TextStyle(fontSize: 13.5)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // TODO: trigger a data export request to your backend.
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(value: value, activeColor: AppColors.primaryPurple, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200, indent: 14, endIndent: 14);
}