// Copilot Prompt:
// Create a Riverpod provider for managing reward state with methods for loading offers, user rewards, earnings, and claim handling.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';
import '../services/reward_service.dart';

// Provider instances
final rewardServiceProvider = Provider<RewardService>((ref) {
  throw UnimplementedError('RewardService should be initialized with getInstance()');
});

final rewardProvider = StateNotifierProvider<RewardNotifier, RewardState>((ref) {
  return RewardNotifier();
});

// State class
class RewardState {
  final List<RewardModel> userRewards;
  final List<OfferModel> availableOffers;
  final List<OfferModel> filteredOffers;
  final UserEarningsModel? userEarnings;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const RewardState({
    this.userRewards = const [],
    this.availableOffers = const [],
    this.filteredOffers = const [],
    this.userEarnings,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  RewardState copyWith({
    List<RewardModel>? userRewards,
    List<OfferModel>? availableOffers,
    List<OfferModel>? filteredOffers,
    UserEarningsModel? userEarnings,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return RewardState(
      userRewards: userRewards ?? this.userRewards,
      availableOffers: availableOffers ?? this.availableOffers,
      filteredOffers: filteredOffers ?? this.filteredOffers,
      userEarnings: userEarnings ?? this.userEarnings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardState &&
        other.userRewards == userRewards &&
        other.availableOffers == availableOffers &&
        other.filteredOffers == filteredOffers &&
        other.userEarnings == userEarnings &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return userRewards.hashCode ^
        availableOffers.hashCode ^
        filteredOffers.hashCode ^
        userEarnings.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        lastUpdated.hashCode;
  }
}

// State notifier
class RewardNotifier extends StateNotifier<RewardState> {
  RewardNotifier() : super(const RewardState());

  RewardService? _rewardService;
  String? _currentUserId;

  Future<void> _initializeService() async {
    if (_rewardService == null) {
      _rewardService = await RewardService.getInstance();
    }
  }

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  String get _userId => _currentUserId ?? 'default_user';

  // Load user rewards
  Future<void> loadUserRewards({RewardStatus? status}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _initializeService();

      final rewards = await _rewardService!.getUserRewards(
        _userId,
        status: status,
      );

      state = state.copyWith(
        userRewards: rewards,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load available offers
  Future<void> loadAvailableOffers({
    String? category,
    String? search,
    int page = 1,
  }) async {
    try {
      if (page == 1) {
        state = state.copyWith(isLoading: true, error: null);
      }
      
      await _initializeService();

      final offers = await _rewardService!.getAvailableOffers(
        category: category,
        search: search,
        page: page,
      );

      final updatedOffers = page == 1 
          ? offers 
          : [...state.availableOffers, ...offers];

      state = state.copyWith(
        availableOffers: updatedOffers,
        filteredOffers: updatedOffers,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load user earnings
  Future<void> loadUserEarnings() async {
    try {
      await _initializeService();

      final earnings = await _rewardService!.getUserEarnings(_userId);

      state = state.copyWith(
        userEarnings: earnings,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Generate reward coupon for completed task
  Future<RewardModel> generateRewardCoupon(String taskId) async {
    try {
      await _initializeService();

      final reward = await _rewardService!.generateRewardCoupon(_userId, taskId);

      // Add to user rewards
      final updatedRewards = [reward, ...state.userRewards];
      state = state.copyWith(userRewards: updatedRewards);

      return reward;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Claim reward
  Future<String> claimReward(String couponId) async {
    try {
      await _initializeService();

      final trackingLink = await _rewardService!.claimReward(couponId, _userId);

      // Update reward status locally
      final updatedRewards = state.userRewards.map((reward) {
        if (reward.couponId == couponId) {
          return reward.copyWith(
            status: RewardStatus.claimed,
            claimedAt: DateTime.now(),
          );
        }
        return reward;
      }).toList();

      state = state.copyWith(userRewards: updatedRewards);

      // Refresh earnings
      loadUserEarnings();

      return trackingLink;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Mark reward as revealed
  void markRewardAsRevealed(String couponId) {
    final updatedRewards = state.userRewards.map((reward) {
      if (reward.couponId == couponId) {
        return reward.copyWith(status: RewardStatus.unlocked);
      }
      return reward;
    }).toList();

    state = state.copyWith(userRewards: updatedRewards);
  }

  // Filter offers by category
  void filterOffersByCategory(String? category) {
    if (category == null) {
      state = state.copyWith(filteredOffers: state.availableOffers);
      return;
    }

    final filtered = state.availableOffers
        .where((offer) => offer.category.toLowerCase() == category.toLowerCase())
        .toList();

    state = state.copyWith(filteredOffers: filtered);
  }

  // Search offers
  Future<void> searchOffers(String query) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _initializeService();

      final offers = await _rewardService!.searchOffers(query);

      state = state.copyWith(
        filteredOffers: offers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get trending offers
  Future<void> loadTrendingOffers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _initializeService();

      final offers = await _rewardService!.getTrendingOffers();

      state = state.copyWith(
        filteredOffers: offers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Request payout
  Future<bool> requestPayout({String paymentMethod = 'upi'}) async {
    try {
      if (state.userEarnings == null || !state.userEarnings!.canWithdraw) {
        throw Exception('Insufficient balance for payout');
      }

      await _initializeService();

      final success = await _rewardService!.requestPayout(
        _userId,
        state.userEarnings!.pendingPayout,
        paymentMethod,
      );

      if (success) {
        // Refresh earnings after successful payout request
        loadUserEarnings();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      await _initializeService();
      return await _rewardService!.getCategories();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Sync offline data
  Future<void> syncOfflineData() async {
    try {
      await _initializeService();
      await _rewardService!.syncOfflineData();
      
      // Refresh all data after sync
      await Future.wait([
        loadUserRewards(),
        loadAvailableOffers(),
        loadUserEarnings(),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadUserRewards(),
      loadAvailableOffers(),
      loadUserEarnings(),
    ]);
  }

  // Get reward by ID
  RewardModel? getRewardById(String couponId) {
    try {
      return state.userRewards.firstWhere((reward) => reward.couponId == couponId);
    } catch (e) {
      return null;
    }
  }

  // Get offer by ID
  OfferModel? getOfferById(String offerId) {
    try {
      return state.availableOffers.firstWhere((offer) => offer.offerId == offerId);
    } catch (e) {
      return null;
    }
  }

  // Get user statistics
  Map<String, dynamic> getUserStats() {
    final earnings = state.userEarnings;
    if (earnings == null) return {};

    return {
      'total_rewards': state.userRewards.length,
      'claimed_rewards': state.userRewards.where((r) => r.isClaimed).length,
      'pending_rewards': state.userRewards.where((r) => r.isPending).length,
      'total_earnings': earnings.totalEarnings,
      'conversion_rate': earnings.conversionRate,
      'avg_click_value': earnings.totalClicks > 0 
          ? earnings.totalCpcEarnings / earnings.totalClicks 
          : 0.0,
      'avg_sale_value': earnings.totalSales > 0 
          ? earnings.totalCpsEarnings / earnings.totalSales 
          : 0.0,
    };
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset state
  void reset() {
    state = const RewardState();
  }

  @override
  void dispose() {
    _rewardService?.dispose();
    super.dispose();
  }
}

// Additional providers for specific data
final userRewardsProvider = Provider<List<RewardModel>>((ref) {
  return ref.watch(rewardProvider).userRewards;
});

final availableOffersProvider = Provider<List<OfferModel>>((ref) {
  return ref.watch(rewardProvider).filteredOffers;
});

final userEarningsProvider = Provider<UserEarningsModel?>((ref) {
  return ref.watch(rewardProvider).userEarnings;
});

final rewardLoadingProvider = Provider<bool>((ref) {
  return ref.watch(rewardProvider).isLoading;
});

final rewardErrorProvider = Provider<String?>((ref) {
  return ref.watch(rewardProvider).error;
});

// Filtered providers
final unclaimedRewardsProvider = Provider<List<RewardModel>>((ref) {
  return ref.watch(userRewardsProvider)
      .where((reward) => !reward.isClaimed && !reward.isExpired)
      .toList();
});

final claimedRewardsProvider = Provider<List<RewardModel>>((ref) {
  return ref.watch(userRewardsProvider)
      .where((reward) => reward.isClaimed)
      .toList();
});

final expiredRewardsProvider = Provider<List<RewardModel>>((ref) {
  return ref.watch(userRewardsProvider)
      .where((reward) => reward.isExpired)
      .toList();
});

// Statistics providers
final userStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(rewardProvider.notifier).getUserStats();
});

final totalEarningsProvider = Provider<double>((ref) {
  final earnings = ref.watch(userEarningsProvider);
  return earnings?.totalEarnings ?? 0.0;
});

final pendingPayoutProvider = Provider<double>((ref) {
  final earnings = ref.watch(userEarningsProvider);
  return earnings?.pendingPayout ?? 0.0;
});

final canWithdrawProvider = Provider<bool>((ref) {
  final earnings = ref.watch(userEarningsProvider);
  return earnings?.canWithdraw ?? false;
});

// Auto-refresh provider
final autoRefreshProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(minutes: 5),
    (count) => DateTime.now(),
  );
});

// Listen to auto-refresh and trigger data reload
final autoRefreshListenerProvider = Provider<void>((ref) {
  ref.listen(autoRefreshProvider, (previous, next) {
    if (next.hasValue) {
      ref.read(rewardProvider.notifier).refreshAll();
    }
  });
});

// Category filter provider
final categoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredOffersByCategoryProvider = Provider<List<OfferModel>>((ref) {
  final offers = ref.watch(availableOffersProvider);
  final category = ref.watch(categoryFilterProvider);
  
  if (category == null) return offers;
  
  return offers
      .where((offer) => offer.category.toLowerCase() == category.toLowerCase())
      .toList();
});

// Search provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<OfferModel>>((ref) {
  final offers = ref.watch(availableOffersProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  
  if (query.isEmpty) return offers;
  
  return offers.where((offer) {
    return offer.title.toLowerCase().contains(query) ||
           offer.description.toLowerCase().contains(query) ||
           offer.brand.toLowerCase().contains(query) ||
           offer.category.toLowerCase().contains(query);
  }).toList();
});