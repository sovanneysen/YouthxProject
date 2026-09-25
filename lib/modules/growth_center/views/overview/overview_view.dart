import 'package:flutter/material.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../widgets/overview_calendar_card.dart';
import '../../widgets/overview_nav_arrow.dart';
import '../../widgets/overview_today_section.dart';
import '../../models/goal_model.dart';
import '../../models/habit_model.dart';
import '../../models/task_model.dart';
import '../../widgets/overview_mode_chip.dart';
import '../../widgets/overview_progress_ring.dart';
import '../../widgets/overview_mini_progress_row.dart';
import '../../widgets/overview_stat_card.dart';
import '../../widgets/overview_day_strip.dart';
import '../../widgets/overview_timeline_block.dart';

enum OverviewMode { month, schedule }

class OverviewView extends StatefulWidget {
  final List<GoalModel> goals;
  final List<HabitModel> habits;
  final List<TaskModel> tasks;

  const OverviewView({
    super.key,
    required this.goals,
    required this.habits,
    required this.tasks,
  });

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  OverviewMode _mode = OverviewMode.month;

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
  static const _timelineHours = [
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
  ];

  List<DateTime> get _currentWeekDays {
    // weekday: Monday = 1 ... Sunday = 7
    // subtracting (weekday - 1) days always lands on that week's Monday
    final weekStart = _selectedDay.subtract(
      Duration(days: _selectedDay.weekday - 1),
    );
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  void _goToPreviousWeek() => setState(
    () => _selectedDay = _selectedDay.subtract(const Duration(days: 7)),
  );
  void _goToNextWeek() =>
      setState(() => _selectedDay = _selectedDay.add(const Duration(days: 7)));

  late DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  late DateTime _selectedDay = DateTime.now();

  void _goToPreviousMonth() {
    setState(
      () => _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      ),
    );
  }

  void _goToNextMonth() {
    setState(
      () => _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Converts each goal's targetDate String into a DateTime, skipping any
  // that fail to parse (e.g. "No date").
  Set<DateTime> get _goalDeadlineDays {
    final dates = <DateTime>{};
    for (final goal in widget.goals) {
      try {
        dates.add(DateTime.parse(goal.targetDate));
      } catch (_) {
        // not a valid date string — skip it
      }
    }
    return dates;
  }

  Set<DateTime> get _taskDueDays {
    final dates = <DateTime>{};
    for (final task in widget.tasks) {
      try {
        dates.add(DateTime.parse(task.dueDate));
      } catch (_) {
        // "No date" or invalid — skip it
      }
    }
    return dates;
  }

  List<TaskModel> get _tasksDueOnSelectedDay {
    return widget.tasks.where((t) {
      try {
        return _isSameDay(DateTime.parse(t.dueDate), _selectedDay);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  double get _goalsProgress {
    if (widget.goals.isEmpty) return 0;
    final total = widget.goals.fold<double>(0, (sum, g) => sum + g.progress);
    return total / widget.goals.length;
  }

  double get _habitsProgress {
    if (widget.habits.isEmpty) return 0;
    final completed = widget.habits.where((h) => h.isCompletedToday).length;
    return completed / widget.habits.length;
  }

  double get _tasksProgress {
    if (widget.tasks.isEmpty) return 0;
    final completed = widget.tasks.where((t) => t.isCompleted).length;
    return completed / widget.tasks.length;
  }

  double get _overallProgress =>
      (_goalsProgress + _habitsProgress + _tasksProgress) / 3;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (_mode == OverviewMode.month) ...[
            _buildOverallProgressCard(),
            const SizedBox(height: 16),
            _buildStatCardsRow(),
            const SizedBox(height: 16),
            OverviewCalendarCard(
              displayedMonth: _displayedMonth,
              selectedDay: _selectedDay,
              goalDeadlineDays: _goalDeadlineDays,
              taskDueDays: _taskDueDays,
              onDaySelected: (day) => setState(() => _selectedDay = day),
              onPreviousMonth: _goToPreviousMonth,
              onNextMonth: _goToNextMonth,
            ),
            const SizedBox(height: 20),
            OverviewTodaySection(tasksDueOnSelectedDay: _tasksDueOnSelectedDay),
          ] else ...[
            _buildScheduleSection(), // NEW
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OverviewNavArrow(
              icon: Icons.chevron_left,
              onTap: _goToPreviousWeek,
            ),
            Text(
              '${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
            OverviewNavArrow(icon: Icons.chevron_right, onTap: _goToNextWeek),
          ],
        ),
        const SizedBox(height: 12),
        OverviewDayStrip(
          days: _currentWeekDays,
          selectedDay: _selectedDay,
          markedDays: {..._goalDeadlineDays, ..._taskDueDays},
          onDaySelected: (day) => setState(() => _selectedDay = day),
        ),
        const SizedBox(height: 20),
        _buildTimeline(),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: _timelineHours.map((hour) {
        final events = _eventsAtHour(hour);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: context.borderColor, height: 1),
                    if (events.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...events,
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Collects every habit/task block that belongs at this specific hour.
  List<Widget> _eventsAtHour(int hour) {
    final blocks = <Widget>[];

    // Habits recur daily, so they show at their scheduled hour every day.
    for (final habit in widget.habits) {
      if (habit.scheduledHour == hour) {
        blocks.add(
          OverviewTimelineBlock(
            emoji: habit.emoji,
            title: habit.title,
            status: habit.isCompletedToday
                ? '✓ Completed'
                : '🔥 ${habit.streak}-day streak',
            color: habit.color,
          ),
        );
      }
    }

    // Tasks only show on their exact due date.
    for (final task in widget.tasks) {
      if (task.scheduledHour == hour) {
        try {
          if (_isSameDay(DateTime.parse(task.dueDate), _selectedDay)) {
            blocks.add(
              OverviewTimelineBlock(
                emoji: '✅',
                title: task.title,
                status: task.isCompleted ? '✓ Done' : 'Due today',
                color: task.isCompleted ? Colors.green : Colors.blueGrey,
              ),
            );
          }
        } catch (_) {
          // dueDate wasn't a valid date string — skip it
        }
      }
    }

    return blocks;
  }

  Widget _buildHeader() {
    final isSchedule = _mode == OverviewMode.schedule;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSchedule ? 'Schedule' : 'Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSchedule
                    ? '${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year}'
                    : 'Your progress at a glance 📊',
                style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cardBgAlt,
            borderRadius: BorderRadius.circular(20),
            border: context.isDark ? Border.all(color: context.borderColor) : null,
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              OverviewModeChip(
                label: 'Month',
                selected: _mode == OverviewMode.month,
                onTap: () => setState(() => _mode = OverviewMode.month),
              ),
              OverviewModeChip(
                label: 'Schedule',
                selected: _mode == OverviewMode.schedule,
                onTap: () => setState(() => _mode = OverviewMode.schedule),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: context.isDark ? Border.all(color: context.borderColor) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OverviewProgressRing(percent: _overallProgress),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Across all 3 categories',
                  style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                ),
                const SizedBox(height: 12),
                OverviewMiniProgressRow(
                  label: '🎯 Goals',
                  percent: _goalsProgress,
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(height: 8),
                OverviewMiniProgressRow(
                  label: '🔥 Habits',
                  percent: _habitsProgress,
                  color: const Color(0xFFF97316),
                ),
                const SizedBox(height: 8),
                OverviewMiniProgressRow(
                  label: '✅ To-Do',
                  percent: _tasksProgress,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardsRow() {
    return Row(
      children: [
        Expanded(
          child: OverviewStatCard(
            emoji: '🎯',
            percent: _goalsProgress,
            label: 'Goals',
            subtext: '${widget.goals.length} active',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OverviewStatCard(
            emoji: '🔥',
            percent: _habitsProgress,
            label: 'Habits',
            subtext:
                '${widget.habits.where((h) => h.isCompletedToday).length}/${widget.habits.length} today',
            color: const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OverviewStatCard(
            emoji: '✅',
            percent: _tasksProgress,
            label: 'To-Do',
            subtext:
                '${widget.tasks.where((t) => t.isCompleted).length}/${widget.tasks.length} done',
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}
