import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/services/local_storage.dart';
import 'package:streaky_app/services/notification_service.dart';
import 'package:streaky_app/providers/streak_provider.dart';

/// Provider for managing task state and operations
final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(ref);
});

/// Task state class
class TaskState {
  final List<Task> tasks;
  final List<Task> todayTasks;
  final List<Task> overdueTasks;
  final bool isLoading;
  final String? error;
  final TaskFilter filter;

  const TaskState({
    this.tasks = const [],
    this.todayTasks = const [],
    this.overdueTasks = const [],
    this.isLoading = false,
    this.error,
    this.filter = const TaskFilter(),
  });

  TaskState copyWith({
    List<Task>? tasks,
    List<Task>? todayTasks,
    List<Task>? overdueTasks,
    bool? isLoading,
    String? error,
    TaskFilter? filter,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      todayTasks: todayTasks ?? this.todayTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filter: filter ?? this.filter,
    );
  }
}

/// Task filter class
class TaskFilter {
  final bool? isCompleted;
  final TaskPriority? priority;
  final String? category;
  final DateTime? dueDate;

  const TaskFilter({
    this.isCompleted,
    this.priority,
    this.category,
    this.dueDate,
  });

  TaskFilter copyWith({
    bool? isCompleted,
    TaskPriority? priority,
    String? category,
    DateTime? dueDate,
  }) {
    return TaskFilter(
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

/// Task state notifier
class TaskNotifier extends StateNotifier<TaskState> {
  final Ref ref;

  TaskNotifier(this.ref) : super(const TaskState()) {
    loadTasks();
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final allTasks = LocalStorageService.getAllTasks();
      final todayTasks = LocalStorageService.getTasksDueToday();
      final overdueTasks = LocalStorageService.getOverdueTasks();

      state = state.copyWith(
        tasks: allTasks,
        todayTasks: todayTasks,
        overdueTasks: overdueTasks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create new task
  Future<void> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? category,
    int estimatedMinutes = 30,
    List<String>? tags,
    bool isRecurring = false,
    RecurrencePattern? recurrencePattern,
  }) async {
    try {
      final user = LocalStorageService.getCurrentUser();
      
      final task = Task(
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        category: category,
        estimatedMinutes: estimatedMinutes,
        tags: tags,
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        userId: user?.id,
      );

      await LocalStorageService.saveTask(task);

      // Schedule notification if due date is set
      if (dueDate != null && dueDate.isAfter(DateTime.now())) {
        final reminderTime = dueDate.subtract(const Duration(hours: 1));
        if (reminderTime.isAfter(DateTime.now())) {
          await NotificationService.scheduleTaskReminder(
            task: task,
            reminderTime: reminderTime,
          );
        }
      }

      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update existing task
  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? category,
    int? estimatedMinutes,
    List<String>? tags,
  }) async {
    try {
      final tasks = List<Task>.from(state.tasks);
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      
      if (taskIndex != -1) {
        final task = tasks[taskIndex];
        
        // Cancel existing notification
        await NotificationService.cancelTaskReminder(taskId);
        
        task.update(
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          category: category,
          estimatedMinutes: estimatedMinutes,
          tags: tags,
        );

        // Schedule new notification if due date is set
        if (task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
          final reminderTime = task.dueDate!.subtract(const Duration(hours: 1));
          if (reminderTime.isAfter(DateTime.now())) {
            await NotificationService.scheduleTaskReminder(
              task: task,
              reminderTime: reminderTime,
            );
          }
        }

        await loadTasks();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Complete task
  Future<void> completeTask(String taskId) async {
    try {
      final tasks = List<Task>.from(state.tasks);
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      
      if (taskIndex != -1) {
        final task = tasks[taskIndex];
        task.complete();
        
        // Cancel notification
        await NotificationService.cancelTaskReminder(taskId);

        // Update streak
        await ref.read(streakProvider.notifier).updateStreakForTask(task);

        // Handle recurring tasks
        if (task.isRecurring && task.recurrencePattern != null) {
          await _createNextRecurringTask(task);
        }

        await loadTasks();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark task as incomplete
  Future<void> markTaskIncomplete(String taskId) async {
    try {
      final tasks = List<Task>.from(state.tasks);
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      
      if (taskIndex != -1) {
        final task = tasks[taskIndex];
        task.markIncomplete();

        // Reschedule notification if due date is in future
        if (task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
          final reminderTime = task.dueDate!.subtract(const Duration(hours: 1));
          if (reminderTime.isAfter(DateTime.now())) {
            await NotificationService.scheduleTaskReminder(
              task: task,
              reminderTime: reminderTime,
            );
          }
        }

        await loadTasks();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await LocalStorageService.deleteTask(taskId);
      await NotificationService.cancelTaskReminder(taskId);
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get filtered tasks
  List<Task> getFilteredTasks() {
    var filteredTasks = state.tasks;

    if (state.filter.isCompleted != null) {
      filteredTasks = filteredTasks
          .where((task) => task.isCompleted == state.filter.isCompleted!)
          .toList();
    }

    if (state.filter.priority != null) {
      filteredTasks = filteredTasks
          .where((task) => task.priority == state.filter.priority!)
          .toList();
    }

    if (state.filter.category != null) {
      filteredTasks = filteredTasks
          .where((task) => task.category == state.filter.category!)
          .toList();
    }

    if (state.filter.dueDate != null) {
      filteredTasks = filteredTasks
          .where((task) => 
              task.dueDate != null &&
              task.dueDate!.year == state.filter.dueDate!.year &&
              task.dueDate!.month == state.filter.dueDate!.month &&
              task.dueDate!.day == state.filter.dueDate!.day)
          .toList();
    }

    return filteredTasks;
  }

  /// Apply filter
  void applyFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Clear filter
  void clearFilter() {
    state = state.copyWith(filter: const TaskFilter());
  }

  /// Get tasks by category
  List<Task> getTasksByCategory(String category) {
    return state.tasks.where((task) => task.category == category).toList();
  }

  /// Get task statistics
  Map<String, dynamic> getTaskStats() {
    final completedTasks = state.tasks.where((task) => task.isCompleted).length;
    final pendingTasks = state.tasks.where((task) => !task.isCompleted).length;
    final overdueTasks = state.overdueTasks.length;
    
    final categories = state.tasks
        .where((task) => task.category != null)
        .map((task) => task.category!)
        .toSet()
        .toList();

    final priorityStats = <TaskPriority, int>{};
    for (final priority in TaskPriority.values) {
      priorityStats[priority] = state.tasks
          .where((task) => task.priority == priority)
          .length;
    }

    return {
      'total': state.tasks.length,
      'completed': completedTasks,
      'pending': pendingTasks,
      'overdue': overdueTasks,
      'todayDue': state.todayTasks.length,
      'completionRate': state.tasks.isNotEmpty 
          ? completedTasks / state.tasks.length 
          : 0.0,
      'categories': categories,
      'priorityStats': priorityStats,
    };
  }

  /// Get productivity data for chart
  List<Map<String, dynamic>> getProductivityData(int days) {
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayTasks = state.tasks.where((task) =>
          task.completedAt != null &&
          task.completedAt!.isAfter(dayStart) &&
          task.completedAt!.isBefore(dayEnd)).length;

      data.add({
        'date': dayStart,
        'completed': dayTasks,
      });
    }

    return data;
  }

  /// Create next recurring task
  Future<void> _createNextRecurringTask(Task originalTask) async {
    if (originalTask.recurrencePattern == null) return;

    DateTime? nextDueDate;
    final pattern = originalTask.recurrencePattern!;
    final currentDue = originalTask.dueDate ?? DateTime.now();

    switch (pattern.type) {
      case RecurrenceType.daily:
        nextDueDate = currentDue.add(Duration(days: pattern.interval));
        break;
      case RecurrenceType.weekly:
        nextDueDate = currentDue.add(Duration(days: 7 * pattern.interval));
        break;
      case RecurrenceType.monthly:
        nextDueDate = DateTime(
          currentDue.year,
          currentDue.month + pattern.interval,
          currentDue.day,
          currentDue.hour,
          currentDue.minute,
        );
        break;
      case RecurrenceType.yearly:
        nextDueDate = DateTime(
          currentDue.year + pattern.interval,
          currentDue.month,
          currentDue.day,
          currentDue.hour,
          currentDue.minute,
        );
        break;
    }

    if (nextDueDate != null) {
      // Check if we've reached the end date or max occurrences
      if (pattern.endDate != null && nextDueDate.isAfter(pattern.endDate!)) {
        return;
      }

      await createTask(
        title: originalTask.title,
        description: originalTask.description,
        dueDate: nextDueDate,
        priority: originalTask.priority,
        category: originalTask.category,
        estimatedMinutes: originalTask.estimatedMinutes,
        tags: originalTask.tags,
        isRecurring: true,
        recurrencePattern: pattern,
      );
    }
  }

  /// Reschedule all task notifications
  Future<void> rescheduleAllNotifications() async {
    await NotificationService.scheduleAllTaskReminders();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadTasks();
  }

  /// Bulk complete tasks
  Future<void> bulkCompleteTasks(List<String> taskIds) async {
    try {
      for (final taskId in taskIds) {
        await completeTask(taskId);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Bulk delete tasks
  Future<void> bulkDeleteTasks(List<String> taskIds) async {
    try {
      for (final taskId in taskIds) {
        await deleteTask(taskId);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}