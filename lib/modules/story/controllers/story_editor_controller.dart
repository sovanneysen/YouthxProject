import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/app_config.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';

const List<Color> storyTextColors = [
  Colors.white,
  Colors.black,
  Color(0xFF2F80ED),
  Color(0xFFEB5757),
  Color(0xFFF2C94C),
  Color(0xFF27AE60),
];

const List<Color> storyBackgroundColors = [
  Colors.white,
  Color(0xFF111827),
  Color(0xFF3D3D3D),
  Color(0xFF2F80ED),
  Color(0xFF5D5FEF),
  Color(0xFF9B51E0),
  Color(0xFFEB5757),
  Color(0xFFF2994A),
  Color(0xFF27AE60),
];

class StoryEditorController extends GetxController {
  final CommunityRepository repository;
  StoryEditorController({required this.repository});

  final RxnString imagePath = RxnString();
  final RxnString backgroundColorHex = RxnString();
  final RxList<StoryTextOverlay> overlays = <StoryTextOverlay>[].obs;
  final Rxn<StoryTextOverlay> selectedOverlay = Rxn<StoryTextOverlay>();
  final Rxn<StoryModel> editingStory = Rxn<StoryModel>();
  final RxBool posting = false.obs;
  final RxBool saving = false.obs;
  final RxBool isSaved = false.obs;
  final RxBool isShared = false.obs;

  bool get isEditing => editingStory.value != null;

  void loadStory(StoryModel story) {
    editingStory.value = story;
    imagePath.value = story.imagePath.isEmpty ? null : story.imagePath;
    backgroundColorHex.value = story.backgroundColorHex;
    overlays.assignAll(story.textOverlays.map(_copyOverlay));
    selectedOverlay.value = null;
    isSaved.value = false;
    isShared.value = false;
  }

  void startNewStory() {
    editingStory.value = null;
    imagePath.value = null;
    backgroundColorHex.value = null;
    overlays.clear();
    selectedOverlay.value = null;
    isSaved.value = false;
    isShared.value = false;
    posting.value = false;
    saving.value = false;
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: source, imageQuality: 90);
    if (file != null) {
      imagePath.value = file.path;
      backgroundColorHex.value = null;
    }
  }

  void setBackgroundColor(String hex) {
    if (imagePath.value != null) return;
    backgroundColorHex.value = hex;
  }

  void addText() {
    final overlay = StoryTextOverlay(
      id: const Uuid().v4(),
      position: const Offset(0.5, 0.5),
      text: 'Tap to edit',
      color: storyTextColors.first,
    );
    overlays.add(overlay);
    selectedOverlay.value = overlay;
  }

  void updateOverlayPosition(String id, Offset normalizedPosition) {
    final overlay = overlays.firstWhereOrNull((o) => o.id == id);
    if (overlay == null) return;
    overlay.position = Offset(
      normalizedPosition.dx.clamp(0.0, 1.0),
      normalizedPosition.dy.clamp(0.0, 1.0),
    );
    overlays.refresh();
  }

  void updateOverlayText(String id, String text) {
    final overlay = overlays.firstWhereOrNull((o) => o.id == id);
    if (overlay == null) return;
    overlay.text = text;
    overlays.refresh();
  }

  void updateOverlayColor(String id, Color color) {
    final overlay = overlays.firstWhereOrNull((o) => o.id == id);
    if (overlay == null) return;
    overlay.color = color;
    overlays.refresh();
  }

  void removeOverlay(String id) {
    overlays.removeWhere((o) => o.id == id);
    if (selectedOverlay.value?.id == id) selectedOverlay.value = null;
  }

  void selectOverlay(StoryTextOverlay? overlay) =>
      selectedOverlay.value = overlay;

  /// Publishable with an image, while still allowing legacy text-only stories
  /// with a saved background to be updated.
  bool get canPost =>
      imagePath.value != null ||
      (backgroundColorHex.value != null && overlays.isNotEmpty);

  StoryModel _compose() {
    final existing = editingStory.value;
    final me =
        existing?.author ?? UserModel(id: AppConfig.currentUserId, name: 'You');
    final image = imagePath.value;
    return StoryModel(
      id: existing?.id ?? const Uuid().v4(),
      author: me,
      imagePath: image ?? '',
      textOverlays: overlays.map(_copyOverlay).toList(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      backgroundColorHex: image == null ? backgroundColorHex.value : null,
      viewed: existing?.viewed ?? false,
    );
  }

  StoryTextOverlay _copyOverlay(StoryTextOverlay overlay) {
    return StoryTextOverlay(
      id: overlay.id,
      position: overlay.position,
      text: overlay.text,
      color: overlay.color,
      fontSize: overlay.fontSize,
    );
  }

  /// "Save" keeps the story as a draft without publishing it to the feed.
  /// Independent from "Share" — both can be activated at the same time.
  Future<bool> saveStory() async {
    if (!canPost || isSaved.value) return false;
    saving.value = true;
    try {
      await repository.addDraftStory(_compose());
      isSaved.value = true;
      return true;
    } finally {
      saving.value = false;
    }
  }

  /// "Share" publishes the story to the community feed. Also independent from
  /// "Save", and guarded so tapping the active button never duplicates.
  Future<bool> postStory() async {
    if (!canPost || isShared.value) return false;
    posting.value = true;
    try {
      final story = _compose();
      if (isEditing) {
        await repository.updateStory(story);
        editingStory.value = story;
      } else {
        await repository.addStory(story);
      }
      isShared.value = true;
      return true;
    } finally {
      posting.value = false;
    }
  }

  Future<bool> deleteStory() async {
    final story = editingStory.value;
    if (story == null) return false;
    await repository.deleteStory(story.id);
    return true;
  }
}
