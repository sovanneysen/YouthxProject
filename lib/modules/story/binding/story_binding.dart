import 'package:get/get.dart';

import '../../../data/repositories/community_repository.dart';
import '../controllers/story_editor_controller.dart';

class StoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StoryEditorController>()) {
      Get.lazyPut<StoryEditorController>(
        () => StoryEditorController(repository: Get.find<CommunityRepository>()),
      );
    }
  }
}
