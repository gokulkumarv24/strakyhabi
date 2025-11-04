import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streaky_app/models/streak_model.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/services/local_storage.dart';
import 'package:streaky_app/services/notification_service.dart';

/// Provider for managing streak state and operations
final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier();
});

/// Streak state class
class StreakState {
  final List<Streak> streaks;
  final StreakAnalytics? analytics;
  final bool isLoading;
  final String? error;

  const StreakState({
    this.streaks = const [],
    this.analytics,
    this.isLoading = false,
    this.error,
  });

  StreakState copyWith({
    List<Streak>? streaks,
    StreakAnalytics? analytics,
    bool? isLoading,
    String? error,
  }) {
    return StreakState(
      streaks: streaks ?? this.streaks,
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Streak state notifier
class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier() : super(const StreakState()) {
    loadStreaks();
  }

  /// Load all streaks for current user
  Future<void> loadStreaks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = LocalStorageService.getCurrentUser();
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No user found',
        );
        return;
      }

      final streaks = LocalStorageService.getStreaksForUser(user.id);
      final analytics = LocalStorageService.getAnalyticsForUser(user.id);

      state = state.copyWith(
        streaks: streaks,
        analytics: analytics,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update streak when task is completed
  Future<void> updateStreakForTask(Task task) async {
    try {
      final user = LocalStorageService.getCurrentUser();
      if (user == null) return;

      // Find existing streak or create new one
      Streak? existingStreak;
      try {
        existingStreak = LocalStorageService.getStreakByTaskId(task.id);
      } catch (e) {
        // No existing streak found
      }

      if (existingStreak == null) {
        // Create new streak
        existingStreak = Streak(
          id: '${task.id}_streak',
          userId: user.id,
          taskId: task.id,
          category: task.category ?? 'Personal',
        );
      }

      // Update streak
      existingStreak.updateStreak(DateTime.now());
      await LocalStorageService.saveStreak(existingStreak);

      // Check for milestone notifications
      await _checkMilestoneNotification(existingStreak);

      // Reload streaks
      await loadStreaks();
      
      // Update analytics
      await _updateAnalytics();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Break streak (when task is not completed in time)
  Future<void> breakStreak(String streakId) async {
    try {
      final streaks = List<Streak>.from(state.streaks);
      final streakIndex = streaks.indexWhere((s) => s.id == streakId);
      
      if (streakIndex != -1) {
        final streak = streaks[streakIndex];
        final lastStreak = streak.currentStreak;
        
        // Reset current streak but keep longest streak record
        streak.currentStreak = 0;
        streak.isActive = false;
        streak.needsSync = true;
        
        await LocalStorageService.saveStreak(streak);

        // Show streak broken notification
        await NotificationService.showStreakBroken(
          category: streak.category,
          lastStreak: lastStreak,
        );

        // Reload streaks
        await loadStreaks();
        await _updateAnalytics();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Create new streak
  Future<void> createStreak({
    required String taskId,
    required String category,
  }) async {
    try {
      final user = LocalStorageService.getCurrentUser();
      if (user == null) return;

      final streak = Streak(
        id: '${taskId}_streak',
        userId: user.id,
        taskId: taskId,
        category: category,
      );

      await LocalStorageService.saveStreak(streak);
      await loadStreaks();
      await _updateAnalytics();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete streak
  Future<void> deleteStreak(String streakId) async {
    try {
      await LocalStorageService.deleteStreak(streakId);
      await loadStreaks();
      await _updateAnalytics();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get streaks by category
  List<Streak> getStreaksByCategory(String category) {
    return state.streaks.where((streak) => streak.category == category).toList();
  }

  /// Get active streaks
  List<Streak> get activeStreaks {
    return state.streaks.where((streak) => streak.isActive).toList();
  }

  /// Get longest streak
  int get longestStreak {
    if (state.streaks.isEmpty) return 0;
    return state.streaks.map((s) => s.longestStreak).reduce((a, b) => a > b ? a : b);
  }

  /// Check all streaks for status updates
  Future<void> checkAllStreakStatus() async {
    bool needsUpdate = false;

    for (final streak in state.streaks) {
      if (streak.isActive) {
        streak.checkStreakStatus();
        
        // If streak was broken, mark for update
        if (streak.currentStreak == 0 && streak.isActive) {
          streak.isActive = false;
          await LocalStorageService.saveStreak(streak);
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate) {
      await loadStreaks();
      await _updateAnalytics();
    }
  }

  /// Update analytics
  Future<void> _updateAnalytics() async {
    final user = LocalStorageService.getCurrentUser();
    if (user == null) return;

    final analytics = LocalStorageService.getAnalyticsForUser(user.id) ??
        StreakAnalytics(userId: user.id);

    analytics.calculateFromStreaks(state.streaks);
    await LocalStorageService.saveAnalytics(analytics);

    state = state.copyWith(analytics: analytics);
  }

  /// Check for milestone notification
  Future<void> _checkMilestoneNotification(Streak streak) async {
    final milestones = [7, 14, 21, 30, 50, 75, 100];
    
    if (milestones.contains(streak.currentStreak)) {
      await NotificationService.showStreakMilestone(
        category: streak.category,
        streakCount: streak.currentStreak,
      );
    }
  }

  /// Get streak statistics
  Map<String, dynamic> getStreakStats() {
    final activeStreaks = this.activeStreaks;
    final totalDays = state.streaks.fold<int>(
      0, 
      (sum, streak) => sum + streak.completionDates.length,
    );
    
    return {
      'totalStreaks': state.streaks.length,
      'activeStreaks': activeStreaks.length,
      'longestStreak': longestStreak,
      'totalCompletionDays': totalDays,
      'averageStreak': state.streaks.isNotEmpty 
          ? totalDays / state.streaks.length 
          : 0.0,
      'categories': state.streaks.map((s) => s.category).toSet().toList(),
    };
  }

  /// Get weekly streak completion rate
  double getWeeklyCompletionRate() {
    if (state.streaks.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    int totalPossibleDays = 0;
    int completedDays = 0;
    
    for (final streak in state.streaks) {
      if (streak.isActive) {
        totalPossibleDays += 7; // 7 days in a week
        
        final weekCompletions = streak.getCompletionDatesInRange(
          startOfWeek, 
          endOfWeek,
        );
        completedDays += weekCompletions.length;
      }
    }
    
    return totalPossibleDays > 0 ? completedDays / totalPossibleDays : 0.0;
  }

  /// Get monthly streak data for chart
  List<Map<String, dynamic>> getMonthlyStreakData() {
    final now = DateTime.now();
    final monthlyData = <String, int>{};
    
    // Initialize last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = 0;
    }
    
    // Fill with actual completion data
    for (final streak in state.streaks) {
      for (final monthKey in streak.monthlyStats.keys) {
        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = monthlyData[monthKey]! + streak.monthlyStats[monthKey]!;
        }
      }
    }
    
    return monthlyData.entries
        .map((entry) => {
              'month': entry.key,
              'completions': entry.value,
            })
        .toList();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadStreaks();
    await _updateAnalytics();
  }
}