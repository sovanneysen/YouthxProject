import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import 'animated_entrance.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.onPressed,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return TapScale(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: gradient.colors.first.withOpacity(0.38),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.button.copyWith(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
