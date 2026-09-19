/// Parsed shapes of the backend auth contract.
///
/// Mirrors the verified Draft Backend:
///   POST /api/auth/register -> 201 UserResponse
///   POST /api/auth/login    -> 200 { "token": "...", "user": UserResponse }
///   GET  /users/me          -> 200 UserResponse
///
/// Field names exactly match `com.youthx.backend.dto.UserResponse` /
/// `LoginResponse`. Kept separate from the UI's [UserModel] (id/name/avatar)
/// so backend parsing stays stable regardless of UI model changes.
class AuthUserModel {
  final String id;
  final String email;
  final String fullName;
  final int xpPoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.xpPoints,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String,
    xpPoints: json['xpPoints'] as int? ?? 0,
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class LoginResponseModel {
  final String token;
  final AuthUserModel user;

  const LoginResponseModel({required this.token, required this.user});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        token: json['token'] as String,
        user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}
