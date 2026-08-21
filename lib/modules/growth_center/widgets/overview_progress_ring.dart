import 'package:flutter/material.dart';

class OverviewProgressRing extends StatelessWidget {
  final double percent; // 0.0 to 1.0

  const OverviewProgressRing({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 8,
              backgroundColor: Colors.blue.shade50,
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue,
                ),
              ),
              Text(
                'overall',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
