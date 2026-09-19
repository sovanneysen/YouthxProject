import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';

// ==================================================================
// 2. ONBOARDING SCREEN (3 pages in a PageView)
// ==================================================================
class _OnboardingPageData {
  final Color background;
  final Color accent;
  final IconData centerIcon;
  final String title;
  final String description;
  final String buttonText;

  const _OnboardingPageData({
    required this.background,
    required this.accent,
    required this.centerIcon,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<_OnboardingPageData> pages = const [
    _OnboardingPageData(
      background: Color(0xFFEAF0FE),
      accent: Color(0xFF4A6CF7),
      centerIcon: Icons.groups,
      title: 'Connect with your Community',
      description:
          'Join thousands of students sharing wins, building habits, and growing together every day.',
      buttonText: 'Continue →',
    ),
    _OnboardingPageData(
      background: Color(0xFFF1EBFE),
      accent: Color(0xFF8B5CF6),
      centerIcon: Icons.track_changes,
      title: 'Track Goals & Build Habits',
      description:
          'Set meaningful goals, build daily habits, and watch your progress compound over time.',
      buttonText: 'Continue →',
    ),
    _OnboardingPageData(
      background: Color(0xFFE6F8EF),
      accent: Color(0xFF10B981),
      centerIcon: Icons.account_balance_wallet,
      title: 'Master Your Finances',
      description:
          'Budget smarter, track every expense, and build financial confidence from day one.',
      buttonText: "Let's Go! ✓",
    ),
  ];

  void goToAuth() {
    Get.offNamed(AppRoutes.auth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentPage];

    return Scaffold(
      backgroundColor: page.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: goToAuth,
                  child: Text('Skip', style: TextStyle(color: page.accent)),
                ),
              ),
            ),

            // The swipeable pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => currentPage = index);
                },
                itemBuilder: (context, index) {
                  final p = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p.centerIcon,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                final isActive = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? page.accent : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Continue / Let's Go button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: page.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final isLastPage = currentPage == pages.length - 1;
                    if (isLastPage) {
                      goToAuth();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    page.buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
