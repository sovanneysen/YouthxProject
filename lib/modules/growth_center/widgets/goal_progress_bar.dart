import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GoalProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  const GoalProgressBar({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: context.cardBgAlt,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              semanticsLabel: 'Goal progress',
              semanticsValue: '${(progress.clamp(0.0, 1.0) * 100).round()}',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

