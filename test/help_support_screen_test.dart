import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/core/theme/app_theme.dart';
import 'package:youthx/modules/profile/views/help_support_screen.dart';

/// Stale instructions that Batch 3I removed because they described flows the
/// app does not have. These are the exact affirmative claims, not substrings:
/// the truthful replacements legitimately mention the same words inside a
/// negation ("Private accounts are not supported yet"), so a substring match
/// would flag correct copy.
const List<String> removedCopy = <String>[
  'Go to Settings > Account security',
  'Account security',
  'choose "Reset password"',
  'follow the steps sent to your email',
  'turn on "Private account"',
  'so only approved followers can see your posts',
  'Only approved followers can see your posts',
];

/// The delete-a-post answer, which is correct and must not regress.
const deleteQuestion = 'How do I delete a post?';
const deleteAnswer =
    'Open the post from your "My posts" tab, tap the menu icon on the post, then choose Delete.';

void main() {
  /// Pumps Help & Support in the app's real light or dark theme, so the theme
  /// extension the screen relies on resolves exactly as it does in the app.
  Future<void> pumpHelp(WidgetTester tester, {required bool isDark}) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const HelpSupportScreen(),
      ),
    );
    await tester.pump();
  }

  /// Finds a question row and expands it, then collapses it again.
  Future<void> toggleFaq(WidgetTester tester, String question) async {
    await tester.tap(find.text(question));
    await tester.pumpAndSettle();
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  group('FAQ accordion', () {
    testWidgets('renders every question with no answer shown yet', (
      tester,
    ) async {
      await pumpHelp(tester, isDark: false);

      expect(tester.takeException(), isNull);
      expect(find.text('Help and Support'), findsOneWidget);
      expect(find.text('Frequently asked questions'), findsOneWidget);
      expect(find.text('How do I reset my password?'), findsOneWidget);
      expect(find.text('How do I make my account private?'), findsOneWidget);
      expect(find.text(deleteQuestion), findsOneWidget);
      expect(find.text(deleteAnswer), findsNothing);
    });

    testWidgets('expands and collapses an answer', (tester) async {
      await pumpHelp(tester, isDark: false);

      await toggleFaq(tester, 'How do I reset my password?');
      expect(
        find.textContaining('no self-service password reset yet'),
        findsOneWidget,
      );

      await toggleFaq(tester, 'How do I reset my password?');
      expect(
        find.textContaining('no self-service password reset yet'),
        findsNothing,
      );
    });

    testWidgets('keeps the correct delete-a-post answer', (tester) async {
      await pumpHelp(tester, isDark: false);

      await toggleFaq(tester, deleteQuestion);
      expect(find.text(deleteAnswer), findsOneWidget);
    });
  });

  group('Password reset answer is truthful', () {
    testWidgets('states that no self-service reset exists', (tester) async {
      await pumpHelp(tester, isDark: false);

      await toggleFaq(tester, 'How do I reset my password?');

      expect(
        find.textContaining('no self-service password reset yet'),
        findsOneWidget,
      );
    });

    testWidgets('no longer points at Settings or a reset flow', (tester) async {
      await pumpHelp(tester, isDark: false);

      await toggleFaq(tester, 'How do I reset my password?');
      final answer = find.textContaining('no self-service password reset');

      expect(answer, findsOneWidget);
      final text = tester.widget<Text>(answer);
      // The old answer routed through Settings and a "Reset password" button.
      expect(text.data, isNot(contains('Account security')));
      expect(text.data, isNot(contains('Reset password')));
      expect(text.data, isNot(contains('follow the steps sent to your email')));
      // It must not tell the user a reset link arrives.
      expect(text.data, isNot(contains('follow the steps')));
    });
  });

  group('Privacy answer is truthful', () {
    testWidgets('states that private accounts are unsupported', (tester) async {
      await pumpHelp(tester, isDark: false);

      await toggleFaq(tester, 'How do I make my account private?');
      expect(
        find.textContaining('Private accounts are not supported yet'),
        findsOneWidget,
      );
    });

    testWidgets('drops the follower-visibility claim', (tester) async {
      await pumpHelp(tester, isDark: false);

      await toggleFaq(tester, 'How do I make my account private?');
      final answer = find.textContaining('Private accounts are not supported');

      expect(answer, findsOneWidget);
      final text = tester.widget<Text>(answer);
      // The old answer promised approved-follower visibility. The new one only
      // states there are no follower controls at all.
      expect(
        text.data,
        isNot(contains('so only approved followers can see your posts')),
      );
      expect(text.data, contains('no follower controls'));
    });
  });

  group('No removed copy survives anywhere', () {
    testWidgets('none of the stale instructions are present', (
      tester,
    ) async {
      await pumpHelp(tester, isDark: false);

      // Expand everything so collapsed answers are asserted too.
      await toggleFaq(tester, 'How do I reset my password?');
      await toggleFaq(tester, 'How do I make my account private?');
      await toggleFaq(tester, deleteQuestion);

      for (final text in removedCopy) {
        expect(find.text(text), findsNothing, reason: 'unexpected: $text');
        expect(
          find.textContaining(text),
          findsNothing,
          reason: 'unexpected substring: $text',
        );
      }
    });
  });

  group('Help actions are informational only', () {
    testWidgets('Contact support has no tap target or chevron', (tester) async {
      await pumpHelp(tester, isDark: false);

      expect(find.text('Contact support'), findsOneWidget);
      expect(find.text('No support channel is set up yet.'), findsOneWidget);

      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Contact support'),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.onTap, isNull);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('Report a problem has no tap target or chevron', (tester) async {
      await pumpHelp(tester, isDark: false);

      expect(find.text('Report a problem'), findsOneWidget);
      expect(find.text('There is nowhere to send a report yet.'), findsOneWidget);

      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Report a problem'),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.onTap, isNull);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('no row on the screen opens anywhere', (tester) async {
      await pumpHelp(tester, isDark: false);

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(tiles, hasLength(2));
      for (final tile in tiles) {
        expect(tile.onTap, isNull, reason: 'a help tile still navigates');
      }
    });
  });

  testWidgets('renders in light theme', (tester) async {
    await pumpHelp(tester, isDark: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Contact support'), findsOneWidget);
  });

  testWidgets('renders in dark theme', (tester) async {
    await pumpHelp(tester, isDark: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Contact support'), findsOneWidget);
  });

  testWidgets('pushes and pops from the Profile menu without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                ),
                child: const Text('open help'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open help'));
    await tester.pumpAndSettle();
    expect(find.text('Help and Support'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('open help'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}