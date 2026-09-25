import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SelectableGridItem<T> {
  final T value;
  final String emoji;
  final String? label; // * ← was `required String label`, now optional
  const SelectableGridItem({
    required this.value,
    required this.emoji,
    this.label,
  });
}

class SelectableGrid<T> extends StatelessWidget {
  final List<SelectableGridItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final int crossAxisCount;

  const SelectableGrid({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.value == selectedValue;
        return GestureDetector(
          onTap: () => onSelected(item.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? (context.isDark
                      ? const Color(0xFF4F46E5).withValues(alpha: 0.25)
                      : const Color(0xFFEFF3FF))
                  : context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : context.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 24)),
                if (item.label != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.label!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : context.textPrimaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

