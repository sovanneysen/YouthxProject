import 'package:get/get.dart';

import '../../../core/storage/local_profile_store.dart';
import '../controllers/profile_data_controller.dart';

/// Registers the Profile data hub.
///
/// Idempotent, so it is safe to run from the app shell (Profile tab) and from
/// the `/profile` route binding. A `LocalProfileStore` registered earlier (for
/// example an in-memory one in a test) is kept as-is.
class ProfileDataBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocalProfileStore>()) {
      Get.put<LocalProfileStore>(
        const SharedPreferencesLocalProfileStore(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<ProfileDataController>()) {
      Get.put<ProfileDataController>(
        ProfileDataController(store: Get.find<LocalProfileStore>()),
        permanent: true,
      );
    }
  }
}
