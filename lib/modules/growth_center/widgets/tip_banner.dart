import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TipBanner extends StatelessWidget {
  final String text;
  const TipBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF4F46E5).withValues(alpha: 0.15)
            : const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13.5,
            color: context.isDark
                ? const Color(0xFFC7D2FE)
                : const Color(0xFF3B4A6B),
            height: 1.4,
          ),
          children: [
            const TextSpan(text: '💡 '),
            const TextSpan(
              text: 'Tip: ',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

