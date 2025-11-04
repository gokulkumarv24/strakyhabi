import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streaky_app/ai/ai_service.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/models/streak_model.dart';

/// Provider for AI-powered productivity insights and recommendations
final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier();
});

/// AI state class
class AiState {
  final bool isInitialized;
  final bool isAvailable;
  final bool isLoading;
  final String? error;
  final ProductivityInsights? insights;
  final List<TaskSuggestion> suggestions;
  final List<ProductivityTip> tips;
  final Map<String, StreakPrediction> streakPredictions;

  const AiState({
    this.isInitialized = false,
    this.isAvailable = false,
    this.isLoading = false,
    this.error,
    this.insights,
    this.suggestions = const [],
    this.tips = const [],
    this.streakPredictions = const {},
  });

  AiState copyWith({
    bool? isInitialized,
    bool? isAvailable,
    bool? isLoading,
    String? error,
    ProductivityInsights? insights,
    List<TaskSuggestion>? suggestions,
    List<ProductivityTip>? tips,
    Map<String, StreakPrediction>? streakPredictions,
  }) {
    return AiState(
      isInitialized: isInitialized ?? this.isInitialized,
      isAvailable: isAvailable ?? this.isAvailable,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      insights: insights ?? this.insights,
      suggestions: suggestions ?? this.suggestions,
      tips: tips ?? this.tips,
      streakPredictions: streakPredictions ?? this.streakPredictions,
    );
  }
}

/// AI state notifier
class AiNotifier extends StateNotifier<AiState> {
  AiNotifier() : super(const AiState()) {
    _initializeAi();
  }

  /// Initialize AI service
  Future<void> _initializeAi() async {
    state = state.copyWith(isLoading: true);

    try {
      await AiService.initialize();
      
      state = state.copyWith(
        isInitialized: true,
        isAvailable: AiService.isAvailable,
        isLoading: false,
      );

      // Load initial data if AI is available
      if (AiService.isAvailable) {
        await _loadInitialData();
      }
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        isAvailable: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load initial AI data
  Future<void> _loadInitialData() async {
    try {
      // Load productivity insights
      final insights = await AiService.analyzeProductivity();
      
      // Load task suggestions
      final suggestions = await AiService.generateTaskSuggestions();
      
      // Load productivity tips
      final tips = await AiService.getProductivityTips();

      state = state.copyWith(
        insights: insights,
        suggestions: suggestions,
        tips: tips,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Predict task priority using AI
  Future<TaskPriority> predictTaskPriority({
    required String title,
    String? description,
    DateTime? dueDate,
    String? category,
    int estimatedMinutes = 30,
    List<String>? tags,
  }) async {
    try {
      return await AiService.predictTaskPriority(
        title: title,
        description: description,
        dueDate: dueDate,
        category: category,
        estimatedMinutes: estimatedMinutes,
        tags: tags,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return TaskPriority.medium; // Fallback
    }
  }

  /// Get streak prediction for a specific streak
  Future<StreakPrediction?> getStreakPrediction(Streak streak) async {
    try {
      final prediction = await AiService.predictStreakContinuation(streak);
      
      // Update state with new prediction
      final updatedPredictions = Map<String, StreakPrediction>.from(state.streakPredictions);
      updatedPredictions[streak.id] = prediction;
      
      state = state.copyWith(streakPredictions: updatedPredictions);
      
      return prediction;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Refresh productivity insights
  Future<void> refreshInsights() async {
    if (!state.isAvailable) return;

    state = state.copyWith(isLoading: true);

    try {
      final insights = await AiService.analyzeProductivity();
      state = state.copyWith(
        insights: insights,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh task suggestions
  Future<void> refreshSuggestions() async {
    if (!state.isAvailable) return;

    try {
      final suggestions = await AiService.generateTaskSuggestions();
      state = state.copyWith(suggestions: suggestions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh productivity tips
  Future<void> refreshTips() async {
    if (!state.isAvailable) return;

    try {
      final tips = await AiService.getProductivityTips();
      state = state.copyWith(tips: tips);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get high-priority tips
  List<ProductivityTip> getHighPriorityTips() {
    return state.tips
        .where((tip) => tip.priority == TipPriority.high)
        .toList();
  }

  /// Get tips by category
  List<ProductivityTip> getTipsByCategory(TipCategory category) {
    return state.tips
        .where((tip) => tip.category == category)
        .toList();
  }

  /// Get suggestions by type
  List<TaskSuggestion> getSuggestionsByType(SuggestionType type) {
    return state.suggestions
        .where((suggestion) => suggestion.type == type)
        .toList();
  }

  /// Mark tip as seen/dismissed
  void dismissTip(String tipId) {
    final updatedTips = state.tips
        .where((tip) => tip.id != tipId)
        .toList();
    
    state = state.copyWith(tips: updatedTips);
  }

  /// Mark suggestion as used
  void useSuggestion(String suggestionId) {
    final updatedSuggestions = state.suggestions
        .where((suggestion) => suggestion.id != suggestionId)
        .toList();
    
    state = state.copyWith(suggestions: updatedSuggestions);
  }

  /// Get AI availability status
  bool get isAiAvailable => state.isAvailable;

  /// Get productivity score
  double? get productivityScore => state.insights?.overallScore;

  /// Get completion rate
  double? get completionRate => state.insights?.completionRate;

  /// Get peak productivity hours
  List<int>? get peakHours => state.insights?.peakProductivityHours;

  /// Check if there are new insights available
  bool get hasNewInsights => state.insights != null;

  /// Check if there are actionable suggestions
  bool get hasActionableSuggestions => state.suggestions.isNotEmpty;

  /// Check if there are important tips
  bool get hasImportantTips => state.tips.any(
    (tip) => tip.priority == TipPriority.high,
  );

  /// Get streak risk warnings
  List<String> getStreakRiskWarnings() {
    return state.streakPredictions.entries
        .where((entry) => entry.value.riskLevel == RiskLevel.high)
        .map((entry) => 'Streak at risk: ${entry.key}')
        .toList();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Dispose AI resources
  void dispose() {
    AiService.dispose();
  }

  /// Force refresh all AI data
  Future<void> refreshAll() async {
    if (!state.isAvailable) return;

    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([
        refreshInsights(),
        refreshSuggestions(),
        refreshTips(),
      ]);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Get personalized recommendations based on current state
  List<String> getPersonalizedRecommendations() {
    final recommendations = <String>[];

    // From productivity insights
    if (state.insights != null) {
      recommendations.addAll(state.insights!.recommendations);
    }

    // From high-priority tips
    final highPriorityTips = getHighPriorityTips();
    for (final tip in highPriorityTips.take(2)) {
      recommendations.add(tip.description);
    }

    // From streak predictions
    for (final prediction in state.streakPredictions.values) {
      if (prediction.riskLevel == RiskLevel.high) {
        recommendations.addAll(prediction.recommendations.take(1));
      }
    }

    return recommendations.take(5).toList();
  }

  /// Check if AI features should be prominently displayed
  bool get shouldHighlightAiFeatures {
    return state.isAvailable && (
      hasNewInsights ||
      hasActionableSuggestions ||
      hasImportantTips
    );
  }
}