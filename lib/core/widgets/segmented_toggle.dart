import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SegmentedOption<T> {
  final T value;
  final String label;
  const SegmentedOption({required this.value, required this.label});
}

class SegmentedToggle<T> extends StatelessWidget {
  final List<SegmentedOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.activeColor = const Color(0xFF4F46E5),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isActive = opt.value == selectedValue;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: opt == options.last ? 0 : 10),
            child: GestureDetector(
              onTap: () => onSelected(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : context.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive ? activeColor : context.borderColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : context.textPrimaryColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

