import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:youthx/core/theme/app_theme.dart';
import '../../utils/task_priority_style.dart';
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
  static final DateFormat _longDay = DateFormat('EEEE, d MMMM');
  static final DateFormat _dayStripLabel = DateFormat('EEE, d MMM');

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

  /// To-dos due on the selected day that have no time attached.
  ///
  /// The backend stores a to-do as a bare `dueDate` (a LocalDate) and never
  /// sends a time, so `TaskModel.scheduledHour` is null for every real task.
  /// Those tasks can therefore never match the hourly timeline, which used to
  /// make a day that clearly had a due to-do look empty.
  List<TaskModel> get _untimedTasksOnSelectedDay =>
      _tasksDueOnSelectedDay.where((t) => t.scheduledHour == null).toList();

  /// To-dos due on the selected day that do carry a time, if any ever do.
  List<TaskModel> get _timedTasksOnSelectedDay =>
      _tasksDueOnSelectedDay.where((t) => t.scheduledHour != null).toList();

  /// Goals whose target date lands on the selected day.
  List<GoalModel> get _goalsDueOnSelectedDay => widget.goals.where((g) {
    try {
      return _isSameDay(DateTime.parse(g.targetDate), _selectedDay);
    } catch (_) {
      return false;
    }
  }).toList();

  /// True when at least one item can be placed in the hourly grid.
  ///
  /// Deliberately checks the data rather than the rendered widgets so the
  /// "nothing on this day" decision never depends on building a list of
  /// widgets to find out it is empty.
  bool get _hasTimelineEvents {
    final habitHours = widget.habits.map((h) => h.scheduledHour);
    if (habitHours.any(_timelineHours.contains)) return true;
    return _timedTasksOnSelectedDay
        .any((t) => _timelineHours.contains(t.scheduledHour));
  }

  /// True when the selected day has nothing at all to show.
  bool get _selectedDayIsEmpty =>
      _untimedTasksOnSelectedDay.isEmpty &&
      _goalsDueOnSelectedDay.isEmpty &&
      !_hasTimelineEvents;

  /// Heading for the selected day.
  ///
  /// "TODAY" is only correct for the real current day; for any other selected
  /// date it is a lie, so a real date is used instead.
  String get _selectedDayLabel {
    final now = DateTime.now();
    if (_isSameDay(_selectedDay, now)) return 'TODAY';
    if (_isSameDay(_selectedDay, now.add(const Duration(days: 1)))) {
      return 'TOMORROW';
    }
    if (_isSameDay(_selectedDay, now.subtract(const Duration(days: 1)))) {
      return 'YESTERDAY';
    }
    return _longDay.format(_selectedDay).toUpperCase();
  }

  /// Small uppercase heading, matching the existing "TODAY" style.
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.textSecondaryColor,
        letterSpacing: 1,
      ),
    ),
  );

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
            OverviewTodaySection(
              tasksDueOnSelectedDay: _tasksDueOnSelectedDay,
              label: _selectedDayLabel,
            ),
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
            // Date-aware: the selected day, not just the month, so switching
            // between days of the same month is visible.
            Text(
              _dayStripLabel.format(_selectedDay),
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
        // An "all day" list plus goal deadlines come first, so a to-do that the
        // backend stores without a time is never hidden behind an hourly grid.
        ..._buildUntimedSections(),
        if (_selectedDayIsEmpty)
          _buildEmptyDayState()
        else if (_hasTimelineEvents)
          _buildTimeline(),
      ],
    );
  }

  /// Sections for everything on the selected day that has no place in the
  /// hourly grid: to-dos without a time, and goal deadlines.
  ///
  /// Returns an empty list when there is nothing to add, so the schedule does
  /// not render stray headings.
  List<Widget> _buildUntimedSections() {
    final untimed = _untimedTasksOnSelectedDay;
    final goalDeadlines = _goalsDueOnSelectedDay;
    if (untimed.isEmpty && goalDeadlines.isEmpty) return const [];

    return [
      if (untimed.isNotEmpty) ...[
        _sectionLabel('ALL DAY · NO TIME SET'),
        for (final task in untimed)
          OverviewTimelineBlock(
            emoji: '✅',
            title: task.title,
            status: task.isCompleted
                ? '✓ Done · no time set'
                : '${TaskPriorityStyle.labelOf(task.priority)} priority · no '
                    'time set',
            color: task.isCompleted ? Colors.green : Colors.blueGrey,
          ),
        const SizedBox(height: 20),
      ],
      if (goalDeadlines.isNotEmpty) ...[
        _sectionLabel('GOAL DEADLINES'),
        for (final goal in goalDeadlines)
          OverviewTimelineBlock(
            emoji: goal.emoji,
            title: goal.title,
            status: goal.isNumericTracked
                ? 'Goal deadline · ${goal.amountLabel ?? 'no amount'}'
                : 'Goal deadline',
            color: const Color(0xFF6366F1),
          ),
        const SizedBox(height: 20),
      ],
    ];
  }

  /// Shown when the selected day genuinely has nothing on it, so the schedule
  /// never falls back to an empty 16-row timeline.
  Widget _buildEmptyDayState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(_selectedDayLabel),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border:
                context.isDark ? Border.all(color: context.borderColor) : null,
          ),
          child: Text(
            'Nothing scheduled for this day 🎉\n'
            'No to-dos, goal deadlines or timed habits on this date.',
            style: TextStyle(color: context.textSecondaryColor),
          ),
        ),
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
