import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../models/task_model.dart';
import '../../../repositories/tasks_repository.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _showCompleted = true;

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    DateTime? selectedDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Task',
                style: AppTypography.cardTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent,
                              onPrimary: Colors.black,
                              surface: AppColors.dialogBackground,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDueDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.chipBackgroundUnselected,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            selectedDueDate != null
                                ? DateFormatter.formatTaskDate(selectedDueDate!)
                                : 'Set Due Date',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.accent, size: 24),
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isNotEmpty) {
                        final auth = ref.read(authServiceProvider);
                        final task = TaskModel(
                          id: const Uuid().v4(),
                          userId: auth.currentUid,
                          title: title,
                          dueDate: selectedDueDate,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        ref.read(tasksRepositoryProvider).saveTask(task);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final repo = ref.watch(tasksRepositoryProvider);
    final allTasks = tasksAsync.value ?? repo.getTasks();

    final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: allTasks.isEmpty
          ? const EmptyStateView(isTasks: true)
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Active Tasks
                ...activeTasks.map((task) => _buildTaskTile(task, repo)),

                // Completed Section Header
                if (completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _showCompleted = !_showCompleted),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _showCompleted
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Completed (${completedTasks.length})',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showCompleted)
                    ...completedTasks.map((task) => _buildTaskTile(task, repo)),
                ],

                const SizedBox(height: 90),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskTile(TaskModel task, TasksRepository repo) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha: 0.8),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        repo.deleteTask(task.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: GestureDetector(
            onTap: () => repo.toggleTaskCompletion(task.id),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? AppColors.accent : AppColors.checkboxBorder,
                  width: 1.8,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.black)
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: task.isCompleted
                ? AppTypography.taskTitleCompleted
                : AppTypography.taskTitle,
          ),
          subtitle: task.dueDate != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormatter.formatTaskDate(task.dueDate!),
                    style: AppTypography.cardDate.copyWith(
                      color: task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                          ? Colors.redAccent
                          : AppColors.textTertiary,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
