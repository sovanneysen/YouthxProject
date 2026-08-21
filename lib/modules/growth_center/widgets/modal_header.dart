import 'package:flutter/material.dart';

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
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E1B2E))),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onClose,
              icon: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Color(0xFFF1F2F6), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF4B5563)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
