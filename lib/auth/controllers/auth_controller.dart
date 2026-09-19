import 'package:get/get.dart';

import '../../core/network/token_store.dart';
import '../../data/models/auth_user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// App-scoped auth state consumed by [AuthScreen] and [SplashScreen].
///
/// Register is followed by an automatic login because the backend does not
/// return a JWT from `/api/auth/register` (only `/api/auth/login` does).
class AuthController extends GetxController {
  AuthController({required this.authRepository, required this.tokenStore});

  final AuthRepository authRepository;
  final TokenStore tokenStore;

  final Rx<AuthUserModel?> currentUser = Rx<AuthUserModel?>(null);
  final RxBool isLoading = false.obs;

  bool get isAuthenticated => currentUser.value != null;

  /// Restores a persisted session on app start. Best-effort: an expired or
  /// missing token quietly resets to signed-out instead of blocking startup.
  Future<void> restoreSession() async {
    final token = await tokenStore.read();
    if (token == null || token.isEmpty) return;

    try {
      final user = await authRepository.fetchMe();
      currentUser.value = user;
    } catch (_) {
      await tokenStore.clear();
      currentUser.value = null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    isLoading.value = true;
    try {
      final result = await authRepository.login(
        email: email,
        password: password,
      );
      await tokenStore.write(result.token);
      currentUser.value = result.user;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    isLoading.value = true;
    try {
      await authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      await login(email: email, password: password);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await tokenStore.clear();
    currentUser.value = null;
  }
}
