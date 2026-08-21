import 'dart:math';
import 'package:flutter/material.dart';

/// A circular progress ring with a gradient stroke and an animated sweep.
class GradientRing extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Gradient gradient;
  final Color trackColor;
  final Widget? center;

  const GradientRing({
    super.key,
    required this.value,
    required this.gradient,
    required this.trackColor,
    this.size = 72,
    this.strokeWidth = 7,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              value: animatedValue,
              strokeWidth: strokeWidth,
              gradient: gradient,
              trackColor: trackColor,
            ),
            child: center == null ? null : Center(child: center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Gradient gradient;
  final Color trackColor;

  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.gradient,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * pi * value;
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.gradient != gradient ||
      oldDelegate.trackColor != trackColor;
}
