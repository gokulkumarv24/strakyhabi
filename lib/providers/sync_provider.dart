import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streaky_app/services/kv_service.dart';
import 'package:streaky_app/services/local_storage.dart';
import 'package:streaky_app/providers/auth_provider.dart';

/// Provider for managing sync operations
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

/// Sync state class
class SyncState {
  final bool isSyncing;
  final bool isConnected;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final String? error;
  final SyncStatus status;
  final Map<String, SyncProgress> syncProgress;

  const SyncState({
    this.isSyncing = false,
    this.isConnected = true,
    this.lastSyncTime,
    this.pendingChanges = 0,
    this.error,
    this.status = SyncStatus.idle,
    this.syncProgress = const {},
  });

  SyncState copyWith({
    bool? isSyncing,
    bool? isConnected,
    DateTime? lastSyncTime,
    int? pendingChanges,
    String? error,
    SyncStatus? status,
    Map<String, SyncProgress>? syncProgress,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isConnected: isConnected ?? this.isConnected,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      error: error ?? this.error,
      status: status ?? this.status,
      syncProgress: syncProgress ?? this.syncProgress,
    );
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
}

/// Sync progress for individual entities
class SyncProgress {
  final String entityType;
  final int total;
  final int completed;
  final String? currentItem;

  const SyncProgress({
    required this.entityType,
    required this.total,
    required this.completed,
    this.currentItem,
  });

  double get progress => total > 0 ? completed / total : 0.0;
  bool get isComplete => completed >= total;
}

/// Sync state notifier
class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;

  SyncNotifier(this.ref) : super(const SyncState()) {
    _initializeSync();
  }

  /// Initialize sync state
  Future<void> _initializeSync() async {
    try {
      final pendingCount = LocalStorageService.getOfflineSyncQueueCount();
      final lastSync = LocalStorageService.getLastSyncTime();
      
      state = state.copyWith(
        pendingChanges: pendingCount,
        lastSyncTime: lastSync,
      );

      // Check connectivity
      await _checkConnectivity();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check by attempting to reach our API
      await KvService.healthCheck();
      state = state.copyWith(isConnected: true);
    } catch (e) {
      state = state.copyWith(isConnected: false);
    }
  }

  /// Perform full sync
  Future<void> syncAll() async {
    if (state.isSyncing) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    state = state.copyWith(
      isSyncing: true,
      status: SyncStatus.syncing,
      error: null,
    );

    try {
      await _checkConnectivity();
      
      if (!state.isConnected) {
        throw Exception('No internet connection');
      }

      // Sync user data
      await _syncUserData();
      
      // Sync tasks
      await _syncTasks();
      
      // Sync streaks
      await _syncStreaks();
      
      // Sync analytics
      await _syncAnalytics();

      // Update state
      state = state.copyWith(
        isSyncing: false,
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
        pendingChanges: 0,
        syncProgress: {},
      );

      // Save sync time
      await LocalStorageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        status: SyncStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Sync user data
  Future<void> _syncUserData() async {
    _updateProgress('user', 1, 0, 'Syncing user profile...');
    
    final user = ref.read(authProvider).user;
    if (user != null) {
      await KvService.syncUserProfile(user);
    }
    
    _updateProgress('user', 1, 1, 'User profile synced');
  }

  /// Sync tasks
  Future<void> _syncTasks() async {
    final tasks = LocalStorageService.getAllTasks();
    final totalTasks = tasks.length;
    
    _updateProgress('tasks', totalTasks, 0, 'Starting task sync...');

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      _updateProgress('tasks', totalTasks, i, 'Syncing task: ${task.title}');
      
      try {
        await KvService.syncTask(task);
      } catch (e) {
        // Handle individual task sync errors
        print('Failed to sync task ${task.id}: $e');
      }
    }

    _updateProgress('tasks', totalTasks, totalTasks, 'All tasks synced');
  }

  /// Sync streaks
  Future<void> _syncStreaks() async {
    final streaks = LocalStorageService.getAllStreaks();
    final totalStreaks = streaks.length;
    
    _updateProgress('streaks', totalStreaks, 0, 'Starting streak sync...');

    for (int i = 0; i < streaks.length; i++) {
      final streak = streaks[i];
      _updateProgress('streaks', totalStreaks, i, 'Syncing streak: ${streak.name}');
      
      try {
        await KvService.syncStreak(streak);
      } catch (e) {
        print('Failed to sync streak ${streak.id}: $e');
      }
    }

    _updateProgress('streaks', totalStreaks, totalStreaks, 'All streaks synced');
  }

  /// Sync analytics
  Future<void> _syncAnalytics() async {
    _updateProgress('analytics', 1, 0, 'Syncing analytics data...');
    
    try {
      final analyticsData = LocalStorageService.getAnalyticsData();
      await KvService.syncAnalytics(analyticsData);
      _updateProgress('analytics', 1, 1, 'Analytics synced');
    } catch (e) {
      print('Failed to sync analytics: $e');
      _updateProgress('analytics', 1, 1, 'Analytics sync failed');
    }
  }

  /// Update sync progress for specific entity type
  void _updateProgress(String entityType, int total, int completed, String? currentItem) {
    final progress = SyncProgress(
      entityType: entityType,
      total: total,
      completed: completed,
      currentItem: currentItem,
    );

    final updatedProgress = Map<String, SyncProgress>.from(state.syncProgress);
    updatedProgress[entityType] = progress;

    state = state.copyWith(syncProgress: updatedProgress);
  }

  /// Sync specific entity type
  Future<void> syncEntityType(String entityType) async {
    switch (entityType) {
      case 'tasks':
        await _syncTasks();
        break;
      case 'streaks':
        await _syncStreaks();
        break;
      case 'user':
        await _syncUserData();
        break;
      case 'analytics':
        await _syncAnalytics();
        break;
    }
  }

  /// Queue offline change
  Future<void> queueOfflineChange({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      await LocalStorageService.queueOfflineChange(
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        data: data,
      );

      final pendingCount = LocalStorageService.getOfflineSyncQueueCount();
      state = state.copyWith(pendingChanges: pendingCount);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Process offline queue
  Future<void> processOfflineQueue() async {
    if (state.isSyncing || !state.isConnected) return;

    try {
      final queueItems = LocalStorageService.getOfflineSyncQueue();
      
      for (final item in queueItems) {
        await _processQueueItem(item);
      }

      // Clear processed items
      await LocalStorageService.clearOfflineSyncQueue();
      
      state = state.copyWith(pendingChanges: 0);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Process individual queue item
  Future<void> _processQueueItem(Map<String, dynamic> item) async {
    final entityType = item['entityType'] as String;
    final entityId = item['entityId'] as String;
    final operation = item['operation'] as String;
    final data = item['data'] as Map<String, dynamic>;

    switch (entityType) {
      case 'task':
        await _processTaskOperation(entityId, operation, data);
        break;
      case 'streak':
        await _processStreakOperation(entityId, operation, data);
        break;
      case 'user':
        await _processUserOperation(entityId, operation, data);
        break;
    }
  }

  /// Process task operation
  Future<void> _processTaskOperation(String entityId, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'create':
      case 'update':
        await KvService.saveTask(data);
        break;
      case 'delete':
        await KvService.deleteTask(entityId);
        break;
    }
  }

  /// Process streak operation
  Future<void> _processStreakOperation(String entityId, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'create':
      case 'update':
        await KvService.saveStreak(data);
        break;
      case 'delete':
        await KvService.deleteStreak(entityId);
        break;
    }
  }

  /// Process user operation
  Future<void> _processUserOperation(String entityId, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'update':
        await KvService.updateUser(data);
        break;
    }
  }

  /// Force sync now
  Future<void> forceSyncNow() async {
    await _checkConnectivity();
    if (state.isConnected) {
      await syncAll();
    }
  }

  /// Schedule background sync
  void scheduleBackgroundSync() {
    // This would integrate with background processing
    // For now, just check if sync is needed
    if (_shouldSync()) {
      forceSyncNow();
    }
  }

  /// Check if sync is needed
  bool _shouldSync() {
    if (state.pendingChanges > 0) return true;
    
    if (state.lastSyncTime == null) return true;
    
    final timeSinceSync = DateTime.now().difference(state.lastSyncTime!);
    return timeSinceSync.inMinutes > 30; // Sync every 30 minutes
  }

  /// Clear sync error
  void clearError() {
    state = state.copyWith(error: null, status: SyncStatus.idle);
  }

  /// Reset sync state
  void resetSyncState() {
    state = const SyncState();
    _initializeSync();
  }

  /// Get sync status message
  String get statusMessage {
    switch (state.status) {
      case SyncStatus.idle:
        if (state.pendingChanges > 0) {
          return '${state.pendingChanges} changes pending sync';
        }
        if (state.lastSyncTime != null) {
          final timeDiff = DateTime.now().difference(state.lastSyncTime!);
          if (timeDiff.inMinutes < 60) {
            return 'Synced ${timeDiff.inMinutes} minutes ago';
          } else if (timeDiff.inHours < 24) {
            return 'Synced ${timeDiff.inHours} hours ago';
          } else {
            return 'Synced ${timeDiff.inDays} days ago';
          }
        }
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.success:
        return 'Sync completed successfully';
      case SyncStatus.error:
        return 'Sync failed: ${state.error}';
      case SyncStatus.conflict:
        return 'Sync conflicts detected';
    }
  }

  /// Get overall sync progress
  double get overallProgress {
    if (state.syncProgress.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (final progress in state.syncProgress.values) {
      totalProgress += progress.progress;
    }

    return totalProgress / state.syncProgress.length;
  }

  /// Check if sync is available
  bool get canSync {
    return state.isConnected && !state.isSyncing;
  }
}