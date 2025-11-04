import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:streaky_app/services/jwt_service.dart';
import 'package:streaky_app/services/local_storage.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/models/user_model.dart';
import 'package:streaky_app/models/streak_model.dart';

/// Service for interacting with Cloudflare Worker API
class KvService {
  static const String _baseUrl = 'https://your-worker.your-subdomain.workers.dev';
  static const Duration _timeout = Duration(seconds: 30);
  
  late final Dio _dio;
  String? _currentToken;

  KvService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[API] $obj'),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token to requests
        if (_currentToken != null) {
          options.headers['Authorization'] = 'Bearer $_currentToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        _handleApiError(error);
        handler.next(error);
      },
    ));
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _currentToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _currentToken = null;
  }

  // AUTH ENDPOINTS

  /// Register new user
  Future<ApiResponse<User>> registerUser({
    required String name,
    required String email,
    String? password,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final userData = response.data['user'];
      final token = response.data['token'];
      final user = User.fromJson(userData);

      setAuthToken(token);
      
      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Login user
  Future<ApiResponse<User>> loginUser({
    required String email,
    String? password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final userData = response.data['user'];
      final token = response.data['token'];
      final user = User.fromJson(userData);

      setAuthToken(token);
      
      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Verify token
  Future<ApiResponse<bool>> verifyToken(String token) async {
    try {
      final response = await _dio.post('/auth/verify', data: {
        'token': token,
      });

      return ApiResponse.success(response.data['valid'] ?? false);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  // TASK ENDPOINTS

  /// Sync tasks to cloud
  Future<ApiResponse<List<Task>>> syncTasks({
    required List<Task> localTasks,
    DateTime? lastSyncTime,
  }) async {
    try {
      final tasksData = localTasks.map((task) => task.toJson()).toList();
      
      final response = await _dio.post('/tasks/sync', data: {
        'tasks': tasksData,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      });

      final serverTasks = (response.data['tasks'] as List)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();

      return ApiResponse.success(serverTasks);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Get tasks from server
  Future<ApiResponse<List<Task>>> getTasks({
    DateTime? since,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }

      final response = await _dio.get('/tasks', queryParameters: queryParams);

      final tasks = (response.data['tasks'] as List)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();

      return ApiResponse.success(tasks);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Create task on server
  Future<ApiResponse<Task>> createTask(Task task) async {
    try {
      final response = await _dio.post('/tasks', data: task.toJson());
      final createdTask = Task.fromJson(response.data['task']);
      return ApiResponse.success(createdTask);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Update task on server
  Future<ApiResponse<Task>> updateTask(Task task) async {
    try {
      final response = await _dio.put('/tasks/${task.id}', data: task.toJson());
      final updatedTask = Task.fromJson(response.data['task']);
      return ApiResponse.success(updatedTask);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Delete task on server
  Future<ApiResponse<bool>> deleteTask(String taskId) async {
    try {
      await _dio.delete('/tasks/$taskId');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  // STREAK ENDPOINTS

  /// Sync streaks to cloud
  Future<ApiResponse<List<Streak>>> syncStreaks({
    required List<Streak> localStreaks,
    DateTime? lastSyncTime,
  }) async {
    try {
      final streaksData = localStreaks.map((streak) => streak.toJson()).toList();
      
      final response = await _dio.post('/streaks/sync', data: {
        'streaks': streaksData,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      });

      final serverStreaks = (response.data['streaks'] as List)
          .map((streakJson) => Streak.fromJson(streakJson))
          .toList();

      return ApiResponse.success(serverStreaks);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Get leaderboard
  Future<ApiResponse<List<Map<String, dynamic>>>> getLeaderboard({
    String? category,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _dio.get('/streaks/leaderboard', 
          queryParameters: queryParams);

      final leaderboard = List<Map<String, dynamic>>.from(
          response.data['leaderboard'] ?? []);

      return ApiResponse.success(leaderboard);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  // USER ENDPOINTS

  /// Update user profile
  Future<ApiResponse<User>> updateUserProfile(User user) async {
    try {
      final response = await _dio.put('/user/profile', data: user.toJson());
      final updatedUser = User.fromJson(response.data['user']);
      return ApiResponse.success(updatedUser);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Get user analytics
  Future<ApiResponse<Map<String, dynamic>>> getUserAnalytics() async {
    try {
      final response = await _dio.get('/user/analytics');
      return ApiResponse.success(
          Map<String, dynamic>.from(response.data['analytics']));
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  // PREMIUM ENDPOINTS

  /// Verify premium subscription
  Future<ApiResponse<Map<String, dynamic>>> verifyPremiumSubscription({
    required String purchaseToken,
    required String productId,
  }) async {
    try {
      final response = await _dio.post('/premium/verify', data: {
        'purchaseToken': purchaseToken,
        'productId': productId,
      });

      return ApiResponse.success(
          Map<String, dynamic>.from(response.data));
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  // ANALYTICS ENDPOINTS

  /// Log analytics event
  Future<ApiResponse<bool>> logAnalyticsEvent({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _dio.post('/analytics/event', data: {
        'eventName': eventName,
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  // UTILITY METHODS

  /// Check server health
  Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return ApiResponse.success(
          Map<String, dynamic>.from(response.data));
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  /// Handle API errors
  void _handleApiError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        print('[API] Timeout error: ${error.message}');
        break;
      case DioExceptionType.badResponse:
        print('[API] HTTP error: ${error.response?.statusCode}');
        break;
      case DioExceptionType.cancel:
        print('[API] Request cancelled');
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          print('[API] Network error: No internet connection');
        } else {
          print('[API] Unknown error: ${error.message}');
        }
        break;
      default:
        print('[API] Unexpected error: ${error.message}');
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'Server error';
          return 'Server error ($statusCode): $message';
        case DioExceptionType.cancel:
          return 'Request was cancelled';
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'No internet connection. Please check your network.';
          }
          return 'An unexpected error occurred';
        default:
          return error.message ?? 'Unknown error occurred';
      }
    }
    return error.toString();
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse.success(this.data) : error = null, isSuccess = true;
  ApiResponse.error(this.error) : data = null, isSuccess = false;

  bool get hasError => error != null;
}

/// Offline-first sync manager
class SyncManager {
  final KvService _kvService;
  bool _isSyncing = false;

  SyncManager(this._kvService);

  /// Sync all data when online
  Future<bool> syncAll() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    try {
      final user = LocalStorageService.getCurrentUser();
      if (user?.jwtToken == null) return false;

      _kvService.setAuthToken(user!.jwtToken!);

      // Sync tasks
      final tasksNeedingSync = LocalStorageService.getTasksNeedingSync();
      if (tasksNeedingSync.isNotEmpty) {
        final tasksResponse = await _kvService.syncTasks(
          localTasks: tasksNeedingSync,
          lastSyncTime: LocalStorageService.getLastSyncTime(),
        );

        if (tasksResponse.isSuccess) {
          // Mark tasks as synced
          for (final task in tasksNeedingSync) {
            await LocalStorageService.markTaskSynced(task.id);
          }
        }
      }

      // Sync streaks
      final streaksNeedingSync = LocalStorageService.getStreaksNeedingSync();
      if (streaksNeedingSync.isNotEmpty) {
        final streaksResponse = await _kvService.syncStreaks(
          localStreaks: streaksNeedingSync,
          lastSyncTime: LocalStorageService.getLastSyncTime(),
        );

        if (streaksResponse.isSuccess) {
          // Handle streak sync response
          final serverStreaks = streaksResponse.data!;
          for (final streak in serverStreaks) {
            await LocalStorageService.saveStreak(streak);
          }
        }
      }

      // Update last sync time
      await LocalStorageService.updateLastSyncTime();
      
      return true;
    } catch (e) {
      print('[Sync] Error during sync: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;
}