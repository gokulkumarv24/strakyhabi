import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'user_model.g.dart';

@HiveType(typeId: 4)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? avatar;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime lastLogin;

  @HiveField(6)
  UserPreferences preferences;

  @HiveField(7)
  SubscriptionTier subscriptionTier;

  @HiveField(8)
  DateTime? subscriptionExpiry;

  @HiveField(9)
  String? jwtToken;

  @HiveField(10)
  Map<String, dynamic> streakData;

  @HiveField(11)
  List<String> achievements;

  @HiveField(12)
  int totalTasksCompleted;

  @HiveField(13)
  bool needsSync;

  User({
    String? id,
    required this.name,
    required this.email,
    this.avatar,
    DateTime? createdAt,
    DateTime? lastLogin,
    UserPreferences? preferences,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.jwtToken,
    Map<String, dynamic>? streakData,
    List<String>? achievements,
    this.totalTasksCompleted = 0,
    this.needsSync = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now(),
        preferences = preferences ?? UserPreferences(),
        streakData = streakData ?? {},
        achievements = achievements ?? [];

  // Check if user has premium access
  bool get isPremium {
    if (subscriptionTier == SubscriptionTier.free) return false;
    if (subscriptionExpiry == null) return true; // Lifetime
    return DateTime.now().isBefore(subscriptionExpiry!);
  }

  // Update user profile
  void updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) {
    if (name != null) this.name = name;
    if (email != null) this.email = email;
    if (avatar != null) this.avatar = avatar;
    needsSync = true;
    save();
  }

  // Update last login
  void updateLastLogin() {
    lastLogin = DateTime.now();
    needsSync = true;
    save();
  }

  // Increment completed tasks
  void incrementTasksCompleted() {
    totalTasksCompleted++;
    needsSync = true;
    save();
  }

  // Add achievement
  void addAchievement(String achievement) {
    if (!achievements.contains(achievement)) {
      achievements.add(achievement);
      needsSync = true;
      save();
    }
  }

  // Update subscription
  void updateSubscription({
    required SubscriptionTier tier,
    DateTime? expiry,
  }) {
    subscriptionTier = tier;
    subscriptionExpiry = expiry;
    needsSync = true;
    save();
  }

  // Convert to JSON for API sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'preferences': preferences.toJson(),
      'subscriptionTier': subscriptionTier.index,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'streakData': streakData,
      'achievements': achievements,
      'totalTasksCompleted': totalTasksCompleted,
    };
  }

  // Create from JSON (for API sync)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
      preferences: UserPreferences.fromJson(json['preferences']),
      subscriptionTier: SubscriptionTier.values[json['subscriptionTier']],
      subscriptionExpiry: json['subscriptionExpiry'] != null
          ? DateTime.parse(json['subscriptionExpiry'])
          : null,
      streakData: Map<String, dynamic>.from(json['streakData'] ?? {}),
      achievements: List<String>.from(json['achievements'] ?? []),
      totalTasksCompleted: json['totalTasksCompleted'] ?? 0,
      needsSync: false, // Synced from server
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, tier: $subscriptionTier)';
  }
}

@HiveType(typeId: 5)
class UserPreferences extends HiveObject {
  @HiveField(0)
  bool notificationsEnabled;

  @HiveField(1)
  bool dailyRemindersEnabled;

  @HiveField(2)
  TimeOfDay dailyReminderTime;

  @HiveField(3)
  bool streakNotificationsEnabled;

  @HiveField(4)
  ThemeMode themeMode;

  @HiveField(5)
  String language;

  @HiveField(6)
  bool aiSuggestionsEnabled;

  @HiveField(7)
  bool socialFeaturesEnabled;

  @HiveField(8)
  int productivityGoal; // Tasks per day

  @HiveField(9)
  List<String> preferredCategories;

  UserPreferences({
    this.notificationsEnabled = true,
    this.dailyRemindersEnabled = true,
    TimeOfDay? dailyReminderTime,
    this.streakNotificationsEnabled = true,
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.aiSuggestionsEnabled = true,
    this.socialFeaturesEnabled = true,
    this.productivityGoal = 3,
    List<String>? preferredCategories,
  })  : dailyReminderTime = dailyReminderTime ?? const TimeOfDay(hour: 9, minute: 0),
        preferredCategories = preferredCategories ?? ['Work', 'Personal', 'Health'];

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'dailyRemindersEnabled': dailyRemindersEnabled,
      'dailyReminderTime': {
        'hour': dailyReminderTime.hour,
        'minute': dailyReminderTime.minute,
      },
      'streakNotificationsEnabled': streakNotificationsEnabled,
      'themeMode': themeMode.index,
      'language': language,
      'aiSuggestionsEnabled': aiSuggestionsEnabled,
      'socialFeaturesEnabled': socialFeaturesEnabled,
      'productivityGoal': productivityGoal,
      'preferredCategories': preferredCategories,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final timeData = json['dailyReminderTime'];
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      dailyRemindersEnabled: json['dailyRemindersEnabled'] ?? true,
      dailyReminderTime: timeData != null
          ? TimeOfDay(hour: timeData['hour'], minute: timeData['minute'])
          : const TimeOfDay(hour: 9, minute: 0),
      streakNotificationsEnabled: json['streakNotificationsEnabled'] ?? true,
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      language: json['language'] ?? 'en',
      aiSuggestionsEnabled: json['aiSuggestionsEnabled'] ?? true,
      socialFeaturesEnabled: json['socialFeaturesEnabled'] ?? true,
      productivityGoal: json['productivityGoal'] ?? 3,
      preferredCategories: List<String>.from(json['preferredCategories'] ?? []),
    );
  }
}

@HiveType(typeId: 6)
enum SubscriptionTier {
  @HiveField(0)
  free,
  @HiveField(1)
  premium,
  @HiveField(2)
  team,
}

@HiveType(typeId: 7)
enum ThemeMode {
  @HiveField(0)
  system,
  @HiveField(1)
  light,
  @HiveField(2)
  dark,
}

@HiveType(typeId: 8)
class TimeOfDay extends HiveObject {
  @HiveField(0)
  final int hour;

  @HiveField(1)
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  @override
  String toString() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  @override
  bool operator ==(Object other) {
    return other is TimeOfDay && 
           other.hour == hour && 
           other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);
}