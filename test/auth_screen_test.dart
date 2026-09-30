import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/auth/controllers/auth_controller.dart';
import 'package:youthx/auth/views/auth_screen.dart';
import 'package:youthx/core/network/token_store.dart';
import 'package:youthx/data/models/auth_user_model.dart';
import 'package:youthx/data/providers/api_provider.dart';
import 'package:youthx/data/repositories/auth_repository.dart';

/// The label that must never come back: it rendered as a blue link while its
/// handler did nothing, because no reset feature exists anywhere.
const removedLabel = 'Forgot password?';

/// The honest replacement Batch 3K introduced.
const truthfulCopy = 'Password reset is not currently available.';

/// Stands in for the REST layer so widget tests never hit a real backend.
class FakeAuthRepository extends AuthRepository {
  Object? nextError;

  @override
  Future<AuthUserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
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
  Future<AuthUserModel> fetchMe() async => _user;

  static const _user = AuthUserModel(
    id: 'u1',
    email: 'alex@university.edu',
    fullName: 'Alex Johnson',
  );
}

void main() {
  late FakeAuthRepository repository;

  Future<void> boot(
    WidgetTester tester, {
    required bool isDark,
  }) async {
    Get.testMode = true;
    repository = FakeAuthRepository();
    Get.put<AuthController>(
      AuthController(
        authRepository: repository,
        tokenStore: MemoryTokenStore(),
      ),
      permanent: true,
    );
    Get.put<ApiProvider>(
      ApiProvider(tokenStore: MemoryTokenStore()),
      permanent: true,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        initialRoute: '/auth',
        getPages: [
          GetPage(name: '/auth', page: () => const AuthScreen()),
          // The screen routes to /home after success; a stub is enough because
          // these tests assert the attempt, not the destination's content.
          GetPage(name: '/home', page: () => const Scaffold(body: Text('Home'))),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Switches to the Sign In tab.
  Future<void> showSignIn(WidgetTester tester) async {
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  /// The form scrolls, and on the default 800x600 test surface the submit
  /// button sits below the fold, so it has to be brought into view first.
  Future<void> submit(WidgetTester tester, String buttonLabel) async {
    final button = find.text(buttonLabel);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  group('Recovery affordance', () {
    testWidgets('Sign In shows truthful copy, not the old link', (tester) async {
      await boot(tester, isDark: false);
      await showSignIn(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(removedLabel), findsNothing);
      expect(find.text(truthfulCopy), findsOneWidget);
    });

    testWidgets('no tappable recovery widget remains', (tester) async {
      await boot(tester, isDark: false);
      await showSignIn(tester);

      // A button, ink well, or gesture detector would reintroduce the fake
      // affordance even if the label changed.
      expect(
        find.ancestor(
          of: find.text(truthfulCopy),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text(truthfulCopy),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('truthful copy is plain non-interactive text', (tester) async {
      await boot(tester, isDark: false);
      await showSignIn(tester);

      final text = tester.widget<Text>(find.text(truthfulCopy));
      expect(text.data, truthfulCopy);
      // It must not claim a channel that does not exist.
      expect(text.data, isNot(contains('@')));
      expect(text.data, isNot(contains('http')));
    });

    testWidgets('Sign Up does not show the recovery copy', (tester) async {
      await boot(tester, isDark: false);

      expect(find.text(truthfulCopy), findsNothing);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('Theme', () {
    testWidgets('renders Sign In in light theme', (tester) async {
      await boot(tester, isDark: false);
      await showSignIn(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(truthfulCopy), findsOneWidget);
    });

    testWidgets('renders Sign In in dark theme', (tester) async {
      await boot(tester, isDark: true);
      await showSignIn(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(truthfulCopy), findsOneWidget);
    });
  });

  group('Sign In behaviour is unchanged', () {
    testWidgets('renders fields and the submit button', (tester) async {
      await boot(tester, isDark: false);
      await showSignIn(tester);

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In →'), findsOneWidget);
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Your password'), findsOneWidget);
    });

    testWidgets('rejects an invalid email before calling the API', (
      tester,
    ) async {
      await boot(tester, isDark: false);
      await showSignIn(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'alex@university.edu'),
        'not-an-email',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Your password'),
        'secret123',
      );
      await tester.tap(find.text('Sign In →'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      // Still on the auth screen: nothing was routed.
      expect(find.text('Sign In →'), findsOneWidget);
    });

    testWidgets('surfaces the API error message on a failed login', (
      tester,
    ) async {
      await boot(tester, isDark: false);
      repository.nextError = const ApiException(401, 'Invalid credentials');
      await showSignIn(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'alex@university.edu'),
        'alex@university.edu',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Your password'),
        'wrong-password',
      );
      await submit(tester, 'Sign In →');

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('successful login navigates away from auth', (tester) async {
      await boot(tester, isDark: false);
      await showSignIn(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'alex@university.edu'),
        'alex@university.edu',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Your password'),
        'secret123',
      );
      await submit(tester, 'Sign In →');

      expect(find.text('Home'), findsOneWidget);
      expect(find.text(truthfulCopy), findsNothing);
    });
  });

  group('Sign Up behaviour is unchanged', () {
    testWidgets('requires a full name', (tester) async {
      await boot(tester, isDark: false);

      await tester.enterText(
        find.widgetWithText(TextField, 'alex@university.edu'),
        'alex@university.edu',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Create a password'),
        'secret123',
      );
      await submit(tester, 'Create Account →');

      expect(find.text('Please enter your full name.'), findsOneWidget);
    });

    testWidgets('registers and routes to home', (tester) async {
      await boot(tester, isDark: false);

      await tester.enterText(
        find.widgetWithText(TextField, 'Alex Johnson'),
        'Alex Johnson',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'alex@university.edu'),
        'alex@university.edu',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Create a password'),
        'secret123',
      );
      await submit(tester, 'Create Account →');

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('password visibility toggle still works', (tester) async {
      await boot(tester, isDark: false);

      final field = find.widgetWithText(TextField, 'Create a password');
      expect(tester.widget<TextField>(field).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.widgetWithText(TextField, 'Create a password')).obscureText,
        isFalse,
      );
    });
  });
}