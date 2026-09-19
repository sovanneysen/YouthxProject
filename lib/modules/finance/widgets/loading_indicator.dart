import 'package:flutter/material.dart';

/// Compact centered loading indicator used across the Finance screens.
///
/// Kept local to the finance module (no `core/widgets` dependency) so the
/// rewrite stays self-contained and matches the existing project style.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            'Loading…',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
