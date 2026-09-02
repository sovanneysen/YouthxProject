import 'package:get/get.dart';

import '../../../core/network/app_config.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    final user = args is UserModel ? args : UserModel(id: AppConfig.currentUserId, name: 'You');

    // Stories are stored on the shared community repository, so make sure it
    // exists even when Profile is opened from outside the community module
    // (e.g. messenger), where CommunityBinding may never have run.
    final repo = Get.isRegistered<CommunityRepository>()
        ? Get.find<CommunityRepository>()
        : Get.put<CommunityRepository>(MockCommunityRepository(), permanent: true);

    Get.lazyPut<ProfileController>(() => ProfileController(user: user, repository: repo));
  }
}
