import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/growth_controller.dart';
import '../models/goal_model.dart';
import '../models/habit_model.dart';
import '../models/task_model.dart';
import '../views/habits_view.dart';
import '../views/overview/overview_view.dart';
import '../views/todo/todo_view.dart';
import 'goals_view.dart';
import '../widgets/growth_header.dart';
import '../widgets/growth_tab_bar.dart';

class GrowthView extends StatelessWidget {
  const GrowthView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrowthController>();
    return _GrowthScreen(controller: controller);
  }
}

class _GrowthScreen extends StatefulWidget {
  final GrowthController controller;

  const _GrowthScreen({required this.controller});

  @override
  State<_GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<_GrowthScreen> {
  int _activeTab = 0;

  final _tabs = const [
    GrowthTab(emoji: '🎯', label: 'Goals', activeColor: Color(0xFF6366F1)),
    GrowthTab(emoji: '🔥', label: 'Habits', activeColor: Color(0xFFF97316)),
    GrowthTab(emoji: '✅', label: 'To-Do', activeColor: Color(0xFF10B981)),
    GrowthTab(emoji: '📊', label: 'Overview', activeColor: Color(0xFF3B82F6)),
  ];

  final _badgeEmojis = ['🎯', '🔥', '✅', '📊'];
  final _badgeColors = [
    const Color(0xFFF3E8FF),
    const Color(0xFFFFEDD5),
    const Color(0xFFD1FAE5),
    const Color(0xFFDBEAFE),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
            Expanded(child: _buildBody(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(GrowthController controller) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final error = controller.error.value;
      if (error != null) {
        return _ErrorView(message: error, onRetry: controller.loadAll);
      }

      final goals = List<GoalModel>.from(controller.goals);
      final habits = List<HabitModel>.from(controller.habits);
      final tasks = List<TaskModel>.from(controller.tasks);
      return IndexedStack(
        index: _activeTab,
        children: [
          GoalsView(
            goals: goals,
            onAdd: (g) => controller.addGoal(g),
            onUpdate: (g) => controller.updateGoal(g),
            onDelete: (g) => controller.deleteGoal(g),
          ),
          HabitsView(
            habits: habits,
            onAdd: (h) => controller.addHabit(h),
            onUpdate: (h) => controller.updateHabit(h),
            onDelete: (h) => controller.deleteHabit(h),
            onToggle: (id, value) => controller.toggleHabit(id, value),
          ),
          TodoView(
            tasks: tasks,
            onAdd: (t) => controller.addTask(t),
            onUpdate: (t) => controller.updateTask(t),
            onDelete: (t) => controller.deleteTask(t),
            onToggle: (t, v) => controller.toggleTask(t, v),
          ),
          OverviewView(goals: goals, habits: habits, tasks: tasks),
          const Center(
            child: Text(
              'Overview — coming next',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    });
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}