import '../models/auth_user_model.dart';
import '../providers/api_provider.dart';

/// Owns the exact Draft Backend auth contract:
///   POST /api/auth/register  (201 -> UserResponse)
///   POST /api/auth/login     (200 -> LoginResponse {token, user})
///   GET  /users/me           (200 -> UserResponse, requires Bearer token)
class AuthRepository {
  AuthRepository({ApiProvider? apiProvider})
    : _apiProvider = apiProvider ?? ApiProvider();

  final ApiProvider _apiProvider;

  Future<AuthUserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final data = await _apiProvider.post('/api/auth/register', {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    return AuthUserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiProvider.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return LoginResponseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthUserModel> fetchMe() async {
    final data = await _apiProvider.get('/users/me');
    return AuthUserModel.fromJson(data as Map<String, dynamic>);
  }
}
