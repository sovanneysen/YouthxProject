import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
  final _usernameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _bioController = TextEditingController();
  final _linksController = TextEditingController();
  final _genderController = TextEditingController();

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
    _usernameController.text = profile.username;
    _pronounsController.text = profile.pronouns;
    _bioController.text = profile.bio;
    _linksController.text = profile.links;
    _genderController.text = profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    _linksController.dispose();
    _genderController.dispose();
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
      username: _usernameController.text,
      pronouns: _pronounsController.text,
      links: _linksController.text,
      gender: _genderController.text,
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
      appBar: buildSimpleAppBar(context, 'Edit profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text(
                      'Edit picture or avatar',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _igTextField(context, _nameController, 'Name'),
            const SizedBox(height: 8),
            _igTextField(context, _usernameController, 'Username'),
            const SizedBox(height: 8),
            _igTextField(context, _pronounsController, 'Pronouns'),
            const SizedBox(height: 8),
            _igTextField(context, _bioController, 'Bio', maxLines: 2),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Links', style: TextStyle(fontSize: 16, color: context.textPrimaryColor)),
                  Text('Add link', style: TextStyle(fontSize: 14, color: context.textSecondaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Banners', style: TextStyle(fontSize: 16, color: context.textPrimaryColor)),
                      Text('Add music, profiles and more.', style: TextStyle(fontSize: 13, color: context.textSecondaryColor)),
                    ],
                  ),
                  Text('1', style: TextStyle(fontSize: 14, color: context.textSecondaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _igTextField(context, _genderController, 'Gender', showDropdown: true),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Reorder grid', style: TextStyle(fontSize: 16, color: context.textPrimaryColor)),
            ),
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
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Real initials on the same gradient used by the Profile header, or local photo.
  Widget _buildAvatar() {
    return Obx(() {
      final profile = _profile;
      final initials = profile?.initials ?? '';
      final imagePath = profile?.imagePath;

      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: imagePath == null ? const LinearGradient(
              colors: [AppColors.gradientBlue, AppColors.primaryPurple],
            ) : null,
            image: imagePath != null ? DecorationImage(
              image: FileImage(File(imagePath)),
              fit: BoxFit.cover,
            ) : null,
          ),
          child: imagePath == null ? Center(
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ) : null,
        ),
      );
    });
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) {
      final profile = _profile;
      if (profile != null) {
        // Save immediately to reflect dynamically across the app.
        // We preserve current text field inputs so they aren't lost.
        final name = _nameController.text.trim();
        await profile.saveLocalProfile(
          displayName: name.isEmpty ? null : name,
          imagePath: file.path,
          bio: _bioController.text,
          username: _usernameController.text,
          pronouns: _pronounsController.text,
          links: _linksController.text,
          gender: _genderController.text,
        );
      }
    }
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

  Widget _igTextField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool showDropdown = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBgAlt.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: context.textPrimaryColor, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondaryColor, fontSize: 14),
          floatingLabelStyle: TextStyle(color: context.textSecondaryColor, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          suffixIcon: showDropdown
              ? Icon(Icons.keyboard_arrow_down, color: context.textSecondaryColor)
              : null,
        ),
      ),
    );
  }
}
