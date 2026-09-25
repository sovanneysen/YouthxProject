import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';

class OverviewCalendarCard extends StatelessWidget {
  final DateTime displayedMonth; // which month is currently shown
  final DateTime selectedDay;
  final Set<DateTime> goalDeadlineDays; // days with a purple dot
  final Set<DateTime> taskDueDays; // days with a green dot
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const OverviewCalendarCard({
    super.key,
    required this.displayedMonth,
    required this.selectedDay,
    required this.goalDeadlineDays,
    required this.taskDueDays,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // How many days are in this month
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;
    // What weekday the 1st falls on (1 = Monday ... 7 = Sunday)
    final firstWeekday = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    ).weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: context.isDark ? Border.all(color: context.borderColor) : null,
      ),
      child: Column(
        children: [
          // --- Month navigation header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavArrow(icon: Icons.chevron_left, onTap: onPreviousMonth),
              Text(
                '${_monthNames[displayedMonth.month - 1]} ${displayedMonth.year}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryColor,
                ),
              ),
              _NavArrow(icon: Icons.chevron_right, onTap: onNextMonth),
            ],
          ),
          const SizedBox(height: 16),

          // --- Weekday labels row ---
          Row(
            children: _dayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // --- Day grid ---
          // firstWeekday - 1 = how many empty cells before day 1
          // (e.g. if the 1st is a Thursday, weekday = 4, so 3 blanks before it)
          _buildDayGrid(context, daysInMonth, firstWeekday),

          Divider(height: 24, color: context.borderColor),

          // --- Legend ---
          Row(
            children: [
              _LegendDot(color: Colors.deepPurple, label: 'Goal deadline'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.green, label: 'Task due'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayGrid(BuildContext context, int daysInMonth, int firstWeekday) {
    // Build one flat list: blanks first, then day numbers 1..daysInMonth
    final cells = <Widget>[];

    for (int i = 0; i < firstWeekday - 1; i++) {
      cells.add(const SizedBox()); // empty cell, no day number
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final thisDate = DateTime(displayedMonth.year, displayedMonth.month, day);
      final isSelected = _isSameDay(thisDate, selectedDay);
      final hasGoalDot = goalDeadlineDays.any((d) => _isSameDay(d, thisDate));
      final hasTaskDot = taskDueDays.any((d) => _isSameDay(d, thisDate));

      cells.add(
        GestureDetector(
          onTap: () => onDaySelected(thisDate),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : context.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Reserve space for a dot whether or not one is shown,
                // so rows don't jump around in height.
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasGoalDot) _dot(Colors.deepPurple),
                      if (hasGoalDot && hasTaskDot) const SizedBox(width: 3),
                      if (hasTaskDot) _dot(Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // GridView needs a fixed number of columns (7, for the days of the week)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent:
            54, // fixed height per cell — enough for circle + dot row
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) => cells[index],
    );
  }

  Widget _dot(Color color) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.cardBgAlt,
        ),
        child: Icon(icon, size: 20, color: context.textSecondaryColor),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
        ),
      ],
    );
  }
}
