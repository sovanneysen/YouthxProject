import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';

class CreatePostController extends GetxController {
  final CommunityRepository repository;
  final PostModel? editingPost;

  CreatePostController({required this.repository, this.editingPost});

  final TextEditingController captionController = TextEditingController();
  final RxList<String> images = <String>[].obs;
  final RxnString selectedFeeling = RxnString();
  final RxList<String> selectedTags = <String>[].obs;
  final RxBool posting = false.obs;
  final RxBool captionDirty = false.obs;

  bool get isEditing => editingPost != null;

  @override
  void onInit() {
    super.onInit();
    if (editingPost != null) {
      captionController.text = editingPost!.caption;
      images.assignAll(editingPost!.imagePaths);
      selectedFeeling.value = editingPost!.feelingId;
      selectedTags.assignAll(editingPost!.tags);
    }
    captionController.addListener(() => captionDirty.toggle());
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) images.add(file.path);
  }

  void removeImage(String path) => images.remove(path);

  void toggleFeeling(String id) {
    selectedFeeling.value = selectedFeeling.value == id ? null : id;
  }

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  void addCustomTag(String tag) {
    final clean = tag.trim();
    if (clean.isEmpty || selectedTags.contains(clean)) return;
    selectedTags.add(clean);
  }

  bool get canSubmit => captionController.text.trim().isNotEmpty || images.isNotEmpty;

  /// Two-step publish: create the post first, then upload each local photo
  /// against the new post id. If any upload fails, the just-created post is
  /// deleted so the backend never keeps a half-published post, and the error
  /// is surfaced for retry with the composed content preserved.
  Future<bool> submit() async {
    if (!canSubmit) return false;
    posting.value = true;
    String? createdPostId;
    try {
      final localFiles = images.where((p) => !p.startsWith('http')).toList();

      if (isEditing) {
        editingPost!
          ..caption = captionController.text.trim()
          ..feelingId = selectedFeeling.value
          ..tags = List.of(selectedTags);
        await repository.updatePost(editingPost!);
        // Locally picked images cannot be replaced after edit (no contract),
        // so they are dropped; only the caption/feeling/tags are updated.
      } else {
        final author = currentAuthor;
        final post = PostModel(
          id: const Uuid().v4(),
          author: author,
          createdAt: DateTime.now(),
          caption: captionController.text.trim(),
          imagePaths: List.of(images),
          feelingId: selectedFeeling.value,
          tags: List.of(selectedTags),
        );
        final created = await repository.createPost(post);
        createdPostId = created.id;

        if (localFiles.isNotEmpty) {
          for (final file in localFiles) {
            await repository.uploadPhoto(createdPostId, file);
          }
        }
      }
      return true;
    } catch (e) {
      // Roll back the half-published post when uploads fail part-way.
      if (!isEditing && createdPostId != null) {
        try {
          await repository.deletePost(createdPostId);
        } catch (_) {}
      }
      // Keep the composed content in the sheet so the user can retry.
      Get.snackbar(
        'Could not publish your post',
        e is ApiException ? e.message : 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
      return false;
    } finally {
      posting.value = false;
    }
  }

  /// The signed-in user for the composer header. Falls back to a neutral
  /// placeholder when no session is available (e.g. unit tests).
  UserModel get currentAuthor {
    final user = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().currentUser.value
        : null;
    final name =
        (user != null && user.fullName.isNotEmpty) ? user.fullName : 'You';
    return UserModel(id: user?.id ?? '', name: name);
  }

  @override
  void onClose() {
    captionController.dispose();
    super.onClose();
  }
}
