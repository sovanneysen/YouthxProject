import 'dart:ui';
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

  /// Home's avatar tap shortcut: switch the existing shell to Profile.
  void _openProfileTab() {
    if (!mounted) return;
    setState(() => _index = 4);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onViewAllHabits: _openHabitsTab,
            onSeeAllCommunity: _openCommunityTab,
            onAvatarTap: _openProfileTab,
          ),
          const CommunityView(),
          const GrowthView(),
          const FinanceHomePage(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242526) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(-1.0 + (_index * 0.5), 0),
                      child: FractionallySizedBox(
                        widthFactor: 0.2,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
                      _buildNavItem(1, Icons.groups_rounded, Icons.groups_outlined),
                      _buildNavItem(2, Icons.track_changes_rounded, Icons.track_changes_outlined),
                      _buildNavItem(3, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined),
                      _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon) {
    final isSelected = _index == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

    return Expanded(
      child: GestureDetector(
        key: Key('nav_item_$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _index = index),
        child: SizedBox(
          height: 60,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? activeColor : inactiveColor,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}