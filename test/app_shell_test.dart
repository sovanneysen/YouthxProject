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
  Finder navItem(int index) => find.byKey(Key('nav_item_$index'));

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
    await tester.pump(const Duration(milliseconds: 500));
  }

  int shellIndex(WidgetTester tester) {
    final stacks = tester.widgetList<IndexedStack>(find.byType(IndexedStack));
    // The AppShell's IndexedStack is the main one that holds the tabs
    // It should have exactly 5 children
    final shellStack = stacks.firstWhere((s) => s.children.length == 5);
    return shellStack.index ?? 0;
  }

  testWidgets('app shell shows one persistent bottom navigation bar with 5 tabs',
      (tester) async {
    await pumpShell(tester);

    // The new custom navigation bar has 5 tabs
    expect(navItem(0), findsOneWidget);
    expect(navItem(1), findsOneWidget);
    expect(navItem(2), findsOneWidget);
    expect(navItem(3), findsOneWidget);
    expect(navItem(4), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('tabs switch the IndexedStack index without pushing routes',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(navItem(1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shellIndex(tester), 1);

    await tester.tap(navItem(2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shellIndex(tester), 2);

    await tester.tap(navItem(3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shellIndex(tester), 3);

    await tester.tap(navItem(4));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shellIndex(tester), 4);

    await tester.tap(navItem(0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shellIndex(tester), 0);

    // Tabs are embedded in the shell, never pushed as routes.
    expect(find.byType(AppShell), findsOneWidget);
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

    await tester.tap(navItem(4));
    await tester.pump(const Duration(milliseconds: 500));

    expect(shellIndex(tester), 4);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('My posts'), findsOneWidget);
  });

  testWidgets('community tab renders the feed once its binding has run',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(navItem(1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(shellIndex(tester), 1);
    expect(find.byType(CommunityView), findsOneWidget);
  });
}