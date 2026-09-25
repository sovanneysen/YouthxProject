import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';

class OverviewNavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const OverviewNavArrow({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.cardBgAlt,
        ),
        child: Icon(icon, size: 20, color: context.textSecondaryColor),
      ),
    );
  }
}
