import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/core/theme/app_theme.dart';
// Both screens expose a class called `NotificationsScreen`, so each import is
// aliased to name the two implementations unambiguously.
import 'package:youthx/auth/views/notifi_screen.dart' as auth;
import 'package:youthx/modules/profile/views/notifications_screen.dart'
    as profile;

/// Every piece of fabricated content the audit found, across both screens.
///
/// Asserting these strings are absent is what stops a future edit from
/// quietly reintroducing invented people or activity.
const List<String> fakeContent = <String>[
  // modules/profile/views/notifications_screen.dart
  'Maria Chen liked your post',
  'Sam Patel started following you',
  'Reminder: Study group at 6 PM',
  'Likes on your posts',
  'Comments',
  'New followers',
  'Study reminders',
  'Preferences',
  'Recent',
  // auth/views/notifi_screen.dart
  'Streak saved',
  '7-day streak kept alive',
  'Sophea liked your post',
  'Reading streak update',
  'Budget alert',
  'Food is 80% of limit',
  'Goal reminder',
  'Learn UI design due in 2 days',
  'New comment',
  'On your Community post',
  'TODAY',
  'EARLIER',
  'Mark all read',
];

/// The honest copy both screens share.
const emptyTitle = 'No notifications yet';
const emptyBody = 'not connected yet';

void main() {
  /// Pumps [home] inside the app's real light or dark theme, so the theme
  /// extension the screens rely on resolves exactly as it does in the app.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    required bool isDark,
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: home,
      ),
    );
    await tester.pump();
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  group('Profile notifications screen', () {
    testWidgets('renders and shows the honest empty state', (tester) async {
      await pump(tester, const profile.NotificationsScreen(), isDark: false);

      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text(emptyTitle), findsOneWidget);
      expect(find.textContaining(emptyBody), findsOneWidget);
    });

    testWidgets('shows no fabricated people or activity', (tester) async {
      await pump(tester, const profile.NotificationsScreen(), isDark: false);

      for (final text in fakeContent) {
        expect(find.text(text), findsNothing, reason: 'unexpected: $text');
      }
    });

    testWidgets('no longer offers non-functional preference switches', (
      tester,
    ) async {
      await pump(tester, const profile.NotificationsScreen(), isDark: false);

      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('renders in light theme', (tester) async {
      await pump(tester, const profile.NotificationsScreen(), isDark: false);

      expect(tester.takeException(), isNull);
      expect(find.text(emptyTitle), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await pump(tester, const profile.NotificationsScreen(), isDark: true);

      expect(tester.takeException(), isNull);
      expect(find.text(emptyTitle), findsOneWidget);
    });
  });

  group('Home notifications screen', () {
    testWidgets('renders and shows the honest empty state', (tester) async {
      await pump(tester, const auth.NotificationsScreen(), isDark: false);

      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text(emptyTitle), findsOneWidget);
      expect(find.textContaining(emptyBody), findsOneWidget);
    });

    testWidgets('shows no fabricated people or activity', (tester) async {
      await pump(tester, const auth.NotificationsScreen(), isDark: false);

      for (final text in fakeContent) {
        expect(find.text(text), findsNothing, reason: 'unexpected: $text');
      }
    });

    testWidgets('renders in light theme', (tester) async {
      await pump(tester, const auth.NotificationsScreen(), isDark: false);

      expect(tester.takeException(), isNull);
      expect(find.text(emptyTitle), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await pump(tester, const auth.NotificationsScreen(), isDark: true);

      expect(tester.takeException(), isNull);
      expect(find.text(emptyTitle), findsOneWidget);
    });
  });

  group('Both screens stay navigable', () {
    testWidgets('profile screen pushes and pops without crashing', (
      tester,
    ) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const profile.NotificationsScreen(),
                  ),
                ),
                child: const Text('open profile'),
              ),
            ),
          ),
        ),
        isDark: false,
      );

      await tester.tap(find.text('open profile'));
      await tester.pumpAndSettle();
      expect(find.text(emptyTitle), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('open profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('home screen pushes and pops without crashing', (
      tester,
    ) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const auth.NotificationsScreen(),
                  ),
                ),
                child: const Text('open home'),
              ),
            ),
          ),
        ),
        isDark: true,
      );

      await tester.tap(find.text('open home'));
      await tester.pumpAndSettle();
      expect(find.text(emptyTitle), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('open home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
