import '../models/goal_model.dart';
import '../models/habit_model.dart';
import '../models/todo_model.dart';
import '../providers/growth_provider.dart';

class GrowthRepository {
  final GrowthProvider _provider;

  GrowthRepository({GrowthProvider? provider})
    : _provider = provider ?? GrowthProvider();

  Future<List<GoalModel>> fetchGoals() => _provider.getGoals();
  Future<List<HabitModel>> fetchHabits() => _provider.getHabits();
  Future<List<TodoModel>> fetchTodos() => _provider.getTodos();
}
