import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';

class GrowthHeader extends StatelessWidget {
  final String badgeEmoji;
  final Color badgeBackground;

  const GrowthHeader({
    super.key,
    this.badgeEmoji = '🎯',
    this.badgeBackground = const Color(0xFFF3E8FF),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY GROWTH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level up daily 🚀',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(badgeEmoji, style: const TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}
