import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_data_controller.dart';
import 'app_colors.dart';

/// Edits the profile fields that only exist on this device.
///
/// The backend `User` has no profile update endpoint, so a display name, bio,
/// and location cannot be sent to the server. They are stored locally per
/// authenticated user id, and the screen says so rather than implying the
/// account was updated.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  bool _saving = false;

  ProfileDataController? get _profile => Get.isRegistered<ProfileDataController>()
      ? Get.find<ProfileDataController>()
      : null;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  /// Fills the fields from the session and any stored local values. The local
  /// display name wins when set, matching what the Profile header shows.
  void _prefill() {
    final profile = _profile;
    if (profile == null) return;
    _nameController.text = profile.displayName;
    _bioController.text = profile.bio;
    _locationController.text = profile.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;
    setState(() => _saving = true);

    // A blank name clears the override so the real account name shows again
    // instead of storing an empty string.
    final name = _nameController.text.trim();
    await profile.saveLocalProfile(
      displayName: name.isEmpty ? null : name,
      bio: _bioController.text,
      location: _locationController.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved on this device')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildAvatar()),
            const SizedBox(height: 28),
            _label(context, 'Display name'),
            _textField(
              context,
              _nameController,
              hint: 'Leave blank to use your account name',
            ),
            const SizedBox(height: 16),
            _label(context, 'Bio'),
            _textField(context, _bioController, maxLines: 3),
            const SizedBox(height: 16),
            _label(context, 'Location'),
            _textField(context, _locationController),
            const SizedBox(height: 16),
            _buildLocalOnlyNote(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save changes',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Real initials on the same gradient used by the Profile header.
  Widget _buildAvatar() {
    final profile = _profile;
    final initials = profile?.initials ?? '';

    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.gradientBlue, AppColors.primaryPurple],
        ),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// States plainly that these fields are not sent to the server.
  Widget _buildLocalOnlyNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.smartphone, size: 16, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'These details are saved on this device only. They are not synced '
              'to your account or shared with other users.',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child:
            Text(text, style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
      );

  Widget _textField(
    BuildContext context,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.cardBgAlt,
        hintText: hint,
        hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple),
        ),
      ),
    );
  }
}
