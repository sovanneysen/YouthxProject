import 'package:flutter/material.dart';

class CardOverflowMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CardOverflowMenu({super.key, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
        padding: EdgeInsets.zero,
        offset: const Offset(0, 44),
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        constraints: const BoxConstraints(minWidth: 170, maxWidth: 200),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'edit',
            padding: EdgeInsets.zero,
            height: 52,
            child: _MenuRow(
              icon: Icons.edit_outlined,
              label: 'Edit',
              color: const Color(0xFF1E1B2E),
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            padding: EdgeInsets.zero,
            height: 52,
            child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: Colors.red.shade600,
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') onEdit?.call();
          if (value == 'delete') onDelete?.call();
        },
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
