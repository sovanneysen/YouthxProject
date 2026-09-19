import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../data/repositories/rest_finance_repository.dart';
import '../controllers/finance_controller.dart';

/// Wires the Finance module at runtime, mirroring the proven Growth/Community
/// binding pattern:
///
///  * registers the real `RestFinanceRepository` (Dio / Draft Backend) as the
///    singleton `FinanceRepository` — exactly once (idempotent / mock-safe),
///  * then lazy-registers the [FinanceController] that every Finance view
///    consumes.
///
/// Tests / offline runs put a `MockFinanceRepository` first; the
/// `if (!Get.isRegistered<FinanceRepository>())` guard means this binding never
/// overwrites it, so the same widget tree works with both backends.
class FinanceBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FinanceRepository>()) {
      Get.put<FinanceRepository>(
        RestFinanceRepository(apiProvider: Get.find<ApiProvider>()),
        permanent: true,
      );
    }

    Get.lazyPut<FinanceController>(
      () => FinanceController(repository: Get.find<FinanceRepository>()),
    );
  }
}
