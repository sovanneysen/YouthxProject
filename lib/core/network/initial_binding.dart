import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../data/providers/api_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../theme/theme_controller.dart';
import 'token_store.dart';

/// App-scoped DI for the auth stack, registered via
/// `GetMaterialApp(initialBinding: InitialBinding())` so AuthController is
/// available from SplashScreen before any module binding runs.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(ThemeController(), permanent: true);
    }
    Get.put<TokenStore>(const SecureTokenStore(), permanent: true);
    Get.put<ApiProvider>(
      ApiProvider(tokenStore: Get.find<TokenStore>()),
      permanent: true,
    );
    Get.put<AuthRepository>(
      AuthRepository(apiProvider: Get.find<ApiProvider>()),
      permanent: true,
    );
    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        tokenStore: Get.find<TokenStore>(),
      ),
    );
  }
}
