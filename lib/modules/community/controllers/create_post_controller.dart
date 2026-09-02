import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/app_config.dart';
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

  Future<bool> submit() async {
    if (!canSubmit) return false;
    posting.value = true;
    try {
      if (isEditing) {
        editingPost!
          ..caption = captionController.text.trim()
          ..imagePaths = List.of(images)
          ..feelingId = selectedFeeling.value
          ..tags = List.of(selectedTags);
        await repository.updatePost(editingPost!);
      } else {
        final me = UserModel(id: AppConfig.currentUserId, name: 'You');
        final post = PostModel(
          id: const Uuid().v4(),
          author: me,
          createdAt: DateTime.now(),
          caption: captionController.text.trim(),
          imagePaths: List.of(images),
          feelingId: selectedFeeling.value,
          tags: List.of(selectedTags),
        );
        await repository.createPost(post);
      }
      return true;
    } finally {
      posting.value = false;
    }
  }

  @override
  void onClose() {
    captionController.dispose();
    super.onClose();
  }
}
