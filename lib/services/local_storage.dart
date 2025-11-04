import 'package:hive_flutter/hive_flutter.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/models/user_model.dart';
import 'package:streaky_app/models/streak_model.dart';

/// Local storage service using Hive for offline-first architecture
class LocalStorageService {
  static const String _tasksBoxName = 'tasks';
  static const String _userBoxName = 'user';
  static const String _streaksBoxName = 'streaks';
  static const String _analyticsBoxName = 'analytics';
  static const String _settingsBoxName = 'settings';

  static Box<Task>? _tasksBox;
  static Box<User>? _userBox;
  static Box<Streak>? _streaksBox;
  static Box<StreakAnalytics>? _analyticsBox;
  static Box<dynamic>? _settingsBox;

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(RecurrencePatternAdapter());
    Hive.registerAdapter(RecurrenceTypeAdapter());
    
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    Hive.registerAdapter(SubscriptionTierAdapter());
    Hive.registerAdapter(ThemeModeAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());
    
    Hive.registerAdapter(StreakAdapter());
    Hive.registerAdapter(StreakTypeAdapter());
    Hive.registerAdapter(StreakAnalyticsAdapter());

    // Open boxes
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
    _userBox = await Hive.openBox<User>(_userBoxName);
    _streaksBox = await Hive.openBox<Streak>(_streaksBoxName);
    _analyticsBox = await Hive.openBox<StreakAnalytics>(_analyticsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  /// Close all boxes
  static Future<void> close() async {
    await _tasksBox?.close();
    await _userBox?.close();
    await _streaksBox?.close();
    await _analyticsBox?.close();
    await _settingsBox?.close();
  }

  // TASK OPERATIONS

  /// Get all tasks
  static List<Task> getAllTasks() {
    return _tasksBox?.values.toList() ?? [];
  }

  /// Get tasks by filter
  static List<Task> getTasksWhere({
    bool? isCompleted,
    TaskPriority? priority,
    String? category,
    DateTime? dueDate,
  }) {
    var tasks = getAllTasks();

    if (isCompleted != null) {
      tasks = tasks.where((task) => task.isCompleted == isCompleted).toList();
    }
    if (priority != null) {
      tasks = tasks.where((task) => task.priority == priority).toList();
    }
    if (category != null) {
      tasks = tasks.where((task) => task.category == category).toList();
    }
    if (dueDate != null) {
      tasks = tasks.where((task) => 
          task.dueDate != null && 
          task.dueDate!.year == dueDate.year &&
          task.dueDate!.month == dueDate.month &&
          task.dueDate!.day == dueDate.day).toList();
    }

    return tasks;
  }

  /// Get tasks due today
  static List<Task> getTasksDueToday() {
    final today = DateTime.now();
    return getTasksWhere(dueDate: today, isCompleted: false);
  }

  /// Get overdue tasks
  static List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return getAllTasks().where((task) => 
        task.dueDate != null && 
        task.dueDate!.isBefore(now) && 
        !task.isCompleted).toList();
  }

  /// Save task
  static Future<void> saveTask(Task task) async {
    await _tasksBox?.put(task.id, task);
  }

  /// Delete task
  static Future<void> deleteTask(String taskId) async {
    await _tasksBox?.delete(taskId);
  }

  /// Get tasks that need sync
  static List<Task> getTasksNeedingSync() {
    return getAllTasks().where((task) => task.needsSync).toList();
  }

  /// Mark task as synced
  static Future<void> markTaskSynced(String taskId) async {
    final task = _tasksBox?.get(taskId);
    if (task != null) {
      task.needsSync = false;
      await task.save();
    }
  }

  // USER OPERATIONS

  /// Get current user
  static User? getCurrentUser() {
    return _userBox?.values.isNotEmpty == true ? _userBox!.values.first : null;
  }

  /// Save user
  static Future<void> saveUser(User user) async {
    await _userBox?.clear(); // Only one user per device
    await _userBox?.put(user.id, user);
  }

  /// Update user
  static Future<void> updateUser(User user) async {
    await _userBox?.put(user.id, user);
  }

  /// Delete user data (logout)
  static Future<void> clearUserData() async {
    await _userBox?.clear();
    await _tasksBox?.clear();
    await _streaksBox?.clear();
    await _analyticsBox?.clear();
  }

  // STREAK OPERATIONS

  /// Get all streaks
  static List<Streak> getAllStreaks() {
    return _streaksBox?.values.toList() ?? [];
  }

  /// Get streaks for user
  static List<Streak> getStreaksForUser(String userId) {
    return getAllStreaks().where((streak) => streak.userId == userId).toList();
  }

  /// Get streak by task ID
  static Streak? getStreakByTaskId(String taskId) {
    return getAllStreaks().firstWhere(
      (streak) => streak.taskId == taskId,
      orElse: () => throw StateError('No streak found'),
    );
  }

  /// Save streak
  static Future<void> saveStreak(Streak streak) async {
    await _streaksBox?.put(streak.id, streak);
  }

  /// Delete streak
  static Future<void> deleteStreak(String streakId) async {
    await _streaksBox?.delete(streakId);
  }

  /// Get streaks that need sync
  static List<Streak> getStreaksNeedingSync() {
    return getAllStreaks().where((streak) => streak.needsSync).toList();
  }

  // ANALYTICS OPERATIONS

  /// Get analytics for user
  static StreakAnalytics? getAnalyticsForUser(String userId) {
    return _analyticsBox?.values
        .where((analytics) => analytics.userId == userId)
        .firstOrNull;
  }

  /// Save analytics
  static Future<void> saveAnalytics(StreakAnalytics analytics) async {
    await _analyticsBox?.put(analytics.userId, analytics);
  }

  // SETTINGS OPERATIONS

  /// Get setting value
  static T? getSetting<T>(String key) {
    return _settingsBox?.get(key) as T?;
  }

  /// Save setting
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  /// Get last sync timestamp
  static DateTime? getLastSyncTime() {
    final timestamp = getSetting<String>('lastSyncTime');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Update last sync timestamp
  static Future<void> updateLastSyncTime() async {
    await saveSetting('lastSyncTime', DateTime.now().toIso8601String());
  }

  /// Get first launch flag
  static bool isFirstLaunch() {
    return getSetting<bool>('firstLaunch') ?? true;
  }

  /// Mark first launch complete
  static Future<void> markFirstLaunchComplete() async {
    await saveSetting('firstLaunch', false);
  }

  // UTILITY METHODS

  /// Get database statistics
  static Map<String, int> getDatabaseStats() {
    return {
      'tasks': _tasksBox?.length ?? 0,
      'streaks': _streaksBox?.length ?? 0,
      'analytics': _analyticsBox?.length ?? 0,
      'settings': _settingsBox?.length ?? 0,
    };
  }

  /// Clear all data (for testing or reset)
  static Future<void> clearAllData() async {
    await _tasksBox?.clear();
    await _userBox?.clear();
    await _streaksBox?.clear();
    await _analyticsBox?.clear();
    await _settingsBox?.clear();
  }

  /// Compact databases to optimize storage
  static Future<void> compactDatabases() async {
    await _tasksBox?.compact();
    await _userBox?.compact();
    await _streaksBox?.compact();
    await _analyticsBox?.compact();
    await _settingsBox?.compact();
  }

  /// Export data as JSON (for backup)
  static Map<String, dynamic> exportData() {
    return {
      'tasks': getAllTasks().map((task) => task.toJson()).toList(),
      'user': getCurrentUser()?.toJson(),
      'streaks': getAllStreaks().map((streak) => streak.toJson()).toList(),
      'analytics': _analyticsBox?.values.map((analytics) => analytics.toJson()).toList(),
      'settings': _settingsBox?.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import data from JSON (for restore)
  static Future<void> importData(Map<String, dynamic> data) async {
    // Clear existing data
    await clearAllData();

    // Import tasks
    if (data['tasks'] != null) {
      for (final taskJson in data['tasks']) {
        final task = Task.fromJson(taskJson);
        await saveTask(task);
      }
    }

    // Import user
    if (data['user'] != null) {
      final user = User.fromJson(data['user']);
      await saveUser(user);
    }

    // Import streaks
    if (data['streaks'] != null) {
      for (final streakJson in data['streaks']) {
        final streak = Streak.fromJson(streakJson);
        await saveStreak(streak);
      }
    }

    // Import analytics
    if (data['analytics'] != null) {
      for (final analyticsJson in data['analytics']) {
        final analytics = StreakAnalytics.fromJson(analyticsJson);
        await saveAnalytics(analytics);
      }
    }

    // Import settings
    if (data['settings'] != null) {
      for (final entry in (data['settings'] as Map).entries) {
        await saveSetting(entry.key, entry.value);
      }
    }
  }
}