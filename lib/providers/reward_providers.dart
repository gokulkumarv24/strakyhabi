import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/offer_model.dart';
import '../models/user_earnings_model.dart';
import '../services/reward_service.dart';

/// Provider for RewardService instance
final rewardServiceProvider = Provider<RewardService>((ref) {
  return RewardService();
});

/// Provider for available offers
final offersProvider = FutureProvider.autoDispose.family<List<OfferModel>, String>((ref, category) async {
  final rewardService = ref.read(rewardServiceProvider);
  return await rewardService.getOffers(category: category);
});

/// Provider for user earnings
final userEarningsProvider = FutureProvider.autoDispose.family<UserEarningsModel?, String>((ref, userId) async {
  final rewardService = ref.read(rewardServiceProvider);
  return await rewardService.getUserEarnings(userId);
});

/// Provider for featured offers (highest paying)
final featuredOffersProvider = FutureProvider.autoDispose<List<OfferModel>>((ref) async {
  final rewardService = ref.read(rewardServiceProvider);
  final offers = await rewardService.getOffers(limit: 10);
  
  // Sort by potential earnings (CPC + estimated CPS)
  offers.sort((a, b) {
    final scoreA = a.cpcRate + (a.cpsRate * 0.02 * 100); // 2% conversion, ₹100 avg order
    final scoreB = b.cpcRate + (b.cpsRate * 0.02 * 100);
    return scoreB.compareTo(scoreA);
  });
  
  return offers.take(5).toList();
});

/// Provider for user's click history
final clickHistoryProvider = FutureProvider.autoDispose.family<List<ClickHistory>, String>((ref, userId) async {
  final earnings = await ref.read(userEarningsProvider(userId).future);
  return earnings?.clickHistory ?? [];
});

/// Provider for user's sale history
final salesHistoryProvider = FutureProvider.autoDispose.family<List<SaleHistory>, String>((ref, userId) async {
  final earnings = await ref.read(userEarningsProvider(userId).future);
  return earnings?.salesHistory ?? [];
});

/// Provider for withdrawal history
final withdrawalHistoryProvider = FutureProvider.autoDispose.family<List<WithdrawalHistory>, String>((ref, userId) async {
  final earnings = await ref.read(userEarningsProvider(userId).future);
  return earnings?.withdrawalHistory ?? [];
});

/// Provider for earning statistics
final earningStatsProvider = FutureProvider.autoDispose.family<EarningStats, String>((ref, userId) async {
  final earnings = await ref.read(userEarningsProvider(userId).future);
  
  if (earnings == null) {
    return EarningStats(
      totalEarnings: 0,
      todayEarnings: 0,
      thisMonthEarnings: 0,
      totalClicks: 0,
      totalSales: 0,
      conversionRate: 0,
      canWithdraw: false,
      pendingPayout: 0,
    );
  }
  
  // Calculate this month's earnings
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  
  final thisMonthClicks = earnings.clickHistory.where((click) {
    final clickDate = DateTime.parse(click.timestamp);
    return clickDate.isAfter(startOfMonth) && clickDate.isBefore(endOfMonth);
  }).fold(0.0, (sum, click) => sum + click.amount);
  
  final thisMonthSales = earnings.salesHistory.where((sale) {
    final saleDate = DateTime.parse(sale.timestamp);
    return saleDate.isAfter(startOfMonth) && saleDate.isBefore(endOfMonth);
  }).fold(0.0, (sum, sale) => sum + sale.amount);
  
  final thisMonthEarnings = thisMonthClicks + thisMonthSales;
  
  return EarningStats(
    totalEarnings: earnings.totalEarnings,
    todayEarnings: earnings.getTodayEarnings(),
    thisMonthEarnings: thisMonthEarnings,
    totalClicks: earnings.totalClicks,
    totalSales: earnings.totalSales,
    conversionRate: earnings.conversionRate,
    canWithdraw: earnings.canWithdraw(),
    pendingPayout: earnings.pendingPayout,
  );
});

/// Provider for offers by category
final offersByCategoryProvider = FutureProvider.autoDispose<Map<String, List<OfferModel>>>((ref) async {
  final rewardService = ref.read(rewardServiceProvider);
  final allOffers = await rewardService.getOffers(limit: 100);
  
  final Map<String, List<OfferModel>> categorizedOffers = {};
  
  for (final offer in allOffers) {
    final category = offer.category;
    if (!categorizedOffers.containsKey(category)) {
      categorizedOffers[category] = [];
    }
    categorizedOffers[category]!.add(offer);
  }
  
  // Sort each category by earning potential
  categorizedOffers.forEach((category, offers) {
    offers.sort((a, b) {
      final scoreA = a.cpcRate + (a.cpsRate * 0.02 * 100);
      final scoreB = b.cpcRate + (b.cpsRate * 0.02 * 100);
      return scoreB.compareTo(scoreA);
    });
  });
  
  return categorizedOffers;
});

/// Provider for recent activity
final recentActivityProvider = FutureProvider.autoDispose.family<List<ActivityItem>, String>((ref, userId) async {
  final earnings = await ref.read(userEarningsProvider(userId).future);
  
  if (earnings == null) return [];
  
  final List<ActivityItem> activities = [];
  
  // Add recent clicks
  for (final click in earnings.clickHistory.take(10)) {
    activities.add(ActivityItem(
      id: click.clickId,
      type: ActivityType.click,
      title: 'Click Reward Earned',
      subtitle: '₹${click.amount.toStringAsFixed(2)} from ${click.source}',
      amount: click.amount,
      timestamp: DateTime.parse(click.timestamp),
      source: click.source,
    ));
  }
  
  // Add recent sales
  for (final sale in earnings.salesHistory.take(10)) {
    activities.add(ActivityItem(
      id: sale.saleId,
      type: ActivityType.sale,
      title: 'Sale Commission Earned',
      subtitle: '₹${sale.amount.toStringAsFixed(2)} from ₹${sale.orderValue.toStringAsFixed(0)} order',
      amount: sale.amount,
      timestamp: DateTime.parse(sale.timestamp),
      source: sale.source,
    ));
  }
  
  // Add recent withdrawals
  for (final withdrawal in earnings.withdrawalHistory.take(5)) {
    activities.add(ActivityItem(
      id: withdrawal.id,
      type: ActivityType.withdrawal,
      title: 'Withdrawal ${withdrawal.status.toUpperCase()}',
      subtitle: '₹${withdrawal.amount.toStringAsFixed(2)} via ${withdrawal.method}',
      amount: withdrawal.amount,
      timestamp: DateTime.parse(withdrawal.requestedAt),
      source: withdrawal.method,
    ));
  }
  
  // Sort by timestamp (newest first)
  activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
  return activities.take(20).toList();
});

/// State notifier for managing offer search and filtering
class OfferFilterNotifier extends StateNotifier<OfferFilter> {
  OfferFilterNotifier() : super(OfferFilter());
  
  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }
  
  void updateSource(String? source) {
    state = state.copyWith(source: source);
  }
  
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
  
  void updateSortBy(SortOption sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }
  
  void reset() {
    state = OfferFilter();
  }
}

final offerFilterProvider = StateNotifierProvider<OfferFilterNotifier, OfferFilter>((ref) {
  return OfferFilterNotifier();
});

/// Provider for filtered offers based on current filter state
final filteredOffersProvider = FutureProvider.autoDispose<List<OfferModel>>((ref) async {
  final rewardService = ref.read(rewardServiceProvider);
  final filter = ref.watch(offerFilterProvider);
  
  final offers = await rewardService.getOffers(
    category: filter.category == 'all' ? null : filter.category,
    limit: 100,
  );
  
  List<OfferModel> filteredOffers = offers;
  
  // Apply source filter
  if (filter.source != null && filter.source!.isNotEmpty) {
    filteredOffers = filteredOffers.where((offer) => 
      offer.source.toLowerCase() == filter.source!.toLowerCase()
    ).toList();
  }
  
  // Apply search filter
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    filteredOffers = filteredOffers.where((offer) =>
      offer.title.toLowerCase().contains(query) ||
      offer.description.toLowerCase().contains(query) ||
      offer.brand.toLowerCase().contains(query) ||
      offer.category.toLowerCase().contains(query)
    ).toList();
  }
  
  // Apply sorting
  switch (filter.sortBy) {
    case SortOption.earnings:
      filteredOffers.sort((a, b) {
        final scoreA = a.cpcRate + (a.cpsRate * 0.02 * 100);
        final scoreB = b.cpcRate + (b.cpsRate * 0.02 * 100);
        return scoreB.compareTo(scoreA);
      });
      break;
    case SortOption.cpcRate:
      filteredOffers.sort((a, b) => b.cpcRate.compareTo(a.cpcRate));
      break;
    case SortOption.cpsRate:
      filteredOffers.sort((a, b) => b.cpsRate.compareTo(a.cpsRate));
      break;
    case SortOption.alphabetical:
      filteredOffers.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortOption.newest:
      filteredOffers.sort((a, b) => 
        DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt))
      );
      break;
  }
  
  return filteredOffers;
});

// Data classes for providers

class EarningStats {
  final double totalEarnings;
  final double todayEarnings;
  final double thisMonthEarnings;
  final int totalClicks;
  final int totalSales;
  final double conversionRate;
  final bool canWithdraw;
  final double pendingPayout;
  
  EarningStats({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.thisMonthEarnings,
    required this.totalClicks,
    required this.totalSales,
    required this.conversionRate,
    required this.canWithdraw,
    required this.pendingPayout,
  });
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime timestamp;
  final String source;
  
  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.timestamp,
    required this.source,
  });
}

enum ActivityType { click, sale, withdrawal }

class OfferFilter {
  final String category;
  final String? source;
  final String searchQuery;
  final SortOption sortBy;
  
  OfferFilter({
    this.category = 'all',
    this.source,
    this.searchQuery = '',
    this.sortBy = SortOption.earnings,
  });
  
  OfferFilter copyWith({
    String? category,
    String? source,
    String? searchQuery,
    SortOption? sortBy,
  }) {
    return OfferFilter(
      category: category ?? this.category,
      source: source ?? this.source,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum SortOption {
  earnings,
  cpcRate,
  cpsRate,
  alphabetical,
  newest,
}