import 'package:get/get.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../controllers/profile_controller.dart';
import 'profile_data_binding.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    ProfileDataBinding().dependencies();

    final args = Get.arguments;
    // Without an argument the route is showing the signed-in account, so fall
    // back to the real session user rather than a placeholder name.
    final user = args is UserModel
        ? args
        : UserModel(
            id: _signedInUserId(),
            name: _signedInUserName(),
          );

    // Stories are stored on the shared community repository, so make sure it
    // exists even when Profile is opened from outside the community module
    // (e.g. messenger), where CommunityBinding may never have run.
    final repo = Get.isRegistered<CommunityRepository>()
        ? Get.find<CommunityRepository>()
        : Get.put<CommunityRepository>(MockCommunityRepository(), permanent: true);

    Get.lazyPut<ProfileController>(() => ProfileController(user: user, repository: repo));
  }

  /// Real id of the signed-in account, or '' when there is no session.
  static String _signedInUserId() {
    if (!Get.isRegistered<AuthController>()) return '';
    return Get.find<AuthController>().currentUser.value?.id ?? '';
  }

  /// Real name of the signed-in account, or '' when there is no session.
  static String _signedInUserName() {
    if (!Get.isRegistered<AuthController>()) return '';
    return Get.find<AuthController>().currentUser.value?.fullName ?? '';
  }
}
