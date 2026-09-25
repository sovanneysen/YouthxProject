import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';

class OverviewModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const OverviewModeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
