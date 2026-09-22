import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';

class GrowthTab {
  final String emoji;
  final String label;
  final Color activeColor;
  const GrowthTab({
    required this.emoji,
    required this.label,
    required this.activeColor,
  });
}

class GrowthTabBar extends StatelessWidget {
  final List<GrowthTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const GrowthTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = index == activeIndex;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? tab.activeColor : context.cardBgAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
