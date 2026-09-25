import 'package:flutter_test/flutter_test.dart';
import 'package:youthx/core/network/token_store.dart';
import 'package:youthx/data/models/auth_user_model.dart';
import 'package:youthx/data/providers/api_provider.dart';
import 'package:youthx/data/repositories/auth_repository.dart';
import 'package:youthx/auth/controllers/auth_controller.dart';

class FakeAuthRepository extends AuthRepository {
  bool registerCalled = false;
  Object? nextError;

  @override
  Future<AuthUserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    registerCalled = true;
    if (nextError != null) throw nextError!;
    return _user;
  }

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    if (nextError != null) throw nextError!;
    return LoginResponseModel(token: 'jwt-123', user: _user);
  }

  @override
  Future<AuthUserModel> fetchMe() async {
    if (nextError != null) throw nextError!;
    return _user;
  }

  static const _user = AuthUserModel(
    id: 'u1',
    email: 'alex@university.edu',
    fullName: 'Alex Johnson',
  );
}

void main() {
  late MemoryTokenStore store;
  late FakeAuthRepository repo;

  setUp(() {
    store = MemoryTokenStore();
    repo = FakeAuthRepository();
  });

  AuthController build() =>
      AuthController(authRepository: repo, tokenStore: store);

  test('login stores the jwt and sets the current user', () async {
    final controller = build();
    await controller.login(email: 'alex@university.edu', password: 'pw');

    expect(await store.read(), 'jwt-123');
    expect(controller.currentUser.value?.id, 'u1');
    expect(controller.currentUser.value?.email, 'alex@university.edu');
    expect(controller.isLoading.value, isFalse);
  });

  test('register auto-logs-in and stores the jwt', () async {
    final controller = build();
    await controller.register(
      email: 'alex@university.edu',
      password: 'pw',
      fullName: 'Alex Johnson',
    );

    expect(repo.registerCalled, isTrue);
    expect(controller.currentUser.value?.fullName, 'Alex Johnson');
    expect(await store.read(), 'jwt-123');
  });

  test('failed login surfaces the error and leaves state signed out', () async {
    repo.nextError = const ApiException(401, 'Invalid credentials');
    final controller = build();

    await expectLater(
      controller.login(email: 'alex@university.edu', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
    expect(controller.currentUser.value, isNull);
    expect(await store.read(), isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test('restoreSession restores the user when a token exists', () async {
    await store.write('jwt-123');
    final controller = build();

    await controller.restoreSession();

    expect(controller.currentUser.value?.email, 'alex@university.edu');
    expect(controller.isAuthenticated, isTrue);
  });

  test('restoreSession clears an invalid token', () async {
    await store.write('stale-jwt');
    repo.nextError = const ApiException(401, 'Unauthorized');
    final controller = build();

    await controller.restoreSession();

    expect(await store.read(), isNull);
    expect(controller.currentUser.value, isNull);
    expect(controller.isAuthenticated, isFalse);
  });

  test('restoreSession is a no-op without a stored token', () async {
    final controller = build();

    await controller.restoreSession();

    expect(controller.currentUser.value, isNull);
    expect(repo.registerCalled, isFalse);
  });

  test('logout clears the token and user', () async {
    await store.write('jwt-123');
    final controller = build();
    await controller.restoreSession();
    expect(controller.isAuthenticated, isTrue);

    await controller.logout();

    expect(await store.read(), isNull);
    expect(controller.isAuthenticated, isFalse);
  });
}
