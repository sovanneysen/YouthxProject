import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/core/theme/app_theme.dart';
import 'package:youthx/modules/profile/views/settings_screen.dart';

/// Rows that were removed from Settings because their tap handlers were empty
/// TODOs, so they looked selectable while doing nothing.
const List<String> removedRows = <String>[
  'Language',
  'Currency',
  'Account security',
  'Storage and data',
];

void main() {
  /// Pumps Settings in the app's real light or dark theme, so the theme
  /// extension the screen relies on resolves exactly as it does in the app.
  Future<void> pumpSettings(WidgetTester tester, {required bool isDark}) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const SettingsScreen(),
      ),
    );
    await tester.pump();
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('renders the Settings app bar and About row', (tester) async {
    await pumpSettings(tester, isDark: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
  });

  testWidgets('no longer advertises a hardcoded currency', (tester) async {
    await pumpSettings(tester, isDark: false);

    expect(find.text('GBP (£)'), findsNothing);
    // Guards against the value simply being renamed to another currency.
    expect(find.textContaining('£'), findsNothing);
    expect(find.textContaining('GBP'), findsNothing);
  });

  testWidgets('removed non-functional rows are absent', (tester) async {
    await pumpSettings(tester, isDark: false);

    for (final row in removedRows) {
      expect(find.text(row), findsNothing, reason: 'unexpected row: $row');
    }
  });

  testWidgets('no row looks tappable without a destination', (tester) async {
    await pumpSettings(tester, isDark: false);

    // A chevron or an enabled onTap would imply a detail screen that does not
    // exist, which is the exact problem this cleanup removed.
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.onTap, isNull);
  });

  testWidgets('renders in light theme', (tester) async {
    await pumpSettings(tester, isDark: false);

    expect(tester.takeException(), isNull);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('renders in dark theme', (tester) async {
    await pumpSettings(tester, isDark: true);

    expect(tester.takeException(), isNull);
    expect(find.text('About'), findsOneWidget);
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
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                child: const Text('open settings'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('open settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
