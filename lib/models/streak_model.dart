import 'package:hive/hive.dart';

part 'streak_model.g.dart';

@HiveType(typeId: 9)
class Streak extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String taskId;

  @HiveField(3)
  final String category;

  @HiveField(4)
  int currentStreak;

  @HiveField(5)
  int longestStreak;

  @HiveField(6)
  DateTime lastCompletedDate;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime lastUpdated;

  @HiveField(9)
  List<DateTime> completionDates;

  @HiveField(10)
  Map<String, int> weeklyStats; // Week -> completion count

  @HiveField(11)
  Map<String, int> monthlyStats; // Month -> completion count

  @HiveField(12)
  bool isActive;

  @HiveField(13)
  StreakType type;

  @HiveField(14)
  bool needsSync;

  Streak({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.category,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastCompletedDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<DateTime>? completionDates,
    Map<String, int>? weeklyStats,
    Map<String, int>? monthlyStats,
    this.isActive = true,
    this.type = StreakType.daily,
    this.needsSync = true,
  })  : lastCompletedDate = lastCompletedDate ?? DateTime.now().subtract(const Duration(days: 1)),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now(),
        completionDates = completionDates ?? [],
        weeklyStats = weeklyStats ?? {},
        monthlyStats = monthlyStats ?? {};

  // Update streak when task is completed
  void updateStreak(DateTime completionDate) {
    final today = DateTime.now();
    final completionDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
    final lastCompletedDay = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
    
    // Check if already completed today
    if (completionDates.any((date) => 
        date.year == completionDay.year && 
        date.month == completionDay.month && 
        date.day == completionDay.day)) {
      return; // Already counted for today
    }

    // Add to completion dates
    completionDates.add(completionDate);
    
    // Update streak count
    if (type == StreakType.daily) {
      if (completionDay.difference(lastCompletedDay).inDays == 1) {
        // Consecutive day
        currentStreak++;
      } else if (completionDay.difference(lastCompletedDay).inDays == 0) {
        // Same day, no change needed
        return;
      } else {
        // Streak broken, restart
        currentStreak = 1;
      }
    }
    
    // Update longest streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }
    
    lastCompletedDate = completionDate;
    lastUpdated = DateTime.now();
    
    // Update statistics
    _updateStats(completionDate);
    
    needsSync = true;
    save();
  }

  // Check if streak should be broken (for daily streaks)
  void checkStreakStatus() {
    if (type != StreakType.daily) return;
    
    final now = DateTime.now();
    final lastDay = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
    final today = DateTime(now.year, now.month, now.day);
    
    // If more than 1 day has passed without completion, break streak
    if (today.difference(lastDay).inDays > 1) {
      currentStreak = 0;
      needsSync = true;
      save();
    }
  }

  // Get streak percentage for current month
  double get monthlyCompletionRate {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final completions = monthlyStats[monthKey] ?? 0;
    return completions / daysInMonth;
  }

  // Get weekly completion rate
  double get weeklyCompletionRate {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
    final completions = weeklyStats[weekKey] ?? 0;
    return completions / 7;
  }

  // Update weekly and monthly statistics
  void _updateStats(DateTime date) {
    // Weekly stats
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final weekKey = '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
    weeklyStats[weekKey] = (weeklyStats[weekKey] ?? 0) + 1;
    
    // Monthly stats
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
  }

  // Get completion dates for visualization
  List<DateTime> getCompletionDatesInRange(DateTime start, DateTime end) {
    return completionDates.where((date) => 
        date.isAfter(start.subtract(const Duration(days: 1))) && 
        date.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  // Convert to JSON for API sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'taskId': taskId,
      'category': category,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'completionDates': completionDates.map((d) => d.toIso8601String()).toList(),
      'weeklyStats': weeklyStats,
      'monthlyStats': monthlyStats,
      'isActive': isActive,
      'type': type.index,
    };
  }

  // Create from JSON (for API sync)
  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      id: json['id'],
      userId: json['userId'],
      taskId: json['taskId'],
      category: json['category'],
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      lastCompletedDate: DateTime.parse(json['lastCompletedDate']),
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      completionDates: (json['completionDates'] as List)
          .map((d) => DateTime.parse(d))
          .toList(),
      weeklyStats: Map<String, int>.from(json['weeklyStats'] ?? {}),
      monthlyStats: Map<String, int>.from(json['monthlyStats'] ?? {}),
      isActive: json['isActive'] ?? true,
      type: StreakType.values[json['type'] ?? 0],
      needsSync: false, // Synced from server
    );
  }

  @override
  String toString() {
    return 'Streak(id: $id, category: $category, current: $currentStreak, longest: $longestStreak)';
  }
}

@HiveType(typeId: 10)
enum StreakType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
}

@HiveType(typeId: 11)
class StreakAnalytics extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  int totalCompletedTasks;

  @HiveField(2)
  int totalActiveStreaks;

  @HiveField(3)
  int longestOverallStreak;

  @HiveField(4)
  Map<String, int> categoryStats; // category -> completed count

  @HiveField(5)
  Map<String, double> productivityByHour; // hour -> completion rate

  @HiveField(6)
  Map<String, int> weekdayStats; // weekday -> completion count

  @HiveField(7)
  DateTime lastCalculated;

  @HiveField(8)
  bool needsSync;

  StreakAnalytics({
    required this.userId,
    this.totalCompletedTasks = 0,
    this.totalActiveStreaks = 0,
    this.longestOverallStreak = 0,
    Map<String, int>? categoryStats,
    Map<String, double>? productivityByHour,
    Map<String, int>? weekdayStats,
    DateTime? lastCalculated,
    this.needsSync = true,
  })  : categoryStats = categoryStats ?? {},
        productivityByHour = productivityByHour ?? {},
        weekdayStats = weekdayStats ?? {},
        lastCalculated = lastCalculated ?? DateTime.now();

  // Calculate analytics from streaks
  void calculateFromStreaks(List<Streak> streaks) {
    totalActiveStreaks = streaks.where((s) => s.isActive).length;
    longestOverallStreak = streaks.map((s) => s.longestStreak).fold(0, (a, b) => a > b ? a : b);
    
    categoryStats.clear();
    weekdayStats.clear();
    
    totalCompletedTasks = 0;
    
    for (final streak in streaks) {
      // Category stats
      categoryStats[streak.category] = (categoryStats[streak.category] ?? 0) + streak.completionDates.length;
      
      // Total completed tasks
      totalCompletedTasks += streak.completionDates.length;
      
      // Weekday stats
      for (final date in streak.completionDates) {
        final weekday = date.weekday.toString();
        weekdayStats[weekday] = (weekdayStats[weekday] ?? 0) + 1;
      }
    }
    
    lastCalculated = DateTime.now();
    needsSync = true;
    save();
  }

  // Get most productive day of week
  String get mostProductiveWeekday {
    if (weekdayStats.isEmpty) return 'Monday';
    
    final sorted = weekdayStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayIndex = int.parse(sorted.first.key) - 1;
    return weekdays[dayIndex];
  }

  // Get most active category
  String get mostActiveCategory {
    if (categoryStats.isEmpty) return 'Personal';
    
    final sorted = categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalCompletedTasks': totalCompletedTasks,
      'totalActiveStreaks': totalActiveStreaks,
      'longestOverallStreak': longestOverallStreak,
      'categoryStats': categoryStats,
      'productivityByHour': productivityByHour,
      'weekdayStats': weekdayStats,
      'lastCalculated': lastCalculated.toIso8601String(),
    };
  }

  factory StreakAnalytics.fromJson(Map<String, dynamic> json) {
    return StreakAnalytics(
      userId: json['userId'],
      totalCompletedTasks: json['totalCompletedTasks'] ?? 0,
      totalActiveStreaks: json['totalActiveStreaks'] ?? 0,
      longestOverallStreak: json['longestOverallStreak'] ?? 0,
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
      productivityByHour: Map<String, double>.from(json['productivityByHour'] ?? {}),
      weekdayStats: Map<String, int>.from(json['weekdayStats'] ?? {}),
      lastCalculated: DateTime.parse(json['lastCalculated']),
      needsSync: false,
    );
  }
}