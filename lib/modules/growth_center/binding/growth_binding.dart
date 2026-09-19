import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/repositories/growth_repository.dart';
import '../../../data/repositories/rest_growth_repository.dart';
import '../controllers/growth_controller.dart';

class GrowthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GrowthRepository>()) {
      Get.put<GrowthRepository>(
        RestGrowthRepository(apiProvider: Get.find<ApiProvider>()),
        permanent: true,
      );
    }

    Get.lazyPut<GrowthController>(
      () => GrowthController(repository: Get.find<GrowthRepository>()),
    );
  }
}