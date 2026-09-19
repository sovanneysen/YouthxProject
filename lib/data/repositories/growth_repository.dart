import 'dart:math';

import 'package:flutter/material.dart';

import '../../modules/growth_center/models/goal_model.dart';
import '../../modules/growth_center/models/habit_model.dart';
import '../../modules/growth_center/models/task_model.dart';

/// Growth Center data access. Implementations may be backed by the real
/// Draft Backend (`RestGrowthRepository`) or stay fully in-memory
/// (`MockGrowthRepository`, used by widget tests so no HTTP happens inside
/// the test harness).
abstract class GrowthRepository {
  Future<List<GoalModel>> fetchGoals();
  Future<GoalModel> createGoal(GoalModel goal);
  Future<GoalModel> updateGoal(GoalModel goal);
  Future<void> deleteGoal(String id);

  Future<List<HabitModel>> fetchHabits();
  Future<HabitModel> createHabit(HabitModel habit);
  Future<HabitModel> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);
  Future<HabitModel> completeHabit(HabitModel habit);
  Future<HabitModel> uncompleteHabit(HabitModel habit);

  Future<List<TaskModel>> fetchTasks();
  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
}

/// In-memory growth data with the same contract as the backend, used by
/// widget tests to keep the app shell offline while exercising real
/// controller/view logic.
class MockGrowthRepository implements GrowthRepository {
  final _rand = Random();
  final List<GoalModel> _goals = [];
  final List<HabitModel> _habits = [];
  final List<TaskModel> _tasks = [];

  MockGrowthRepository() {
    _seed();
  }

  void _seed() {
    _goals.addAll([
      GoalModel(
        id: _newId(),
        emoji: '📚',
        title: 'Read 30 min daily',
        category: GoalCategory.learning,
        targetDate: '2026-09-01',
        progress: 0.7,
        hasReminder: true,
        reminderTime: '8:00 AM',
      ),
      GoalModel(
        id: _newId(),
        emoji: '💪',
        title: 'Exercise 3x/week',
        category: GoalCategory.health,
        targetDate: '2026-08-01',
        progress: 0.5,
      ),
    ]);

    _habits.addAll([
      HabitModel(
        id: _newId(),
        emoji: '📓',
        title: 'Morning journal',
        frequency: HabitFrequency.daily,
        streak: 12,
        color: const Color(0xFF6366F1),
        isCompletedToday: true,
        scheduledHour: 8,
      ),
      HabitModel(
        id: _newId(),
        emoji: '💧',
        title: 'Drink 2L water',
        frequency: HabitFrequency.daily,
        streak: 5,
        color: const Color(0xFF3B82F6),
        scheduledHour: 9,
      ),
    ]);

    _tasks.addAll([
      TaskModel(
        id: _newId(),
        title: 'Submit assignment',
        priority: TaskPriority.high,
        dueDate: '2026-06-25',
      ),
      TaskModel(
        id: _newId(),
        title: 'Call mom',
        priority: TaskPriority.medium,
        dueDate: '2026-06-27',
      ),
    ]);
  }

  String _newId() => 'g${_rand.nextInt(1 << 31)}';

  @override
  Future<List<GoalModel>> fetchGoals() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<GoalModel>.from(_goals);
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final created = GoalModel(
      id: _newId(),
      emoji: goal.emoji,
      title: goal.title,
      category: goal.category,
      customCategoryLabel: goal.customCategoryLabel,
      targetDate: goal.targetDate,
      progress: goal.progress,
      hasReminder: goal.hasReminder,
      reminderTime: goal.reminderTime,
    );
    _goals.add(created);
    return created;
  }

  @override
  Future<GoalModel> updateGoal(GoalModel goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) _goals[index] = goal;
    return goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
  }

  @override
  Future<List<HabitModel>> fetchHabits() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<HabitModel>.from(_habits);
  }

  @override
  Future<HabitModel> createHabit(HabitModel habit) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final created = HabitModel(
      id: _newId(),
      emoji: habit.emoji,
      title: habit.title,
      frequency: habit.frequency,
      streak: habit.streak,
      color: habit.color,
      isCompletedToday: habit.isCompletedToday,
      scheduledHour: habit.scheduledHour,
    );
    _habits.add(created);
    return created;
  }

  @override
  Future<HabitModel> updateHabit(HabitModel habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) _habits[index] = habit;
    return habit;
  }

  @override
  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
  }

  @override
  Future<HabitModel> completeHabit(HabitModel habit) async {
    final updated = HabitModel(
      id: habit.id,
      emoji: habit.emoji,
      title: habit.title,
      frequency: habit.frequency,
      streak: habit.isCompletedToday ? habit.streak : habit.streak + 1,
      color: habit.color,
      isCompletedToday: true,
      scheduledHour: habit.scheduledHour,
    );
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) _habits[index] = updated;
    return updated;
  }

  @override
  Future<HabitModel> uncompleteHabit(HabitModel habit) async {
    final updated = HabitModel(
      id: habit.id,
      emoji: habit.emoji,
      title: habit.title,
      frequency: habit.frequency,
      streak: max(0, habit.streak - 1),
      color: habit.color,
      isCompletedToday: false,
      scheduledHour: habit.scheduledHour,
    );
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) _habits[index] = updated;
    return updated;
  }

  @override
  Future<List<TaskModel>> fetchTasks() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<TaskModel>.from(_tasks);
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final created = TaskModel(
      id: _newId(),
      title: task.title,
      priority: task.priority,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
    );
    _tasks.add(created);
    return created;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) _tasks[index] = task;
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
  }
}