import '../models/goal_model.dart';
import '../models/habit_model.dart';
import '../models/todo_model.dart';
import '../../core/theme/app_colors.dart';

class GrowthProvider {
  // Uncomment when backend is ready:
  // final Dio _dio = DioClient.instance;

  Future<List<GoalModel>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockGoals.map((json) => GoalModel.fromJson(json)).toList();

    // --- REAL API (uncomment once backend is ready) ---
    // final response = await _dio.get('/api/v1/growth/goals');
    // return (response.data as List)
    //     .map((json) => GoalModel.fromJson(json))
    //     .toList();
  }

  Future<List<HabitModel>> getHabits() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockHabits;

    // --- REAL API ---
    // final response = await _dio.get('/api/v1/growth/habits');
    // return (response.data as List).map((j) => HabitModel.fromJson(j)).toList();
  }

  Future<List<TodoModel>> getTodos() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockTodos.map((json) => TodoModel.fromJson(json)).toList();

    // --- REAL API ---
    // final response = await _dio.get('/api/v1/growth/todos');
    // return (response.data as List).map((j) => TodoModel.fromJson(j)).toList();
  }

  static final List<Map<String, dynamic>> _mockGoals = [
    {
      'id': 'g1',
      'title': 'Save \$500 emergency fund',
      'category': 'Finance',
      'emoji': '💰',
      'targetDate': '2026-09-30',
      'progress': 0.45,
    },
    {
      'id': 'g2',
      'title': 'Read 30 minutes daily',
      'category': 'Learning',
      'emoji': '📚',
      'targetDate': '2026-08-31',
      'progress': 0.7,
    },
    {
      'id': 'g3',
      'title': 'Run a 5K',
      'category': 'Health',
      'emoji': '💪',
      'targetDate': '2026-10-15',
      'progress': 0.2,
    },
  ];

  static final List<HabitModel> _mockHabits = [
    HabitModel(
      id: 'h1',
      title: 'Morning meditation',
      emoji: '🧘',
      frequency: 'daily',
      streak: 12,
      completedToday: true,
      accentColor: AppColors.habitsAccent,
    ),
    HabitModel(
      id: 'h2',
      title: 'Drink 2L water',
      emoji: '💧',
      frequency: 'daily',
      streak: 5,
      completedToday: false,
      accentColor: AppColors.habitsAccent,
    ),
    HabitModel(
      id: 'h3',
      title: 'Weekly budget review',
      emoji: '📊',
      frequency: 'weekly',
      streak: 3,
      completedToday: false,
      accentColor: AppColors.habitsAccent,
    ),
  ];

  static final List<Map<String, dynamic>> _mockTodos = [
    {
      'id': 't1',
      'title': 'Submit scholarship application',
      'dueDate': '2026-08-02',
      'priority': 'high',
      'isDone': false,
    },
    {
      'id': 't2',
      'title': 'Update resume',
      'dueDate': '2026-08-05',
      'priority': 'medium',
      'isDone': false,
    },
    {
      'id': 't3',
      'title': 'Call ACLEDA mentor',
      'dueDate': '2026-07-28',
      'priority': 'low',
      'isDone': true,
    },
  ];
}
