import 'package:flutter_test/flutter_test.dart';
import 'package:youthx/data/models/auth_user_model.dart';

void main() {
  test('login response parses token and user from the backend contract', () {
    final json = {
      'token': 'eyJhbGciOiJIUzI1NiJ9',
      'user': {
        'id': '3f2a1c5e-0000-4000-8000-000000000001',
        'email': 'alex@university.edu',
        'fullName': 'Alex Johnson',
        'xpPoints': 0,
        'createdAt': '2026-09-19T10:00:00+07:00',
        'updatedAt': '2026-09-19T10:00:00+07:00',
      },
    };

    final result = LoginResponseModel.fromJson(json);

    expect(result.token, 'eyJhbGciOiJIUzI1NiJ9');
    expect(result.user.id, '3f2a1c5e-0000-4000-8000-000000000001');
    expect(result.user.email, 'alex@university.edu');
    expect(result.user.fullName, 'Alex Johnson');
    expect(result.user.xpPoints, 0);
    expect(result.user.createdAt, isNotNull);
    expect(result.user.updatedAt, isNotNull);
  });

  test('register response (plain user object) parses', () {
    final json = {
      'id': '3f2a1c5e-0000-4000-8000-000000000001',
      'email': 'alex@university.edu',
      'fullName': 'Alex Johnson',
      'xpPoints': 0,
      'createdAt': '2026-09-19T10:00:00+07:00',
      'updatedAt': null,
    };

    final user = AuthUserModel.fromJson(json);

    expect(user.fullName, 'Alex Johnson');
    expect(user.xpPoints, 0);
    expect(user.createdAt, isNotNull);
    expect(user.updatedAt, isNull);
  });

  test('missing optional fields fall back to defaults', () {
    final user = AuthUserModel.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'fullName': 'A B',
    });

    expect(user.xpPoints, 0);
    expect(user.createdAt, isNull);
    expect(user.updatedAt, isNull);
  });
}
