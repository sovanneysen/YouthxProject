import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/selectable_chip.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/feeling_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/community_controller.dart';

class CreatePostView extends StatefulWidget {
  final PostModel? editingPost;
  const CreatePostView({super.key, this.editingPost});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  late final String tag;
  late final CreatePostController c;

  @override
  void initState() {
    super.initState();
    tag = 'create_post_${widget.editingPost?.id ?? DateTime.now().microsecondsSinceEpoch}';
    c = Get.put(
      CreatePostController(
        repository: Get.find<CommunityRepository>(),
        editingPost: widget.editingPost,
      ),
      tag: tag,
    );
  }

  @override
  void dispose() {
    Get.delete<CreatePostController>(tag: tag);
    super.dispose();
  }

  /// Called after a successful create/edit. Closes this screen and, if the
  /// community feed controller is alive, tells it to refetch from the
  /// shared repository so the new/edited post shows up immediately.
  void _handleSubmitSuccess() {
    Get.back();
    if (Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().loadFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(c.isEditing ? 'Edit Post' : 'Create Post'),
        actions: [
          Obx(() {
            c.captionDirty.value; // rebuild on every keystroke
            return TextButton(
                onPressed: c.canSubmit && !c.posting.value
                    ? () async {
                        final ok = await c.submit();
                        if (ok) _handleSubmitSuccess();
                      }
                    : null,
                child: c.posting.value
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(c.isEditing ? 'Save' : 'Post',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: c.canSubmit ? AppColors.primary : AppColors.textMuted,
                        )),
              );
          }),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              Obx(() {
                final user = Get.find<AuthController>().currentUser.value;
                final me = UserModel(
                  id: user?.id ?? '',
                  name: (user != null && user.fullName.isNotEmpty)
                      ? user.fullName
                      : 'You',
                );
                return Row(
                  children: [
                    UserAvatar(user: me, size: 44),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const Text('Posting to Community',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: c.captionController,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          _ImagesPreview(controller: c),
          const SizedBox(height: 8),
          _MediaButtons(controller: c),
          const SizedBox(height: 24),
          const Text('How are you feeling?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FeelingCatalog.all
                    .map((f) => SelectableChip(
                          label: f.display,
                          selected: c.selectedFeeling.value == f.id,
                          onTap: () => c.toggleFeeling(f.id),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 24),
          const Text('Add a tag',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TagCatalog.suggested
                    .map((t) => SelectableChip(
                          label: t,
                          selected: c.selectedTags.contains(t),
                          onTap: () => c.toggleTag(t),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 12),
          _CustomTagField(controller: c),
          const SizedBox(height: 28),
          Obx(() {
            c.captionDirty.value; // rebuild on every keystroke
            return PrimaryButton(
              label: c.isEditing ? 'Save Changes' : 'Post',
              loading: c.posting.value,
              onPressed: c.canSubmit
                  ? () async {
                      final ok = await c.submit();
                      if (ok) _handleSubmitSuccess();
                    }
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _ImagesPreview extends StatelessWidget {
  final CreatePostController controller;
  const _ImagesPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.images.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final path = controller.images[i];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(path), width: 96, height: 96, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: GestureDetector(
                    onTap: () => controller.removeImage(path),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}

class _MediaButtons extends StatelessWidget {
  final CreatePostController controller;
  const _MediaButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MediaChip(icon: Icons.image_outlined, label: 'Photo', onTap: controller.pickImage),
        const SizedBox(width: 10),
        const _MediaChip(icon: Icons.location_on_outlined, label: 'Location', onTap: null),
      ],
    );
  }
}

class _MediaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MediaChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CustomTagField extends StatefulWidget {
  final CreatePostController controller;
  const _CustomTagField({required this.controller});

  @override
  State<_CustomTagField> createState() => _CustomTagFieldState();
}

class _CustomTagFieldState extends State<_CustomTagField> {
  final _fieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _fieldController,
            decoration: InputDecoration(
              hintText: 'Add a custom tag',
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (v) {
              widget.controller.addCustomTag(v);
              _fieldController.clear();
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            widget.controller.addCustomTag(_fieldController.text);
            _fieldController.clear();
          },
          icon: const Icon(Icons.add_circle, color: AppColors.primary),
        ),
      ],
    );
  }
}