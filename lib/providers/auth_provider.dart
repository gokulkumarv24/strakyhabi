import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streaky_app/models/user_model.dart';
import 'package:streaky_app/services/local_storage.dart';
import 'package:streaky_app/services/jwt_service.dart';
import 'package:streaky_app/services/kv_service.dart';

/// Provider for managing user authentication and profile state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Authentication state class
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool isSyncing;
  final DateTime? lastSyncTime;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.isSyncing = false,
    this.lastSyncTime,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? isSyncing,
    DateTime? lastSyncTime,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser != null) {
        state = state.copyWith(
          user: currentUser,
          isAuthenticated: true,
          isLoading: false,
        );
        
        // Validate token
        final isValid = await JwtService.validateToken(currentUser.token);
        if (!isValid) {
          await logout();
          return;
        }

        // Start background sync
        await _performBackgroundSync();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sign in user
  Future<void> signIn({
    required String email,
    required String name,
    String? deviceId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Generate JWT token
      final token = JwtService.generateToken(
        email: email,
        name: name,
        deviceId: deviceId,
      );

      // Create user object
      final user = User(
        email: email,
        name: name,
        token: token,
        deviceId: deviceId,
        lastLoginAt: DateTime.now(),
      );

      // Save user locally
      await LocalStorageService.saveUser(user);

      // Update state
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );

      // Sync with server
      await _performBackgroundSync();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sign out user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Sync final data before logout
      if (state.user != null) {
        await _performBackgroundSync();
      }

      // Clear local data
      await LocalStorageService.clearUserData();

      // Reset state
      state = const AuthState();
    } catch (e) {
      // Force logout even if sync fails
      await LocalStorageService.clearUserData();
      state = const AuthState();
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    Map<String, dynamic>? preferences,
    String? timezone,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
  }) async {
    if (state.user == null) return;

    try {
      final updatedUser = state.user!.copyWith(
        name: name,
        preferences: preferences,
        timezone: timezone,
        notificationSettings: notificationSettings,
        privacySettings: privacySettings,
      );

      // Save locally
      await LocalStorageService.saveUser(updatedUser);

      // Update state
      state = state.copyWith(user: updatedUser);

      // Sync to server
      await _syncUserData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Upgrade to premium
  Future<void> upgradeToPremium() async {
    if (state.user == null) return;

    try {
      final updatedUser = state.user!.copyWith(
        subscriptionTier: SubscriptionTier.premium,
        subscriptionStartDate: DateTime.now(),
      );

      // Save locally
      await LocalStorageService.saveUser(updatedUser);

      // Update state
      state = state.copyWith(user: updatedUser);

      // Sync to server
      await _syncUserData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Downgrade to free
  Future<void> downgradeToFree() async {
    if (state.user == null) return;

    try {
      final updatedUser = state.user!.copyWith(
        subscriptionTier: SubscriptionTier.free,
        subscriptionStartDate: null,
        subscriptionEndDate: DateTime.now(),
      );

      // Save locally
      await LocalStorageService.saveUser(updatedUser);

      // Update state
      state = state.copyWith(user: updatedUser);

      // Sync to server
      await _syncUserData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    if (state.user == null || state.isSyncing) return;

    state = state.copyWith(isSyncing: true);

    try {
      await KvService.syncAllData();
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Sync failed: ${e.toString()}',
      );
    }
  }

  /// Sync user data to server
  Future<void> _syncUserData() async {
    if (state.user == null) return;

    try {
      await KvService.syncUserProfile(state.user!);
    } catch (e) {
      // Don't update error state for silent sync
      print('User sync failed: $e');
    }
  }

  /// Manual sync trigger
  Future<void> syncData() async {
    await _performBackgroundSync();
  }

  /// Check if user is premium
  bool get isPremium {
    return state.user?.subscriptionTier == SubscriptionTier.premium;
  }

  /// Check if user has valid subscription
  bool get hasValidSubscription {
    if (state.user?.subscriptionTier != SubscriptionTier.premium) {
      return false;
    }

    if (state.user?.subscriptionEndDate != null) {
      return state.user!.subscriptionEndDate!.isAfter(DateTime.now());
    }

    return true; // No end date means active subscription
  }

  /// Get subscription days remaining
  int? get subscriptionDaysRemaining {
    if (!hasValidSubscription) return null;

    if (state.user?.subscriptionEndDate != null) {
      final daysRemaining = state.user!.subscriptionEndDate!
          .difference(DateTime.now())
          .inDays;
      return daysRemaining > 0 ? daysRemaining : 0;
    }

    return null; // Unlimited
  }

  /// Get user statistics
  Map<String, dynamic> getUserStats() {
    if (state.user == null) return {};

    final user = state.user!;
    final daysSinceJoin = DateTime.now()
        .difference(user.createdAt)
        .inDays;

    final stats = LocalStorageService.getUserStats();

    return {
      'daysSinceJoin': daysSinceJoin,
      'totalTasks': stats['totalTasks'] ?? 0,
      'completedTasks': stats['completedTasks'] ?? 0,
      'currentStreak': stats['currentStreak'] ?? 0,
      'longestStreak': stats['longestStreak'] ?? 0,
      'totalProductiveMinutes': stats['totalProductiveMinutes'] ?? 0,
      'averageCompletionRate': stats['averageCompletionRate'] ?? 0.0,
      'favoriteCategory': stats['favoriteCategory'] ?? 'General',
      'subscriptionTier': user.subscriptionTier.toString().split('.').last,
      'hasValidSubscription': hasValidSubscription,
      'subscriptionDaysRemaining': subscriptionDaysRemaining,
    };
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    await updateProfile(notificationSettings: settings);
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    await updateProfile(privacySettings: settings);
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // Delete from server
      await KvService.deleteUserAccount(state.user!.id);

      // Clear all local data
      await LocalStorageService.clearAllData();

      // Reset state
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData() async {
    if (state.user == null) return {};

    try {
      return await LocalStorageService.exportUserData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  /// Import user data
  Future<void> importUserData(Map<String, dynamic> data) async {
    if (state.user == null) return;

    try {
      await LocalStorageService.importUserData(data);
      await _performBackgroundSync();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if sync is needed
  bool get needsSync {
    if (state.lastSyncTime == null) return true;
    
    final timeSinceSync = DateTime.now()
        .difference(state.lastSyncTime!)
        .inMinutes;
    
    return timeSinceSync > 30; // Sync every 30 minutes
  }

  /// Force refresh user data
  Future<void> refreshUserData() async {
    if (state.user == null) return;

    try {
      final refreshedUser = LocalStorageService.getCurrentUser();
      if (refreshedUser != null) {
        state = state.copyWith(user: refreshedUser);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    if (state.user == null) return;

    try {
      final updatedUser = state.user!.copyWith(lastActiveAt: DateTime.now());
      await LocalStorageService.saveUser(updatedUser);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      // Silent fail for activity tracking
    }
  }

  /// Get offline sync queue count
  int get offlineSyncQueueCount {
    try {
      return LocalStorageService.getOfflineSyncQueueCount();
    } catch (e) {
      return 0;
    }
  }
}