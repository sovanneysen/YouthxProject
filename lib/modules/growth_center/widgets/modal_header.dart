import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ModalHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const ModalHeader({super.key, required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.textPrimaryColor)),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onClose,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: context.cardBgAlt, shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, size: 18, color: context.textPrimaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

