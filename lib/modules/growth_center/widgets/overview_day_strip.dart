import 'package:flutter/material.dart';

class OverviewDayStrip extends StatelessWidget {
  final List<DateTime> days; // always 7 days, Monday first
  final DateTime selectedDay;
  final Set<DateTime> markedDays; // days that get a small dot
  final ValueChanged<DateTime> onDaySelected;

  const OverviewDayStrip({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.markedDays,
    required this.onDaySelected,
  });

  static const _dayLabels = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final isSelected = _isSameDay(day, selectedDay);
        final hasDot = markedDays.any((d) => _isSameDay(d, day));

        return Expanded(
          child: GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _dayLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1E1B2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 6,
                    child: hasDot
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : Colors.blue,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
