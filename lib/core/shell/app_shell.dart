import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/views/home_screen.dart';
import '../../modules/community/binding/community_binding.dart';
import '../../modules/community/views/community_view.dart';
import '../../modules/finance/bindings/finance_binding.dart';
import '../../modules/finance/views/finance_home_page.dart';
import '../../modules/growth_center/binding/growth_binding.dart';
import '../../modules/growth_center/controllers/growth_controller.dart';
import '../../modules/growth_center/views/growth_view.dart';
import '../../modules/profile/binding/profile_data_binding.dart';
import '../../modules/profile/views/profile_screen.dart';

/// Persistent bottom-navigation shell.
///
/// Owns a single [BottomNavigationBar] and keeps every tab alive in an
/// [IndexedStack] so each screen preserves its own state while switching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _homeTab = 0;
  static const int _communityTab = 1;
  static const int _growthTab = 2;

  int _index = _homeTab;

  @override
  void initState() {
    super.initState();
    // CommunityView is a GetView that requires CommunityController before it
    // builds. CommunityBinding is idempotent, so it is safe to run here.
    CommunityBinding().dependencies();
    // GrowthView needs GrowthController (gets its own lists from REST).
    GrowthBinding().dependencies();
    // FinanceHomePage is a GetView<FinanceController>; FinanceBinding is
    // idempotent (mock-safe guard), so it is safe to run here like the others.
    FinanceBinding().dependencies();
    // ProfileScreen reads its header and stats from ProfileDataController.
    // ProfileDataBinding is idempotent and local-only (no HTTP), so it is
    // safe to run here as well.
    ProfileDataBinding().dependencies();
  }

  /// Home's "View all habits" shortcut: switch the existing shell to Growth
  /// with the Habits sub-tab selected instead of pushing a second Growth page.
  void _openHabitsTab() {
    if (!mounted) return;
    Get.find<GrowthController>().activeTab.value = GrowthController.tabHabits;
    setState(() => _index = _growthTab);
  }

  /// Home's "See All" shortcut: switch the existing shell to Community.
  void _openCommunityTab() {
    if (!mounted) return;
    setState(() => _index = _communityTab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onViewAllHabits: _openHabitsTab,
            onSeeAllCommunity: _openCommunityTab,
          ),
          const CommunityView(),
          const GrowthView(),
          const FinanceHomePage(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _index = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Growth',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}