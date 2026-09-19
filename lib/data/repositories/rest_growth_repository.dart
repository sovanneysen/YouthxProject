import 'package:flutter/material.dart';

import '../../modules/growth_center/models/goal_model.dart';
import '../../modules/growth_center/models/habit_model.dart';
import '../../modules/growth_center/models/task_model.dart';
import '../providers/api_provider.dart';
import 'growth_repository.dart';

/// REST-backed Growth Center repository.
///
/// Contract verified from the Draft Backend:
///
///   GET    /goals            -> `List<GoalResponse>`
///   POST   /goals            -> 201 GoalResponse (owner from JWT)
///   PUT    /goals/{id}       -> 200 GoalResponse (owner only)
///   DELETE /goals/{id}       -> 204
///
///   GET    /habits                -> `List<HabitResponse>`
///   POST   /habits                -> 201 HabitResponse
///   PUT    /habits/{id}           -> 200 HabitResponse
///   DELETE /habits/{id}           -> 204
///   POST   /habits/{id}/complete  -> 200 HabitResponse (streak grows)
///   POST   /habits/{id}/uncomplete-> 200 HabitResponse
///
///   GET    /todos            -> `List<TodoResponse>`
///   POST   /todos            -> 201 TodoResponse
///   PUT    /todos/{id}       -> 200 TodoResponse
///   DELETE /todos/{id}       -> 204
///
/// Not persisted by the backend (schema has no columns):
///   - Goal numeric tracking (targetAmount/currentAmount/unit)
///   - Task scheduledHour
/// These fields round-trip to the nearest supported representation.
class RestGrowthRepository implements GrowthRepository {
  RestGrowthRepository({ApiProvider? apiProvider})
    : _api = apiProvider ?? ApiProvider();

  final ApiProvider _api;

  // ── Goals ────────────────────────────────────────────────

  Future<List<GoalModel>> fetchGoals() async {
    final data = await _api.get('/goals');
    final list = data is List ? data : const <dynamic>[];
    return list.map((e) => _toGoal(e as Map<String, dynamic>)).toList();
  }

  Future<GoalModel> createGoal(GoalModel goal) async {
    final data = await _api.post('/goals', {
      'name': goal.title,
      'category': _goalCategoryString(goal),
      'targetDate': _parseDateOrNull(goal.targetDate),
      'progressPercent': (goal.effectiveProgress.clamp(0.0, 1.0) * 100).round(),
      'dailyReminderTime': _reminderTime(goal.reminderTime),
    });
    return _toGoal(data as Map<String, dynamic>);
  }

  Future<GoalModel> updateGoal(GoalModel goal) async {
    final data = await _api.put('/goals/${goal.id}', {
      'name': goal.title,
      'category': _goalCategoryString(goal),
      'targetDate': _parseDateOrNull(goal.targetDate),
      'progressPercent': (goal.effectiveProgress.clamp(0.0, 1.0) * 100).round(),
      'dailyReminderTime': _reminderTime(goal.reminderTime),
    });
    return _toGoal(data as Map<String, dynamic>);
  }

  Future<void> deleteGoal(String id) async {
    await _api.delete('/goals/$id');
  }

  // ── Habits ──────────────────────────────────────────────

  Future<List<HabitModel>> fetchHabits() async {
    final data = await _api.get('/habits');
    final list = data is List ? data : const <dynamic>[];
    return list.map((e) => _toHabit(e as Map<String, dynamic>)).toList();
  }

  Future<HabitModel> createHabit(HabitModel habit) async {
    final data = await _api.post('/habits', _habitBody(habit));
    return _toHabit(data as Map<String, dynamic>);
  }

  Future<HabitModel> updateHabit(HabitModel habit) async {
    final data = await _api.put('/habits/${habit.id}', _habitBody(habit));
    return _toHabit(data as Map<String, dynamic>);
  }

  Future<void> deleteHabit(String id) async {
    await _api.delete('/habits/$id');
  }

  Future<HabitModel> completeHabit(HabitModel habit) async {
    final data = await _api.post('/habits/${habit.id}/complete', const {});
    return _toHabit(data as Map<String, dynamic>);
  }

  Future<HabitModel> uncompleteHabit(HabitModel habit) async {
    final data = await _api.post('/habits/${habit.id}/uncomplete', const {});
    return _toHabit(data as Map<String, dynamic>);
  }

  // ── Tasks ───────────────────────────────────────────────

  Future<List<TaskModel>> fetchTasks() async {
    final data = await _api.get('/todos');
    final list = data is List ? data : const <dynamic>[];
    return list.map((e) => _toTask(e as Map<String, dynamic>)).toList();
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final data = await _api.post('/todos', _taskBody(task));
    return _toTask(data as Map<String, dynamic>);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final data = await _api.put('/todos/${task.id}', _taskBody(task));
    return _toTask(data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    await _api.delete('/todos/$id');
  }

  // ── Mapping ─────────────────────────────────────────────

  GoalModel _toGoal(Map<String, dynamic> json) {
    final String rawId = json['id'].toString();
    return GoalModel(
      id: rawId,
      emoji: _goalEmoji(json['category'] as String?),
      title: json['name'] as String? ?? '',
      category: _goalCategory(json['category'] as String?),
      targetDate: json['targetDate'] is String ? json['targetDate'] as String : '',
      progress: ((json['progressPercent'] as num?) ?? 0) / 100.0,
      hasReminder: json['dailyReminderTime'] != null,
      reminderTime: _formatReminder(json['dailyReminderTime']),
    );
  }

  HabitModel _toHabit(Map<String, dynamic> json) {
    final rawId = json['id'].toString();
    final completedAt = json['lastCompletedAt'] as String?;
    final today = DateTime.now();
    final isToday = completedAt != null && completedAt.startsWith(_dash(today));

    return HabitModel(
      id: rawId,
      emoji: json['emoji'] as String? ?? '✅',
      title: json['name'] as String? ?? '',
      frequency: (json['frequency'] as String?) == 'weekly'
          ? HabitFrequency.weekly
          : HabitFrequency.daily,
      streak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      color: _color(json['color']),
      isCompletedToday: isToday,
      scheduledHour: _hourOf(json['timeOfDay']),
    );
  }

  TaskModel _toTask(Map<String, dynamic> json) {
    final rawId = json['id'].toString();
    return TaskModel(
      id: rawId,
      title: json['title'] as String? ?? '',
      priority: _priority(json['priority'] as String?),
      dueDate: json['dueDate'] is String ? json['dueDate'] as String : 'No date',
      isCompleted: json['isCompleted'] == true,
    );
  }

  Map<String, dynamic> _habitBody(HabitModel habit) => {
        'name': habit.title,
        'emoji': habit.emoji,
        'color': _colorString(habit.color),
        'frequency': habit.frequency.name,
        'timeOfDay': habit.scheduledHour == null
            ? null
            : '${_pad(habit.scheduledHour!)}:00:00',
      };

  Map<String, dynamic> _taskBody(TaskModel task) => {
        'title': task.title,
        'priority': task.priority.name,
        'dueDate': _parseDateOrNull(task.dueDate),
        'isCompleted': task.isCompleted,
      };

  String _dash(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_pad(d.month)}-${_pad(d.day)}';

  String _pad(int n) => n.toString().padLeft(2, '0');

  GoalCategory _goalCategory(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    return GoalCategory.values.firstWhere(
      (c) => c.name == value || _goalLabel(c).toLowerCase() == value,
      orElse: () => GoalCategory.other,
    );
  }

  String _goalCategoryString(GoalModel goal) {
    if (goal.category == GoalCategory.other &&
        (goal.customCategoryLabel?.trim().isNotEmpty ?? false)) {
      return goal.customCategoryLabel!.trim();
    }
    return _goalLabel(goal.category);
  }

  String _goalLabel(GoalCategory c) => switch (c) {
        GoalCategory.health => 'Health',
        GoalCategory.finance => 'Finance',
        GoalCategory.career => 'Career',
        GoalCategory.learning => 'Learning',
        GoalCategory.social => 'Social',
        GoalCategory.mindset => 'Mindset',
        GoalCategory.other => 'Other',
      };

  String _goalEmoji(String? raw) => switch (_goalCategory(raw)) {
        GoalCategory.health => '💪',
        GoalCategory.finance => '💰',
        GoalCategory.career => '💼',
        GoalCategory.learning => '📚',
        GoalCategory.social => '👥',
        GoalCategory.mindset => '🧘',
        GoalCategory.other => '✏️',
      };

  Color _color(String? raw) {
    if (raw == null || !raw.startsWith('#')) return const Color(0xFF6366F1);
    final hex = int.tryParse(raw.substring(1), radix: 16);
    return hex == null ? const Color(0xFF6366F1) : Color(0xFF000000 | hex);
  }

  String _colorString(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return '#$value';
  }

  TaskPriority _priority(String? raw) => switch (raw?.toLowerCase()) {
        'high' => TaskPriority.high,
        'low' => TaskPriority.low,
        _ => TaskPriority.medium,
      };

  int? _hourOf(String? timeOfDay) {
    if (timeOfDay == null) return null;
    final parts = timeOfDay.split(':');
    return parts.isEmpty ? null : int.tryParse(parts.first);
  }

  String? _formatReminder(String? timeOfDay) {
    if (timeOfDay == null) return null;
    final parts = timeOfDay.split(':');
    if (parts.isEmpty) return null;
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${_pad(h12)}:${_pad(minute)} $suffix';
  }

  String? _reminderTime(String? friendly) {
    if (friendly == null || friendly.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(friendly);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    return '${_pad(hour)}:${_pad(minute)}:00';
  }

  String? _parseDateOrNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'No date') return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
    if (match == null) return null;
    return trimmed.substring(0, 10);
  }
}