import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/models/streak_model.dart';
import 'package:streaky_app/services/local_storage.dart';

/// AI Service for intelligent task recommendations and productivity insights
class AiService {
  static Interpreter? _taskPriorityModel;
  static Interpreter? _productivityModel;
  static Interpreter? _streakPredictionModel;
  
  static bool _isInitialized = false;
  static bool _modelsLoaded = false;

  /// Initialize AI service and load models
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TensorFlow Lite models
      await _loadModels();
      _isInitialized = true;
      _modelsLoaded = true;
    } catch (e) {
      print('AI Service initialization failed: $e');
      _isInitialized = true;
      _modelsLoaded = false;
    }
  }

  /// Load TensorFlow Lite models from assets
  static Future<void> _loadModels() async {
    try {
      // Load task priority prediction model
      _taskPriorityModel = await Interpreter.fromAsset('assets/ai/task_priority_model.tflite');
      
      // Load productivity analysis model
      _productivityModel = await Interpreter.fromAsset('assets/ai/productivity_model.tflite');
      
      // Load streak prediction model
      _streakPredictionModel = await Interpreter.fromAsset('assets/ai/streak_prediction_model.tflite');
      
      print('AI models loaded successfully');
    } catch (e) {
      print('Failed to load AI models: $e');
      throw e;
    }
  }

  /// Check if AI features are available
  static bool get isAvailable => _isInitialized && _modelsLoaded;

  /// Dispose AI service and release resources
  static void dispose() {
    _taskPriorityModel?.close();
    _productivityModel?.close();
    _streakPredictionModel?.close();
    
    _taskPriorityModel = null;
    _productivityModel = null;
    _streakPredictionModel = null;
    
    _isInitialized = false;
    _modelsLoaded = false;
  }

  /// Predict optimal task priority based on context
  static Future<TaskPriority> predictTaskPriority({
    required String title,
    required String? description,
    required DateTime? dueDate,
    required String? category,
    required int estimatedMinutes,
    required List<String>? tags,
  }) async {
    if (!isAvailable || _taskPriorityModel == null) {
      return _fallbackPriorityPrediction(title, dueDate, estimatedMinutes);
    }

    try {
      // Prepare input features
      final features = _extractTaskFeatures(
        title: title,
        description: description,
        dueDate: dueDate,
        category: category,
        estimatedMinutes: estimatedMinutes,
        tags: tags,
      );

      // Run inference
      final input = [features];
      final output = List.filled(4, 0.0).reshape([1, 4]);
      
      _taskPriorityModel!.run(input, output);

      // Convert output to priority
      final probabilities = output[0] as List<double>;
      final maxIndex = probabilities.indexWhere(
        (prob) => prob == probabilities.reduce((a, b) => a > b ? a : b),
      );

      return TaskPriority.values[maxIndex];
    } catch (e) {
      print('Task priority prediction failed: $e');
      return _fallbackPriorityPrediction(title, dueDate, estimatedMinutes);
    }
  }

  /// Analyze productivity patterns and provide insights
  static Future<ProductivityInsights> analyzeProductivity({
    int daysToAnalyze = 30,
  }) async {
    if (!isAvailable || _productivityModel == null) {
      return _fallbackProductivityAnalysis(daysToAnalyze);
    }

    try {
      // Get user data for analysis
      final tasks = LocalStorageService.getAllTasks();
      final streaks = LocalStorageService.getAllStreaks();
      
      // Prepare productivity features
      final features = _extractProductivityFeatures(tasks, streaks, daysToAnalyze);

      // Run inference
      final input = [features];
      final output = List.filled(10, 0.0).reshape([1, 10]);
      
      _productivityModel!.run(input, output);

      // Parse output into insights
      return _parseProductivityOutput(output[0] as List<double>);
    } catch (e) {
      print('Productivity analysis failed: $e');
      return _fallbackProductivityAnalysis(daysToAnalyze);
    }
  }

  /// Predict streak continuation probability
  static Future<StreakPrediction> predictStreakContinuation(Streak streak) async {
    if (!isAvailable || _streakPredictionModel == null) {
      return _fallbackStreakPrediction(streak);
    }

    try {
      // Prepare streak features
      final features = _extractStreakFeatures(streak);

      // Run inference
      final input = [features];
      final output = List.filled(3, 0.0).reshape([1, 3]);
      
      _streakPredictionModel!.run(input, output);

      // Parse output
      final probabilities = output[0] as List<double>;
      return StreakPrediction(
        continuationProbability: probabilities[0],
        riskLevel: _getRiskLevel(probabilities[1]),
        recommendations: _generateStreakRecommendations(probabilities),
      );
    } catch (e) {
      print('Streak prediction failed: $e');
      return _fallbackStreakPrediction(streak);
    }
  }

  /// Generate smart task suggestions based on user patterns
  static Future<List<TaskSuggestion>> generateTaskSuggestions({
    int maxSuggestions = 5,
  }) async {
    try {
      final tasks = LocalStorageService.getAllTasks();
      final now = DateTime.now();
      
      final suggestions = <TaskSuggestion>[];

      // Analyze patterns
      final patterns = _analyzeTaskPatterns(tasks);
      
      // Generate suggestions based on patterns
      if (patterns.hasRecurringTasks) {
        suggestions.addAll(_suggestRecurringTasks(patterns));
      }
      
      if (patterns.hasMissedDeadlines) {
        suggestions.addAll(_suggestDeadlineManagement(patterns));
      }
      
      if (patterns.hasLowProductivityPeriods) {
        suggestions.addAll(_suggestProductivityBoosts(patterns));
      }
      
      // Add time-based suggestions
      suggestions.addAll(_suggestTimeBasedTasks(now));
      
      // Sort by relevance and limit
      suggestions.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      return suggestions.take(maxSuggestions).toList();
    } catch (e) {
      print('Task suggestion generation failed: $e');
      return [];
    }
  }

  /// Get personalized productivity tips
  static Future<List<ProductivityTip>> getProductivityTips() async {
    try {
      final tasks = LocalStorageService.getAllTasks();
      final streaks = LocalStorageService.getAllStreaks();
      final analytics = LocalStorageService.getAnalyticsData();
      
      final tips = <ProductivityTip>[];
      
      // Analyze completion patterns
      final completionRate = _calculateCompletionRate(tasks);
      if (completionRate < 0.7) {
        tips.add(ProductivityTip(
          id: 'completion_rate',
          title: 'Improve Task Completion',
          description: 'Your completion rate is ${(completionRate * 100).toInt()}%. Try breaking large tasks into smaller ones.',
          priority: TipPriority.high,
          category: TipCategory.habits,
        ));
      }
      
      // Analyze time patterns
      final peakHours = _identifyPeakProductivityHours(tasks);
      if (peakHours.isNotEmpty) {
        tips.add(ProductivityTip(
          id: 'peak_hours',
          title: 'Optimize Your Schedule',
          description: 'You\'re most productive at ${peakHours.join(", ")}. Schedule important tasks during these hours.',
          priority: TipPriority.medium,
          category: TipCategory.scheduling,
        ));
      }
      
      // Analyze streak patterns
      final streakTips = _analyzeStreakPatterns(streaks);
      tips.addAll(streakTips);
      
      return tips;
    } catch (e) {
      print('Productivity tips generation failed: $e');
      return _getDefaultProductivityTips();
    }
  }

  // Helper methods for feature extraction

  /// Extract features from task data for ML models
  static List<double> _extractTaskFeatures({
    required String title,
    required String? description,
    required DateTime? dueDate,
    required String? category,
    required int estimatedMinutes,
    required List<String>? tags,
  }) {
    final features = <double>[];
    
    // Text features (simplified - in production, use proper NLP)
    features.add(title.length.toDouble());
    features.add(description?.length.toDouble() ?? 0.0);
    features.add(title.toLowerCase().contains('urgent') ? 1.0 : 0.0);
    features.add(title.toLowerCase().contains('important') ? 1.0 : 0.0);
    
    // Time features
    if (dueDate != null) {
      final hoursUntilDue = dueDate.difference(DateTime.now()).inHours.toDouble();
      features.add(hoursUntilDue);
      features.add(hoursUntilDue < 24 ? 1.0 : 0.0); // Due today
      features.add(hoursUntilDue < 0 ? 1.0 : 0.0);  // Overdue
    } else {
      features.addAll([0.0, 0.0, 0.0]);
    }
    
    // Duration features
    features.add(estimatedMinutes.toDouble());
    features.add(estimatedMinutes > 60 ? 1.0 : 0.0); // Long task
    
    // Category features (one-hot encoding for common categories)
    final commonCategories = ['work', 'personal', 'health', 'learning'];
    for (final cat in commonCategories) {
      features.add(category?.toLowerCase() == cat ? 1.0 : 0.0);
    }
    
    // Tag features
    features.add(tags?.length.toDouble() ?? 0.0);
    
    return features;
  }

  /// Extract productivity features for analysis
  static List<double> _extractProductivityFeatures(
    List<Task> tasks,
    List<Streak> streaks,
    int days,
  ) {
    final features = <double>[];
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    // Task completion metrics
    final recentTasks = tasks.where(
      (task) => task.createdAt.isAfter(startDate),
    ).toList();
    
    features.add(recentTasks.length.toDouble());
    features.add(recentTasks.where((t) => t.isCompleted).length.toDouble());
    features.add(_calculateCompletionRate(recentTasks));
    
    // Time-based metrics
    final hourlyProductivity = List.filled(24, 0.0);
    for (final task in recentTasks.where((t) => t.isCompleted && t.completedAt != null)) {
      hourlyProductivity[task.completedAt!.hour] += 1.0;
    }
    features.addAll(hourlyProductivity);
    
    // Streak metrics
    features.add(streaks.length.toDouble());
    features.add(streaks.where((s) => s.isActive).length.toDouble());
    features.add(streaks.isEmpty ? 0.0 : streaks.map((s) => s.currentCount).reduce((a, b) => a + b).toDouble());
    
    return features;
  }

  /// Extract features from streak data
  static List<double> _extractStreakFeatures(Streak streak) {
    final features = <double>[];
    
    // Basic streak metrics
    features.add(streak.currentCount.toDouble());
    features.add(streak.longestStreak.toDouble());
    features.add(streak.totalDays.toDouble());
    features.add(streak.isActive ? 1.0 : 0.0);
    
    // Recent performance
    final recentDates = streak.completionDates
        .where((date) => date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    features.add(recentDates.length.toDouble());
    
    // Pattern analysis
    if (streak.completionDates.length >= 7) {
      final weekPattern = List.filled(7, 0.0);
      for (final date in streak.completionDates) {
        weekPattern[date.weekday - 1] += 1.0;
      }
      features.addAll(weekPattern);
    } else {
      features.addAll(List.filled(7, 0.0));
    }
    
    return features;
  }

  // Fallback methods for when AI models aren't available

  /// Fallback priority prediction using heuristics
  static TaskPriority _fallbackPriorityPrediction(
    String title,
    DateTime? dueDate,
    int estimatedMinutes,
  ) {
    final urgentKeywords = ['urgent', 'asap', 'emergency', 'critical'];
    final isUrgent = urgentKeywords.any(
      (keyword) => title.toLowerCase().contains(keyword),
    );
    
    if (isUrgent) return TaskPriority.urgent;
    
    if (dueDate != null) {
      final hoursUntilDue = dueDate.difference(DateTime.now()).inHours;
      if (hoursUntilDue < 24) return TaskPriority.high;
      if (hoursUntilDue < 72) return TaskPriority.medium;
    }
    
    if (estimatedMinutes > 120) return TaskPriority.high;
    
    return TaskPriority.medium;
  }

  /// Fallback productivity analysis
  static ProductivityInsights _fallbackProductivityAnalysis(int days) {
    final tasks = LocalStorageService.getAllTasks();
    final completionRate = _calculateCompletionRate(tasks);
    
    return ProductivityInsights(
      overallScore: completionRate * 100,
      completionRate: completionRate,
      averageTasksPerDay: tasks.length / days,
      peakProductivityHours: [9, 10, 14, 15],
      recommendations: [
        'Maintain consistent daily task completion',
        'Focus on high-priority tasks during peak hours',
        'Break large tasks into smaller, manageable pieces',
      ],
      trends: {
        'completion_rate': completionRate > 0.8 ? 'increasing' : 'stable',
        'task_volume': 'stable',
        'productivity_score': 'improving',
      },
    );
  }

  /// Fallback streak prediction
  static StreakPrediction _fallbackStreakPrediction(Streak streak) {
    final recentPerformance = streak.completionDates
        .where((date) => date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;
    
    final continuationProbability = (recentPerformance / 7.0).clamp(0.0, 1.0);
    
    return StreakPrediction(
      continuationProbability: continuationProbability,
      riskLevel: continuationProbability < 0.3 ? RiskLevel.high 
                : continuationProbability < 0.7 ? RiskLevel.medium 
                : RiskLevel.low,
      recommendations: [
        if (continuationProbability < 0.5) 'Set daily reminders for this streak',
        if (continuationProbability < 0.7) 'Track your progress more closely',
        'Celebrate small wins to maintain motivation',
      ],
    );
  }

  // Helper methods for analysis

  /// Calculate task completion rate
  static double _calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((task) => task.isCompleted).length;
    return completed / tasks.length;
  }

  /// Identify peak productivity hours
  static List<int> _identifyPeakProductivityHours(List<Task> tasks) {
    final hourCounts = <int, int>{};
    
    for (final task in tasks.where((t) => t.isCompleted && t.completedAt != null)) {
      final hour = task.completedAt!.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    if (hourCounts.isEmpty) return [];
    
    final maxCount = hourCounts.values.reduce((a, b) => a > b ? a : b);
    return hourCounts.entries
        .where((entry) => entry.value >= maxCount * 0.8)
        .map((entry) => entry.key)
        .toList()
        ..sort();
  }

  /// Get default productivity tips
  static List<ProductivityTip> _getDefaultProductivityTips() {
    return [
      ProductivityTip(
        id: 'daily_planning',
        title: 'Plan Your Day',
        description: 'Start each day by reviewing and prioritizing your tasks.',
        priority: TipPriority.high,
        category: TipCategory.planning,
      ),
      ProductivityTip(
        id: 'break_tasks',
        title: 'Break Down Large Tasks',
        description: 'Divide complex tasks into smaller, actionable steps.',
        priority: TipPriority.medium,
        category: TipCategory.organization,
      ),
      ProductivityTip(
        id: 'eliminate_distractions',
        title: 'Minimize Distractions',
        description: 'Create a focused work environment to improve concentration.',
        priority: TipPriority.medium,
        category: TipCategory.focus,
      ),
    ];
  }

  // Additional helper methods would be implemented here...
  // (Pattern analysis, suggestion generation, etc.)
  
  static TaskPatterns _analyzeTaskPatterns(List<Task> tasks) {
    // Simplified implementation
    return TaskPatterns(
      hasRecurringTasks: tasks.any((t) => t.isRecurring),
      hasMissedDeadlines: tasks.any((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()) && !t.isCompleted),
      hasLowProductivityPeriods: _calculateCompletionRate(tasks) < 0.6,
    );
  }

  static List<TaskSuggestion> _suggestRecurringTasks(TaskPatterns patterns) => [];
  static List<TaskSuggestion> _suggestDeadlineManagement(TaskPatterns patterns) => [];
  static List<TaskSuggestion> _suggestProductivityBoosts(TaskPatterns patterns) => [];
  static List<TaskSuggestion> _suggestTimeBasedTasks(DateTime now) => [];
  static List<ProductivityTip> _analyzeStreakPatterns(List<Streak> streaks) => [];
  
  static RiskLevel _getRiskLevel(double riskScore) {
    if (riskScore > 0.7) return RiskLevel.high;
    if (riskScore > 0.4) return RiskLevel.medium;
    return RiskLevel.low;
  }
  
  static List<String> _generateStreakRecommendations(List<double> probabilities) => [
    'Keep up the great work!',
    'Stay consistent with your routine',
  ];
  
  static ProductivityInsights _parseProductivityOutput(List<double> output) {
    return ProductivityInsights(
      overallScore: output[0] * 100,
      completionRate: output[1],
      averageTasksPerDay: output[2],
      peakProductivityHours: [9, 14],
      recommendations: ['Stay focused', 'Plan ahead'],
      trends: {'score': 'improving'},
    );
  }
}

// Data classes for AI features

class ProductivityInsights {
  final double overallScore;
  final double completionRate;
  final double averageTasksPerDay;
  final List<int> peakProductivityHours;
  final List<String> recommendations;
  final Map<String, String> trends;

  ProductivityInsights({
    required this.overallScore,
    required this.completionRate,
    required this.averageTasksPerDay,
    required this.peakProductivityHours,
    required this.recommendations,
    required this.trends,
  });
}

class StreakPrediction {
  final double continuationProbability;
  final RiskLevel riskLevel;
  final List<String> recommendations;

  StreakPrediction({
    required this.continuationProbability,
    required this.riskLevel,
    required this.recommendations,
  });
}

enum RiskLevel { low, medium, high }

class TaskSuggestion {
  final String id;
  final String title;
  final String description;
  final TaskPriority suggestedPriority;
  final double relevanceScore;
  final SuggestionType type;

  TaskSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.suggestedPriority,
    required this.relevanceScore,
    required this.type,
  });
}

enum SuggestionType { recurring, deadline, productivity, contextual }

class ProductivityTip {
  final String id;
  final String title;
  final String description;
  final TipPriority priority;
  final TipCategory category;

  ProductivityTip({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
  });
}

enum TipPriority { low, medium, high }
enum TipCategory { habits, scheduling, organization, planning, focus }

class TaskPatterns {
  final bool hasRecurringTasks;
  final bool hasMissedDeadlines;
  final bool hasLowProductivityPeriods;

  TaskPatterns({
    required this.hasRecurringTasks,
    required this.hasMissedDeadlines,
    required this.hasLowProductivityPeriods,
  });
}