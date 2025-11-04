import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:streaky_app/services/local_storage.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/models/user_model.dart';

/// Service for managing local notifications and reminders
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle navigation based on payload
      // This would integrate with your router
      print('Notification tapped: $payload');
    }
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Assume granted on other platforms
  }

  /// Schedule task reminder
  static Future<void> scheduleTaskReminder({
    required Task task,
    required DateTime reminderTime,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for scheduled tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'task_reminder',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      task.id.hashCode, // Use task ID as notification ID
      'Task Reminder',
      'Don\'t forget: ${task.title}',
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      payload: 'task:${task.id}',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule daily reminder
  static Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    String title = 'Daily Productivity Check',
    String body = 'How are your streaks going today?',
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has passed today, schedule for tomorrow
    final targetTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Daily productivity reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'daily_reminder',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      999, // Fixed ID for daily reminder
      title,
      body,
      tz.TZDateTime.from(targetTime, tz.local),
      notificationDetails,
      payload: 'daily_reminder',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Show streak milestone notification
  static Future<void> showStreakMilestone({
    required String category,
    required int streakCount,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streak_milestones',
      'Streak Milestones',
      channelDescription: 'Celebrate your streak achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'streak_milestone',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String title = '🔥 Streak Milestone!';
    String body = 'You\'ve reached $streakCount days in $category!';

    // Customize message based on milestone
    if (streakCount == 7) {
      title = '🎉 One Week Streak!';
      body = 'Amazing! You\'ve maintained your $category habit for a week!';
    } else if (streakCount == 30) {
      title = '🏆 One Month Streak!';
      body = 'Incredible! $streakCount days of $category - you\'re unstoppable!';
    } else if (streakCount == 100) {
      title = '👑 Century Streak!';
      body = 'LEGENDARY! $streakCount days of $category - you\'re a habit master!';
    }

    await _notifications.show(
      streakCount.hashCode + category.hashCode,
      title,
      body,
      notificationDetails,
      payload: 'streak:$category:$streakCount',
    );
  }

  /// Show streak broken notification
  static Future<void> showStreakBroken({
    required String category,
    required int lastStreak,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streak_broken',
      'Streak Updates',
      channelDescription: 'Updates about your streaks',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'streak_update',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      category.hashCode + 1000,
      'Streak Reset',
      'Your $category streak of $lastStreak days has reset. Ready to start again?',
      notificationDetails,
      payload: 'streak_broken:$category',
    );
  }

  /// Cancel task reminder
  static Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  /// Cancel daily reminder
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(999);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Schedule notifications for all tasks
  static Future<void> scheduleAllTaskReminders() async {
    final user = LocalStorageService.getCurrentUser();
    if (user?.preferences.notificationsEnabled != true) return;

    final tasks = LocalStorageService.getTasksWhere(isCompleted: false);
    
    for (final task in tasks) {
      if (task.dueDate != null) {
        // Schedule reminder 1 hour before due time
        final reminderTime = task.dueDate!.subtract(const Duration(hours: 1));
        
        // Only schedule if reminder time is in the future
        if (reminderTime.isAfter(DateTime.now())) {
          await scheduleTaskReminder(
            task: task,
            reminderTime: reminderTime,
          );
        }
      }
    }
  }

  /// Setup daily reminders based on user preferences
  static Future<void> setupDailyReminders() async {
    final user = LocalStorageService.getCurrentUser();
    if (user?.preferences.dailyRemindersEnabled != true) return;

    await scheduleDailyReminder(
      time: user!.preferences.dailyReminderTime,
      title: 'Daily Productivity Check',
      body: 'Time to check your tasks and maintain your streaks!',
    );
  }

  /// Check and notify about streak milestones
  static Future<void> checkStreakMilestones() async {
    final user = LocalStorageService.getCurrentUser();
    if (user?.preferences.streakNotificationsEnabled != true) return;

    final streaks = LocalStorageService.getStreaksForUser(user!.id);
    
    for (final streak in streaks) {
      if (streak.isActive) {
        // Check for milestone notifications (7, 14, 30, 50, 100 days)
        final milestones = [7, 14, 30, 50, 100];
        if (milestones.contains(streak.currentStreak)) {
          await showStreakMilestone(
            category: streak.category,
            streakCount: streak.currentStreak,
          );
        }
      }
    }
  }

  /// Show immediate notification
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
    String channelName = 'General Notifications',
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Update notification settings based on user preferences
  static Future<void> updateNotificationSettings(UserPreferences preferences) async {
    // Cancel all existing notifications
    await cancelAllNotifications();

    // Reschedule based on new preferences
    if (preferences.notificationsEnabled) {
      if (preferences.dailyRemindersEnabled) {
        await setupDailyReminders();
      }
      
      await scheduleAllTaskReminders();
    }
  }
}