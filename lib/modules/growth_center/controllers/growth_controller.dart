import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../data/repositories/growth_repository.dart';
import '../models/goal_model.dart';
import '../models/habit_model.dart';
import '../models/task_model.dart';

/// Manages the Growth Center's three lists (goals, habits, tasks) backed by
/// the real Draft Backend.
class GrowthController extends GetxController {
  final GrowthRepository repository;

  GrowthController({required this.repository});

  final RxList<GoalModel> goals = <GoalModel>[].obs;
  final RxList<HabitModel> habits = <HabitModel>[].obs;
  final RxList<TaskModel> tasks = <TaskModel>[].obs;
  final RxBool loading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait<Object?>([
        repository.fetchGoals(),
        repository.fetchHabits(),
        repository.fetchTasks(),
      ]);
      goals.assignAll((results[0] as List<GoalModel>));
      habits.assignAll((results[1] as List<HabitModel>));
      tasks.assignAll((results[2] as List<TaskModel>));
      // Loading indicator would flash too quickly on fast networks.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'Could not load your growth data.';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> addGoal(GoalModel goal) async {
    try {
      final created = await repository.createGoal(goal);
      goals.add(created);
      return true;
    } catch (e) {
      _showError('Could not add the goal', e);
      return false;
    }
  }

  Future<bool> updateGoal(GoalModel goal) async {
    try {
      final updated = await repository.updateGoal(goal);
      final index = goals.indexWhere((g) => g.id == updated.id);
      if (index != -1) goals[index] = updated;
      return true;
    } catch (e) {
      _showError('Could not update the goal', e);
      return false;
    }
  }

  Future<bool> deleteGoal(GoalModel goal) async {
    try {
      await repository.deleteGoal(goal.id);
      goals.removeWhere((g) => g.id == goal.id);
      return true;
    } catch (e) {
      _showError('Could not delete the goal', e);
      return false;
    }
  }

  Future<bool> addHabit(HabitModel habit) async {
    try {
      final created = await repository.createHabit(habit);
      habits.add(created);
      return true;
    } catch (e) {
      _showError('Could not add the habit', e);
      return false;
    }
  }

  Future<bool> updateHabit(HabitModel habit) async {
    try {
      final updated = await repository.updateHabit(habit);
      final index = habits.indexWhere((h) => h.id == updated.id);
      if (index != -1) habits[index] = updated;
      return true;
    } catch (e) {
      _showError('Could not update the habit', e);
      return false;
    }
  }

  Future<bool> deleteHabit(HabitModel habit) async {
    try {
      await repository.deleteHabit(habit.id);
      habits.removeWhere((h) => h.id == habit.id);
      return true;
    } catch (e) {
      _showError('Could not delete the habit', e);
      return false;
    }
  }

  /// Persists today's completion toggle on the backend, then mirrors the
  /// returned streak/lastCompletedAt into the list.
  Future<void> toggleHabit(String id, bool value) async {
    final index = habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    final habit = habits[index];
    try {
      final updated = value
          ? await repository.completeHabit(habit)
          : await repository.uncompleteHabit(habit);
      if (index < habits.length) habits[index] = updated;
    } catch (e) {
      _showError('Could not update the habit', e);
    }
  }

  Future<bool> addTask(TaskModel task) async {
    try {
      final created = await repository.createTask(task);
      tasks.add(created);
      return true;
    } catch (e) {
      _showError('Could not add the task', e);
      return false;
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    try {
      final updated = await repository.updateTask(task);
      final index = tasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) tasks[index] = updated;
      return true;
    } catch (e) {
      _showError('Could not update the task', e);
      return false;
    }
  }

  Future<bool> deleteTask(TaskModel task) async {
    try {
      await repository.deleteTask(task.id);
      tasks.removeWhere((t) => t.id == task.id);
      return true;
    } catch (e) {
      _showError('Could not delete the task', e);
      return false;
    }
  }

  Future<void> toggleTask(TaskModel task, bool? value) async {
    final updated = TaskModel(
      id: task.id,
      title: task.title,
      priority: task.priority,
      dueDate: task.dueDate,
      isCompleted: value ?? false,
    );
    try {
      await repository.updateTask(updated);
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) tasks[index] = updated;
    } catch (e) {
      _showError('Could not update the task', e);
    }
  }

  void _showError(String title, Object error) {
    Get.snackbar(
      title,
      error is ApiException ? error.message : 'Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }
}