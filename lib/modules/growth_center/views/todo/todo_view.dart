import 'package:flutter/material.dart';
import '../../../../core/widgets/task_card.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../models/task_model.dart';
import 'add_task_modal.dart';

enum TaskFilter { all, active, done }

class TodoView extends StatefulWidget {
  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onAdd;
  final ValueChanged<TaskModel> onUpdate;
  final ValueChanged<TaskModel> onDelete;
  final void Function(TaskModel task, bool? value) onToggle;

  const TodoView({
    super.key,
    required this.tasks,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> {
  // This filter stays LOCAL to TodoView — it's just "what's showing on
  // screen right now," not real data, so it doesn't need to move to
  // GrowthView.
  TaskFilter _selectedFilter = TaskFilter.all;

  final Set<String> _recentlyCompletedIds = {};

  int get _completedCount => widget.tasks.where((t) => t.isCompleted).length;
  int get _totalCount => widget.tasks.length;

  List<TaskModel> get _filteredTasks {
    switch (_selectedFilter) {
      case TaskFilter.all:
        return widget.tasks;
      case TaskFilter.active:
        return widget.tasks
            .where(
              (t) => !t.isCompleted || _recentlyCompletedIds.contains(t.id),
            )
            .toList();
      case TaskFilter.done:
        return widget.tasks.where((t) => t.isCompleted).toList();
    }
  }

  void _handleToggle(TaskModel task, bool? value) {
    widget.onToggle(task, value);

    if (value == true && _selectedFilter == TaskFilter.active) {
      setState(() => _recentlyCompletedIds.add(task.id));
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _recentlyCompletedIds.remove(task.id));
      });
    }
  }

  void _openAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskModal(onSave: widget.onAdd),
    );
  }

  void _openEditTask(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddTaskModal(existingTask: task, onSave: widget.onUpdate),
    );
  }

  Future<void> _handleDeleteTask(TaskModel task) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      message: 'This task will be permanently deleted.',
    );
    if (confirmed) widget.onDelete(task);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To-Do List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B2E),
                ),
              ),
              GestureDetector(
                onTap: _openAddTask,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_completedCount/$_totalCount completed today ✅',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _selectedFilter == TaskFilter.all,
                onTap: () => setState(() => _selectedFilter = TaskFilter.all),
              ),
              const SizedBox(width: 10),
              _FilterChip(
                label: 'Active',
                selected: _selectedFilter == TaskFilter.active,
                onTap: () =>
                    setState(() => _selectedFilter = TaskFilter.active),
              ),
              const SizedBox(width: 10),
              _FilterChip(
                label: 'Done',
                selected: _selectedFilter == TaskFilter.done,
                onTap: () => setState(() => _selectedFilter = TaskFilter.done),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                return TaskCard(
                  task: task,
                  onToggleComplete: (value) => _handleToggle(task, value),
                  onEdit: () => _openEditTask(task),
                  onDelete: () => _handleDeleteTask(task),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
