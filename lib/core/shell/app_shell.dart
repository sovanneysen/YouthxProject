import 'package:flutter/material.dart';

import '../../auth/views/home_screen.dart';
import '../../modules/community/binding/community_binding.dart';
import '../../modules/community/views/community_view.dart';
import '../../modules/finance/bindings/finance_binding.dart';
import '../../modules/finance/views/finance_home_page.dart';
import '../../modules/growth_center/binding/growth_binding.dart';
import '../../modules/growth_center/views/growth_view.dart';
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
  int _index = 0;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          CommunityView(),
          GrowthView(),
          FinanceHomePage(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: const Color(0xFF4A6CF7),
        unselectedItemColor: Colors.grey,
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