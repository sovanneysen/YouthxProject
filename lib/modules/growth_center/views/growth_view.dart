import 'package:flutter/material.dart';
import 'package:youthx/modules/growth_center/models/goal_model.dart';
import 'package:youthx/modules/growth_center/models/habit_model.dart';
import 'package:youthx/modules/growth_center/models/task_model.dart';
import 'package:youthx/modules/growth_center/views/habits_view.dart';
import 'package:youthx/modules/growth_center/views/overview/overview_view.dart';
import 'package:youthx/modules/growth_center/views/todo/todo_view.dart';
import 'goals_view.dart';
import '../widgets/growth_header.dart';
import '../widgets/growth_tab_bar.dart';

class GrowthView extends StatefulWidget {
  const GrowthView({super.key});

  @override
  State<GrowthView> createState() => _GrowthViewState();
}

class _GrowthViewState extends State<GrowthView> {
  int _activeTab = 0;

  final _tabs = const [
    GrowthTab(emoji: '🎯', label: 'Goals', activeColor: Color(0xFF6366F1)),
    GrowthTab(emoji: '🔥', label: 'Habits', activeColor: Color(0xFFF97316)),
    GrowthTab(emoji: '✅', label: 'To-Do', activeColor: Color(0xFF10B981)),
    GrowthTab(emoji: '📊', label: 'Overview', activeColor: Color(0xFF3B82F6)),
  ];

  static const _badgeEmojis = ['🎯', '🔥', '✅', '📊'];
  static const _badgeColors = [
    Color(0xFFF3E8FF),
    Color(0xFFFFEDD5),
    Color(0xFFD1FAE5),
    Color(0xFFDBEAFE),
  ];

  // ─────────────────────────────────────────────
  // ALL DATA NOW LIVES HERE (moved from each view)
  // ─────────────────────────────────────────────

  final List<GoalModel> _goals = [
    GoalModel(
      id: '1',
      emoji: '📚',
      title: 'Read 30 min daily',
      category: GoalCategory.learning,
      targetDate: '2026-09-01',
      progress: 0.70,
      hasReminder: true,
      reminderTime: '8:00 AM',
    ),
    GoalModel(
      id: '2',
      emoji: '💪',
      title: 'Exercise 3x/week',
      category: GoalCategory.health,
      targetDate: '2026-08-01',
      progress: 0.50,
    ),
    GoalModel(
      id: '3',
      emoji: '💰',
      title: 'Save \$200/month',
      category: GoalCategory.finance,
      targetDate: '2026-12-31',
      progress: 0.85,
      hasReminder: true,
      reminderTime: '8:00 AM',
      targetAmount: 200,
      currentAmount: 170,
      unit: '\$',
    ),
    GoalModel(
      id: '4',
      emoji: '💼',
      title: 'Apply to 5 internships',
      category: GoalCategory.career,
      targetDate: '2026-07-15',
      progress: 0.40,
    ),
  ];

  final List<HabitModel> _habits = [
    const HabitModel(
      id: '1',
      emoji: '📓',
      title: 'Morning journal',
      frequency: HabitFrequency.daily,
      streak: 12,
      color: Color(0xFF6366F1),
      isCompletedToday: true,
      scheduledHour: 8, // NEW
    ),
    const HabitModel(
      id: '2',
      emoji: '💧',
      title: 'Drink 2L water',
      frequency: HabitFrequency.daily,
      streak: 5,
      color: Color(0xFF3B82F6),
      scheduledHour: 9, // NEW
    ),
    const HabitModel(
      id: '3',
      emoji: '🌙',
      title: 'No screen 1hr before bed',
      frequency: HabitFrequency.daily,
      streak: 3,
      color: Color(0xFFA855F7),
      scheduledHour: 10, // NEW
    ),
    const HabitModel(
      id: '4',
      emoji: '🏋️',
      title: 'Weekly workout recap',
      frequency: HabitFrequency.weekly,
      streak: 8,
      color: Color(0xFF10B981),
      isCompletedToday: true,
      // no scheduledHour — won't show on timeline, matches screenshot
    ),
    const HabitModel(
      id: '5',
      emoji: '📖',
      title: 'Read book',
      frequency: HabitFrequency.daily,
      streak: 1,
      color: Color(0xFFF59E0B),
      isCompletedToday: true,
      scheduledHour: 7,
    ),
  ];

  final List<TaskModel> _tasks = [
    TaskModel(
      id: '1',
      title: 'Submit assignment by 11:59 PM',
      priority: TaskPriority.high,
      dueDate: '2026-06-25',
    ),
    TaskModel(
      id: '2',
      title: 'Reply to recruiter email',
      priority: TaskPriority.medium,
      dueDate: '2026-06-26',
    ),
    TaskModel(
      id: '3',
      title: 'Grocery run — oat milk + greens',
      priority: TaskPriority.low,
      dueDate: '2026-06-25',
      isCompleted: true,
      scheduledHour: 16, // NEW — matches the 16:00 slot in your screenshot
    ),
    TaskModel(
      id: '4',
      title: 'Call mom',
      priority: TaskPriority.medium,
      dueDate: '2026-06-27',
    ),
  ];

  // ─────────────────────────────────────────────
  // GOALS callbacks — passed down to GoalsView
  // ─────────────────────────────────────────────
  void _addGoal(GoalModel goal) => setState(() => _goals.add(goal));

  void _updateGoal(GoalModel updated) {
    setState(() {
      final index = _goals.indexWhere((g) => g.id == updated.id);
      _goals[index] = updated;
    });
  }

  void _deleteGoal(GoalModel goal) {
    setState(() => _goals.removeWhere((g) => g.id == goal.id));
  }

  // ─────────────────────────────────────────────
  // HABITS callbacks — passed down to HabitsView
  // ─────────────────────────────────────────────
  void _addHabit(HabitModel habit) => setState(() => _habits.add(habit));

  void _updateHabit(HabitModel updated) {
    setState(() {
      final index = _habits.indexWhere((h) => h.id == updated.id);
      _habits[index] = updated;
    });
  }

  void _deleteHabit(HabitModel habit) {
    setState(() => _habits.removeWhere((h) => h.id == habit.id));
  }

  void _toggleHabit(String id, bool value) {
    setState(() {
      final index = _habits.indexWhere((h) => h.id == id);
      _habits[index] = _habits[index].copyWith(isCompletedToday: value);
    });
  }

  // ─────────────────────────────────────────────
  // TASKS callbacks — passed down to TodoView
  // ─────────────────────────────────────────────
  void _addTask(TaskModel task) => setState(() => _tasks.add(task));

  void _updateTask(TaskModel updated) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updated.id);
      _tasks[index] = updated;
    });
  }

  void _deleteTask(TaskModel task) {
    setState(() => _tasks.removeWhere((t) => t.id == task.id));
  }

  void _toggleTask(TaskModel task, bool? value) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      _tasks[index] = TaskModel(
        id: task.id,
        title: task.title,
        priority: task.priority,
        dueDate: task.dueDate,
        isCompleted: value ?? false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  GrowthHeader(
                    badgeEmoji: _badgeEmojis[_activeTab],
                    badgeBackground: _badgeColors[_activeTab],
                  ),
                  GrowthTabBar(
                    tabs: _tabs,
                    activeIndex: _activeTab,
                    onTabSelected: (i) => setState(() => _activeTab = i),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _activeTab,
                children: [
                  GoalsView(
                    goals: _goals,
                    onAdd: _addGoal,
                    onUpdate: _updateGoal,
                    onDelete: _deleteGoal,
                  ),
                  HabitsView(
                    habits: _habits,
                    onAdd: _addHabit,
                    onUpdate: _updateHabit,
                    onDelete: _deleteHabit,
                    onToggle: _toggleHabit,
                  ),
                  TodoView(
                    tasks: _tasks,
                    onAdd: _addTask,
                    onUpdate: _updateTask,
                    onDelete: _deleteTask,
                    onToggle: _toggleTask,
                  ),
                  OverviewView(goals: _goals, habits: _habits, tasks: _tasks),
                  _placeholder('Overview — coming next'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String t) => Center(
    child: Text(t, style: const TextStyle(color: Colors.grey)),
  );
}
