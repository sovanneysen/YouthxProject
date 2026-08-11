import 'package:get/get.dart';

import '../../../data/repositories/community_repository.dart';
import '../controllers/community_controller.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true → created once, NEVER auto-disposed for the
    // lifetime of the app. Same instance everywhere, every time.
    if (!Get.isRegistered<CommunityRepository>()) {
      Get.put<CommunityRepository>(MockCommunityRepository(), permanent: true);
    }

    Get.lazyPut<CommunityController>(
      () => CommunityController(repository: Get.find<CommunityRepository>()),
    );
  }
}
