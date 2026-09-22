import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';

class OverviewStatCard extends StatelessWidget {
  final String emoji;
  final double percent;
  final String label;
  final String subtext;
  final Color color;

  const OverviewStatCard({
    super.key,
    required this.emoji,
    required this.percent,
    required this.label,
    required this.subtext,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            '${(percent * 100).round()}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
