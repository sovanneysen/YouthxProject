import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/auth/views/home_screen.dart';
import 'package:youthx/core/network/initial_binding.dart';
import 'package:youthx/core/shell/app_shell.dart';
import 'package:youthx/data/repositories/community_repository.dart';
import 'package:youthx/data/repositories/finance_repository.dart';
import 'package:youthx/data/repositories/growth_repository.dart';
import 'package:youthx/modules/community/views/community_view.dart';
import 'package:youthx/modules/finance/views/finance_home_page.dart';
import 'package:youthx/modules/growth_center/views/growth_view.dart';
import 'package:youthx/modules/profile/views/profile_screen.dart';

void main() {
  Finder navItem(String label) => find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(label),
      );

  Future<void> pumpShell(WidgetTester tester) async {
    // Widget tests must stay offline: pre-register the in-memory repository
    // so CommunityBinding keeps it instead of wiring the REST repo (which
    // would try a real HTTP call inside the test harness).
    if (!Get.isRegistered<CommunityRepository>()) {
      Get.put<CommunityRepository>(MockCommunityRepository(), permanent: true);
    }
    if (!Get.isRegistered<GrowthRepository>()) {
      Get.put<GrowthRepository>(MockGrowthRepository(), permanent: true);
    }
    if (!Get.isRegistered<FinanceRepository>()) {
      Get.put<FinanceRepository>(MockFinanceRepository(), permanent: true);
    }
    if (!Get.isRegistered<FinanceRepository>()) {
      Get.put<FinanceRepository>(MockFinanceRepository(), permanent: true);
    }
    await tester.pumpWidget(
      GetMaterialApp(home: const AppShell(), initialBinding: InitialBinding()),
    );
    await tester.pumpAndSettle();
  }

  int shellIndex(WidgetTester tester) =>
      tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex;

  testWidgets('app shell shows one persistent bottom navigation bar with 5 tabs',
      (tester) async {
    await pumpShell(tester);

    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.items.length, 5);
    expect(navBar.currentIndex, 0);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('tabs switch the IndexedStack index without pushing routes',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(navItem('Community'));
    await tester.pumpAndSettle();
    expect(shellIndex(tester), 1);

    await tester.tap(navItem('Growth'));
    await tester.pumpAndSettle();
    expect(shellIndex(tester), 2);

    await tester.tap(navItem('Finance'));
    await tester.pumpAndSettle();
    expect(shellIndex(tester), 3);

    await tester.tap(navItem('Profile'));
    await tester.pumpAndSettle();
    expect(shellIndex(tester), 4);

    await tester.tap(navItem('Home'));
    await tester.pumpAndSettle();
    expect(shellIndex(tester), 0);

    // Tabs are embedded in the shell, never pushed as routes.
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('all five tab screens are mounted inside the shell', (tester) async {
    await pumpShell(tester);

    // IndexedStack mounts every child up-front; unselected tabs are offstage,
    // so find them with skipOffstage: false to prove they are all present.
    expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(CommunityView, skipOffstage: false), findsOneWidget);
    expect(find.byType(GrowthView, skipOffstage: false), findsOneWidget);
    expect(find.byType(FinanceHomePage, skipOffstage: false), findsOneWidget);
    expect(find.byType(ProfileScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('profile tab uses the rich ProfileScreen without an inner nav bar',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(navItem('Profile'));
    await tester.pumpAndSettle();

    expect(shellIndex(tester), 4);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    // Only the shell bar remains; ProfileScreen no longer renders its own nav.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('community tab renders the feed once its binding has run',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(navItem('Community'));
    await tester.pumpAndSettle();

    expect(shellIndex(tester), 1);
    expect(find.textContaining('budgeting spreadsheet'), findsOneWidget);
    expect(find.byType(CommunityView), findsOneWidget);
  });
}