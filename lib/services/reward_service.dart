import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';
import 'affiliate_api_service.dart';

class RewardService {
  static const String _baseUrl = 'https://your-worker.your-subdomain.workers.dev';
  static const String _cacheKey = 'rewards_cache';
  static const Duration _cacheTimeout = Duration(hours: 4);
  
  final Dio _dio;
  final Box _cache;

  RewardService._(this._dio, this._cache);

  static RewardService? _instance;

  static Future<RewardService> getInstance() async {
    if (_instance == null) {
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'StreakRewards/1.0',
        },
      ));

      // Add interceptors for logging and error handling
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));

      dio.interceptors.add(InterceptorsWrapper(
        onError: (error, handler) {
          print('API Error: ${error.message}');
          handler.next(error);
        },
      ));

      final cache = await Hive.openBox('reward_cache');
      _instance = RewardService._(dio, cache);
    }
    return _instance!;
  }

  /// Get available affiliate offers
  Future<List<OfferModel>> getAvailableOffers({
    String? category,
    String? search,
    bool personalized = false,
    String? userId,
  }) async {
    try {
      List<dynamic> offersData;

      if (personalized && userId != null) {
        // Get personalized offers from affiliate API
        final response = await AffiliateApiService.fetchPersonalizedOffers(userId);
        offersData = response['offers'] ?? [];
      } else {
        // Get regular ranked offers
        offersData = await AffiliateApiService.fetchRankedOffers();
      }

      // Convert to OfferModel list
      final offers = offersData.map((json) => OfferModel.fromAffiliate(json)).toList();

      // Apply local filtering
      var filteredOffers = offers;
      if (category != null) {
        filteredOffers = offers.where((o) => o.category.toLowerCase() == category.toLowerCase()).toList();
      }
      if (search != null && search.isNotEmpty) {
        filteredOffers = filteredOffers.where((o) => 
          o.title.toLowerCase().contains(search.toLowerCase()) ||
          o.description.toLowerCase().contains(search.toLowerCase())
        ).toList();
      }

      return filteredOffers;
    } catch (e) {
      print('Error fetching offers: $e');
      return _getFallbackOffers();
    }
  }

  /// Generate scratch card reward for completed task
  Future<RewardModel> generateScratchCardReward(String userId, String taskId) async {
    try {
      // Get personalized offers for this user
      final offers = await getAvailableOffers(personalized: true, userId: userId);
      if (offers.isEmpty) throw Exception('No offers available');

      // Select offer weighted by earning potential and user preferences
      final selectedOffer = _selectOfferByWeight(offers);
      
      // Create reward model with affiliate offer data
      final reward = RewardModel(
        couponId: 'scratch_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        offerId: selectedOffer.offerId,
        title: selectedOffer.title,
        description: selectedOffer.description,
        type: _selectRewardType(selectedOffer),
        rewardAmount: _calculateRewardAmount(selectedOffer),
        trackingLink: selectedOffer.trackingUrl,
        imageUrl: selectedOffer.imageUrl,
        status: RewardStatus.unlocked,
        createdAt: DateTime.now(),
        affiliateData: {
          'network': selectedOffer.source,
          'category': selectedOffer.category,
          'merchant': selectedOffer.brand,
          'cpc': selectedOffer.cpcRate,
          'cps': selectedOffer.cpsRate,
        },
      );

      // Cache the reward locally
      await _cacheReward(reward);
      
      return reward;
    } catch (e) {
      print('Error generating scratch card reward: $e');
      return _generateFallbackReward(userId, taskId);
    }
  }

  /// Claim reward and track click
  Future<void> claimReward(RewardModel reward) async {
    try {
      // Track click through affiliate API
      await AffiliateApiService.trackClick(
        offerUrl: reward.trackingLink,
        userId: reward.userId,
        offerId: reward.offerId,
      );

      // Update reward status
      final updatedReward = reward.copyWith(
        status: RewardStatus.claimed,
        claimedAt: DateTime.now(),
      );

      await _updateCachedReward(updatedReward);
    } catch (e) {
      print('Error claiming reward: $e');
      throw Exception('Unable to claim reward. Please check your connection.');
    }
  }

  /// Get user's reward history
  Future<List<RewardModel>> getUserRewards(String userId, {
    RewardStatus? status,
    int limit = 50,
  }) async {
    try {
      final cached = _getCachedUserRewards(userId);
      
      if (status != null) {
        return cached.where((r) => r.status == status).take(limit).toList();
      }
      
      return cached.take(limit).toList();
    } catch (e) {
      print('Error fetching user rewards: $e');
      return [];
    }
  }

  /// Get user earnings summary
  Future<UserEarningsModel> getUserEarnings(String userId) async {
    try {
      // Try to get from affiliate API first
      final profile = await AffiliateApiService.getUserProfile(userId);
      
      return UserEarningsModel(
        userId: userId,
        totalCpcEarnings: (profile['totalEarnings'] ?? 0.0).toDouble(),
        totalCpsEarnings: 0.0, // Will be updated when sales are tracked
        totalClicks: profile['totalClicks'] ?? 0,
        totalSales: profile['totalSales'] ?? 0,
        pendingPayout: (profile['totalEarnings'] ?? 0.0).toDouble(),
        clickHistory: [],
        salesHistory: [],
      );
    } catch (e) {
      print('Error fetching earnings: $e');
      return _getDefaultEarnings(userId);
    }
  }

  /// Get daily analytics
  Future<Map<String, dynamic>> getDailyAnalytics([String? date]) async {
    try {
      return await AffiliateApiService.getDailyMetrics(date);
    } catch (e) {
      print('Error fetching daily analytics: $e');
      return {
        'totalSales': 0,
        'totalRevenue': 0.0,
        'networks': {},
        'avgOrderValue': 0.0,
      };
    }
  }

  /// Trigger offer ranking update
  Future<void> refreshOfferRanking() async {
    try {
      await AffiliateApiService.triggerRanking();
    } catch (e) {
      print('Error refreshing offer ranking: $e');
    }
  }

  /// Search offers
  Future<List<OfferModel>> searchOffers(String query, {String? userId}) async {
    final offers = await getAvailableOffers(search: query, userId: userId);
    return offers;
  }

  /// Get offers by category
  Future<List<OfferModel>> getOffersByCategory(String category, {String? userId}) async {
    return getAvailableOffers(category: category, userId: userId);
  }

  /// Get trending/top offers
  Future<List<OfferModel>> getTrendingOffers({String? userId, int limit = 10}) async {
    final offers = await getAvailableOffers(personalized: true, userId: userId);
    return offers.take(limit).toList();
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    try {
      final cached = _getCachedData('categories');
      if (cached != null) return List<String>.from(cached);

      final offers = await getAvailableOffers();
      final categories = offers.map((o) => o.category).toSet().toList();
      
      _setCachedData('categories', categories);
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return _getDefaultCategories();
    }
  }

  /// Sync offline data
  Future<void> syncOfflineData() async {
    try {
      // Sync any pending clicks or rewards
      final pendingRewards = _cache.get('pending_rewards', defaultValue: <Map<String, dynamic>>[]);
      
      for (final rewardData in pendingRewards) {
        try {
          final reward = RewardModel.fromJson(rewardData);
          if (reward.status == RewardStatus.claimed) {
            await claimReward(reward);
          }
        } catch (e) {
          print('Error syncing reward: $e');
        }
      }
      
      await _cache.delete('pending_rewards');
    } catch (e) {
      print('Error syncing offline data: $e');
    }
  }

  // Helper methods
  OfferModel _selectOfferByWeight(List<OfferModel> offers) {
    if (offers.isEmpty) throw Exception('No offers to select from');
    
    // Weight by total earning potential (CPC + CPS * average order value)
    final weights = offers.map((o) => o.cpcRate + (o.cpsRate * 100)).toList();
    final totalWeight = weights.reduce((a, b) => a + b);
    
    final random = Random();
    double randomValue = random.nextDouble() * totalWeight;
    
    for (int i = 0; i < offers.length; i++) {
      randomValue -= weights[i];
      if (randomValue <= 0) return offers[i];
    }
    
    return offers.last;
  }

  RewardType _selectRewardType(OfferModel offer) {
    // Prefer CPS for higher value offers, CPC for engagement offers
    if (offer.cpsRate > 5.0) return RewardType.cps;
    return RewardType.cpc;
  }

  double _calculateRewardAmount(OfferModel offer) {
    final random = Random();
    return offer.cpcRate + (random.nextDouble() * 2); // Add small random bonus
  }

  // Cache management
  Future<void> _cacheReward(RewardModel reward) async {
    final userRewards = _getCachedUserRewards(reward.userId);
    userRewards.add(reward);
    
    await _cache.put('user_rewards_${reward.userId}', 
      userRewards.map((r) => r.toJson()).toList());
  }

  Future<void> _updateCachedReward(RewardModel reward) async {
    final userRewards = _getCachedUserRewards(reward.userId);
    final index = userRewards.indexWhere((r) => r.couponId == reward.couponId);
    
    if (index != -1) {
      userRewards[index] = reward;
      await _cache.put('user_rewards_${reward.userId}', 
        userRewards.map((r) => r.toJson()).toList());
    }
  }

  List<RewardModel> _getCachedUserRewards(String userId) {
    final cached = _cache.get('user_rewards_$userId', defaultValue: <Map<String, dynamic>>[]);
    return (cached as List).map((json) => RewardModel.fromJson(json)).toList();
  }

  dynamic _getCachedData(String key) {
    final cached = _cache.get(key);
    if (cached == null) return null;
    
    final cacheData = Map<String, dynamic>.from(cached);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        
    if (DateTime.now().difference(timestamp) > _cacheTimeout) {
      _cache.delete(key);
      return null;
    }
        
    return cacheData['data'];
  }

  void _setCachedData(String key, dynamic data) {
    _cache.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Fallback data for offline mode
  List<OfferModel> _getFallbackOffers() {
    return [
      OfferModel(
        offerId: 'fallback_amazon',
        title: 'Amazon Shopping Rewards',
        description: 'Get cashback on electronics, books, and more from Amazon',
        brand: 'Amazon',
        category: 'Shopping',
        imageUrl: 'https://via.placeholder.com/200x120/FF9900/white?text=Amazon',
        trackingUrl: 'https://amazon.in',
        cpcRate: 5.0,
        cpsRate: 3.0,
        source: 'fallback',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      OfferModel(
        offerId: 'fallback_udemy',
        title: 'Udemy Course Discounts',
        description: 'Learn new skills with up to 90% off on popular courses',
        brand: 'Udemy',
        category: 'Education',
        imageUrl: 'https://via.placeholder.com/200x120/A435F0/white?text=Udemy',
        trackingUrl: 'https://udemy.com',
        cpcRate: 3.0,
        cpsRate: 15.0,
        source: 'fallback',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  RewardModel _generateFallbackReward(String userId, String taskId) {
    final random = Random();
    final fallbackOffers = _getFallbackOffers();
    final selectedOffer = fallbackOffers[random.nextInt(fallbackOffers.length)];
    
    return RewardModel(
      couponId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      offerId: selectedOffer.offerId,
      title: selectedOffer.title,
      description: selectedOffer.description,
      type: RewardType.cpc,
      rewardAmount: selectedOffer.cpcRate,
      trackingLink: selectedOffer.trackingUrl,
      imageUrl: selectedOffer.imageUrl,
      status: RewardStatus.unlocked,
      createdAt: DateTime.now(),
    );
  }

  UserEarningsModel _getDefaultEarnings(String userId) {
    return UserEarningsModel(
      userId: userId,
      totalCpcEarnings: 0.0,
      totalCpsEarnings: 0.0,
      totalClicks: 0,
      totalSales: 0,
      pendingPayout: 0.0,
      clickHistory: [],
      salesHistory: [],
    );
  }

  List<String> _getDefaultCategories() {
    return [
      'Shopping',
      'Electronics',
      'Education',
      'Fashion',
      'Food & Dining',
      'Travel',
      'Entertainment',
      'Health & Beauty',
      'Finance',
      'Gaming',
    ];
  }

  void dispose() {
    _cache.close();
  }
}

// Provider for reward service
final rewardServiceProvider = Provider<RewardService>((ref) {
  throw UnimplementedError('RewardService must be initialized with getInstance()');
});

// Provider for reward service state
final rewardServiceStateProvider = StateNotifierProvider<RewardServiceState, RewardServiceStateData>((ref) {
  return RewardServiceState(ref);
});

class RewardServiceStateData {
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const RewardServiceStateData({
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  RewardServiceStateData copyWith({
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return RewardServiceStateData(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class RewardServiceState extends StateNotifier<RewardServiceStateData> {
  final Ref _ref;

  RewardServiceState(this._ref) : super(const RewardServiceStateData());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void setLastUpdated() {
    state = state.copyWith(lastUpdated: DateTime.now());
  }

  void reset() {
    state = const RewardServiceStateData();
  }
}

// Custom exceptions
class RewardServiceException implements Exception {
  final String message;
  final String? code;
  
  const RewardServiceException(this.message, [this.code]);
  
  @override
  String toString() => 'RewardServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends RewardServiceException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class AuthenticationException extends RewardServiceException {
  const AuthenticationException(String message) : super(message, 'AUTH_ERROR');
}

class RateLimitException extends RewardServiceException {
  const RateLimitException(String message) : super(message, 'RATE_LIMIT');
}



  // Get available offers from affiliate networks  // Get available offers from affiliate networks

  Future<List<OfferModel>> getAvailableOffers({  Future<List<OfferModel>> getAvailableOffers({

    String? category,    String? category,

    String? search,    String? search,

    int page = 1,    int page = 1,

    int limit = 20,    int limit = 20,

  }) async {  }) async {

    try {    try {

      final cacheKey = 'offers_${category ?? 'all'}_${search ?? ''}_$page';      final cacheKey = 'offers_${category ?? 'all'}_${search ?? ''}_$page';

      final cached = _getCachedData(cacheKey);      final cached = _getCachedData(cacheKey);

      if (cached != null) {      if (cached != null) {

        return (cached as List).map((json) => OfferModel.fromJson(json)).toList();        return (cached as List).map((json) => OfferModel.fromJson(json)).toList();

      }      }



      final response = await _dio.get('/api/offers', queryParameters: {      final response = await _dio.get('/api/offers', queryParameters: {

        if (category != null) 'category': category,        if (category != null) 'category': category,

        if (search != null) 'search': search,        if (search != null) 'search': search,

        'page': page,        'page': page,

        'limit': limit,        'limit': limit,

      });      });



      if (response.statusCode == 200) {      if (response.statusCode == 200) {

        final offers = (response.data['offers'] as List)        final offers = (response.data['offers'] as List)

            .map((json) => OfferModel.fromJson(json))            .map((json) => OfferModel.fromJson(json))

            .toList();            .toList();

                

        _setCachedData(cacheKey, offers.map((o) => o.toJson()).toList());        _setCachedData(cacheKey, offers.map((o) => o.toJson()).toList());

        return offers;        return offers;

      }      }



      throw Exception('Failed to fetch offers: ${response.statusMessage}');      throw Exception('Failed to fetch offers: ${response.statusMessage}');

    } catch (e) {    } catch (e) {

      print('Error fetching offers: $e');      print('Error fetching offers: $e');

      return _getFallbackOffers();      return _getFallbackOffers();

    }    }

  }  }



  // Generate reward coupon for completed task  // Generate reward coupon for completed task

  Future<RewardModel> generateRewardCoupon(String userId, String taskId) async {  Future<RewardModel> generateRewardCoupon(String userId, String taskId) async {

    try {    try {

      final offers = await getAvailableOffers();      final offers = await getAvailableOffers();

      if (offers.isEmpty) throw Exception('No offers available');      if (offers.isEmpty) throw Exception('No offers available');



      // Select random offer weighted by earning potential      // Select random offer weighted by earning potential

      final selectedOffer = _selectOfferByWeight(offers);      final selectedOffer = _selectOfferByWeight(offers);

      final rewardType = _selectRewardType();      final rewardType = _selectRewardType();

            

      final couponData = {      final couponData = {

        'user_id': userId,        'user_id': userId,

        'task_id': taskId,        'task_id': taskId,

        'offer_id': selectedOffer.offerId,        'offer_id': selectedOffer.offerId,

        'reward_type': rewardType.name,        'reward_type': rewardType.name,

      };      };



      final response = await _dio.post('/api/coupons/generate', data: couponData);      final response = await _dio.post('/api/coupons/generate', data: couponData);



      if (response.statusCode == 201) {      if (response.statusCode == 201) {

        return RewardModel.fromJson(response.data['coupon']);        return RewardModel.fromJson(response.data['coupon']);

      }      }



      throw Exception('Failed to generate coupon: ${response.statusMessage}');      throw Exception('Failed to generate coupon: ${response.statusMessage}');

    } catch (e) {    } catch (e) {

      print('Error generating coupon: $e');      print('Error generating coupon: $e');

      return _generateFallbackCoupon(userId, taskId);      return _generateFallbackCoupon(userId, taskId);

    }    }

  }  }



  // Get user's reward coupons  /// Load offers (for provider)

  Future<List<RewardModel>> getUserRewards(String userId, {  Future<void> loadOffers() async {

    RewardStatus? status,    await getOffers();

    int page = 1,  }

    int limit = 50,

  }) async {  /// Get user earnings from API

    try {  Future<UserEarnings> getUserEarnings() async {

      final response = await _dio.get('/api/users/$userId/rewards', queryParameters: {    try {

        if (status != null) 'status': status.name,      final userId = await _getUserId();

        'page': page,      

        'limit': limit,      final response = await _dio.get(

      });        '$baseUrl/api/earnings/$userId',

      );

      if (response.statusCode == 200) {

        return (response.data['rewards'] as List)      if (response.statusCode == 200) {

            .map((json) => RewardModel.fromJson(json))        return UserEarnings.fromJson(response.data);

            .toList();      } else {

      }        throw Exception('Failed to load earnings: ${response.statusCode}');

      }

      throw Exception('Failed to fetch user rewards: ${response.statusMessage}');    } on DioException catch (e) {

    } catch (e) {      throw Exception('Network error: ${e.message}');

      print('Error fetching user rewards: $e');    } catch (e) {

      return [];      throw Exception('Error loading earnings: $e');

    }    }

  }  }



  // Claim reward coupon and get tracking link  /// Load user earnings (for provider)

  Future<String> claimReward(String couponId, String userId) async {  Future<void> loadUserEarnings() async {

    try {    await getUserEarnings();

      final response = await _dio.post('/api/coupons/$couponId/claim', data: {  }

        'user_id': userId,

        'timestamp': DateTime.now().toIso8601String(),  /// Process a click (CPC) and open affiliate link

      });  Future<void> processClick(Offer offer) async {

    try {

      if (response.statusCode == 200) {      final userId = await _getUserId();

        final trackingLink = response.data['tracking_link'];      

              // Log click to backend first

        // Track click event      final response = await _dio.post(

        await _trackClick(couponId, userId, trackingLink);        '$baseUrl/api/click/log',

                data: {

        return trackingLink;          'userId': userId,

      }          'offerId': offer.id,

          'source': offer.source,

      throw Exception('Failed to claim reward: ${response.statusMessage}');          'cpcRate': offer.cpcRate,

    } catch (e) {          'timestamp': DateTime.now().toIso8601String(),

      print('Error claiming reward: $e');        },

      throw Exception('Unable to claim reward. Please try again.');      );

    }

  }      if (response.statusCode != 200) {

        throw Exception('Failed to log click: ${response.statusCode}');

  // Track click event for CPC earnings      }

  Future<void> _trackClick(String couponId, String userId, String trackingLink) async {

    try {      // Store locally for offline tracking

      await _dio.post('/api/clicks/track', data: {      final storage = _ref.read(storageServiceProvider);

        'coupon_id': couponId,      await storage.logClick({

        'user_id': userId,        'userId': userId,

        'tracking_link': trackingLink,        'offerId': offer.id,

        'timestamp': DateTime.now().toIso8601String(),        'amount': offer.cpcRate,

        'user_agent': 'StreakRewards/1.0',        'timestamp': DateTime.now().toIso8601String(),

      });        'source': offer.source,

    } catch (e) {      });

      print('Error tracking click: $e');

      // Non-critical error, don't throw    } catch (e) {

    }      throw Exception('Error processing click: $e');

  }    }

  }

  // Get user earnings summary

  Future<UserEarningsModel> getUserEarnings(String userId) async {  /// Open affiliate link in browser

    try {  Future<void> openAffiliateLink(Offer offer) async {

      final response = await _dio.get('/api/users/$userId/earnings');    try {

      final userId = await _getUserId();

      if (response.statusCode == 200) {      

        return UserEarningsModel.fromJson(response.data);      // Generate affiliate link via worker

      }      final affiliateUrl = '$baseUrl/click/${offer.id}/$userId';

      

      throw Exception('Failed to fetch earnings: ${response.statusMessage}');      final uri = Uri.parse(affiliateUrl);

    } catch (e) {      

      print('Error fetching earnings: $e');      if (await canLaunchUrl(uri)) {

      return _getDefaultEarnings(userId);        await launchUrl(

    }          uri,

  }          mode: LaunchMode.externalApplication,

        );

  // Initiate payout request      } else {

  Future<bool> requestPayout(String userId, double amount, String paymentMethod) async {        throw Exception('Could not launch affiliate link');

    try {      }

      final response = await _dio.post('/api/payouts/request', data: {    } catch (e) {

        'user_id': userId,      throw Exception('Error opening affiliate link: $e');

        'amount': amount,    }

        'payment_method': paymentMethod,  }

        'timestamp': DateTime.now().toIso8601String(),

      });  /// Get offers by category

  Future<List<Offer>> getOffersByCategory(String category) async {

      return response.statusCode == 202;    return await getOffers(category: category);

    } catch (e) {  }

      print('Error requesting payout: $e');

      return false;  /// Search offers by keyword

    }  Future<List<Offer>> searchOffers(String query) async {

  }    try {

      final allOffers = await getOffers();

  // Get available categories for filtering      return allOffers.where((offer) {

  Future<List<String>> getCategories() async {        return offer.title.toLowerCase().contains(query.toLowerCase()) ||

    try {               offer.description.toLowerCase().contains(query.toLowerCase()) ||

      final cached = _getCachedData('categories');               offer.category.toLowerCase().contains(query.toLowerCase());

      if (cached != null) return List<String>.from(cached);      }).toList();

    } catch (e) {

      final response = await _dio.get('/api/categories');      throw Exception('Error searching offers: $e');

    }

      if (response.statusCode == 200) {  }

        final categories = List<String>.from(response.data['categories']);

        _setCachedData('categories', categories);  /// Get top performing offers

        return categories;  Future<List<Offer>> getTopOffers({int limit = 10}) async {

      }    try {

      final allOffers = await getOffers();

      return _getDefaultCategories();      

    } catch (e) {      // Sort by CPC rate + CPS rate for best earning potential

      print('Error fetching categories: $e');      allOffers.sort((a, b) {

      return _getDefaultCategories();        final scoreA = a.cpcRate + (a.cpsRate * 10); // Weight CPS higher

    }        final scoreB = b.cpcRate + (b.cpsRate * 10);

  }        return scoreB.compareTo(scoreA);

      });

  // Search offers by query      

  Future<List<OfferModel>> searchOffers(String query) async {      return allOffers.take(limit).toList();

    return getAvailableOffers(search: query);    } catch (e) {

  }      throw Exception('Error loading top offers: $e');

    }

  // Get trending offers  }

  Future<List<OfferModel>> getTrendingOffers() async {

    try {  /// Check if click tracking is working

      final response = await _dio.get('/api/offers/trending');  Future<bool> testClickTracking() async {

    try {

      if (response.statusCode == 200) {      final response = await _dio.get('$baseUrl/health');

        return (response.data['offers'] as List)      return response.statusCode == 200;

            .map((json) => OfferModel.fromJson(json))    } catch (e) {

            .toList();      return false;

      }    }

  }

      // Fallback to regular offers

      return getAvailableOffers(limit: 10);  /// Sync offline clicks with server

    } catch (e) {  Future<void> syncOfflineClicks() async {

      print('Error fetching trending offers: $e');    try {

      return getAvailableOffers(limit: 10);      final storage = _ref.read(storageServiceProvider);

    }      final offlineClicks = await storage.getOfflineClicks();

  }      

      for (final click in offlineClicks) {

  // Sync offline data when connection is restored        try {

  Future<void> syncOfflineData() async {          await _dio.post(

    try {            '$baseUrl/api/click/sync',

      final pendingClicks = _cache.get('pending_clicks', defaultValue: <Map<String, dynamic>>[]);            data: click,

                );

      for (final clickData in pendingClicks) {          

        await _dio.post('/api/clicks/track', data: clickData);          // Remove synced click from local storage

      }          await storage.removeOfflineClick(click['id']);

              } catch (e) {

      await _cache.delete('pending_clicks');          // Keep click for next sync attempt

    } catch (e) {          print('Failed to sync click ${click['id']}: $e');

      print('Error syncing offline data: $e');        }

    }      }

  }    } catch (e) {

      print('Error syncing offline clicks: $e');

  // Validate tracking link security    }

  String _generateSecureTrackingLink(String baseUrl, String userId, String offerId) {  }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final data = '$userId:$offerId:$timestamp';  /// Process sale confirmation (CPS)

    final signature = _generateSignature(data);  Future<void> processSaleConfirmation({

        required String offerId,

    return '$baseUrl?uid=$userId&oid=$offerId&ts=$timestamp&sig=$signature';    required double saleAmount,

  }    required double commission,

    required String transactionId,

  String _generateSignature(String data) {  }) async {

    final key = utf8.encode('your-secret-key'); // Store in secure config    try {

    final bytes = utf8.encode(data);      final userId = await _getUserId();

    final hmac = Hmac(sha256, key);      

    final digest = hmac.convert(bytes);      final response = await _dio.post(

    return digest.toString();        '$baseUrl/api/sale/confirm',

  }        data: {

          'userId': userId,

  // Helper methods          'offerId': offerId,

  OfferModel _selectOfferByWeight(List<OfferModel> offers) {          'saleAmount': saleAmount,

    final random = Random();          'commission': commission,

    final weights = offers.map((o) => o.estimatedEarning).toList();          'transactionId': transactionId,

    final totalWeight = weights.reduce((a, b) => a + b);          'timestamp': DateTime.now().toIso8601String(),

            },

    double randomValue = random.nextDouble() * totalWeight;      );

    

    for (int i = 0; i < offers.length; i++) {      if (response.statusCode != 200) {

      randomValue -= weights[i];        throw Exception('Failed to process sale: ${response.statusCode}');

      if (randomValue <= 0) return offers[i];      }

    }    } catch (e) {

          throw Exception('Error processing sale: $e');

    return offers.last;    }

  }  }



  RewardType _selectRewardType() {  /// Get earning statistics

    final random = Random();  Future<Map<String, dynamic>> getEarningStats() async {

    return random.nextBool() ? RewardType.cpc : RewardType.cps;    try {

  }      final userId = await _getUserId();

      

  dynamic _getCachedData(String key) {      final response = await _dio.get(

    final cached = _cache.get(key);        '$baseUrl/api/stats/$userId',

    if (cached == null) return null;      );

    

    final cacheData = Map<String, dynamic>.from(cached);      if (response.statusCode == 200) {

    final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);        return response.data;

          } else {

    if (DateTime.now().difference(timestamp) > _cacheTimeout) {        throw Exception('Failed to load stats: ${response.statusCode}');

      _cache.delete(key);      }

      return null;    } catch (e) {

    }      throw Exception('Error loading stats: $e');

        }

    return cacheData['data'];  }

  }

  /// Check cache freshness

  void _setCachedData(String key, dynamic data) {  bool _isCacheFresh() {

    _cache.put(key, {    final storage = _ref.read(storageServiceProvider);

      'data': data,    final lastCacheTime = storage.getLastCacheTime();

      'timestamp': DateTime.now().millisecondsSinceEpoch,    if (lastCacheTime == null) return false;

    });    

  }    final now = DateTime.now();

    final difference = now.difference(lastCacheTime);

  // Fallback data for offline mode    

  List<OfferModel> _getFallbackOffers() {    return difference.inHours < 1; // Cache is fresh for 1 hour

    return [  }

      OfferModel(

        offerId: 'fallback_1',  /// Dispose resources

        title: 'Shop Online & Earn',  void dispose() {

        description: 'Get rewarded for shopping from popular brands',    _dio.close();

        brand: 'Multi-Brand',  }

        category: 'Shopping',}

        imageUrl: 'https://via.placeholder.com/200x120/4CAF50/white?text=Shop',

        trackingUrl: 'https://example.com/shop',// Provider for reward service state

        cpcRate: 2.0,final rewardServiceStateProvider = StateNotifierProvider<RewardServiceState, RewardServiceStateData>((ref) {

        cpsRate: 3.0,  return RewardServiceState(ref);

        source: 'internal',});

        currency: 'INR',

        createdAt: DateTime.now(),class RewardServiceStateData {

        updatedAt: DateTime.now(),  final bool isLoading;

      ),  final String? error;

    ];  final DateTime? lastUpdated;

  }

  const RewardServiceStateData({

  RewardModel _generateFallbackCoupon(String userId, String taskId) {    this.isLoading = false,

    final random = Random();    this.error,

    final rewardType = random.nextBool() ? RewardType.cpc : RewardType.cps;    this.lastUpdated,

    final amount = rewardType == RewardType.cpc   });

        ? (random.nextDouble() * 10 + 1) // ₹1-10

        : (random.nextDouble() * 5 + 1); // 1-5%  RewardServiceStateData copyWith({

    bool? isLoading,

    return RewardModel(    String? error,

      couponId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',    DateTime? lastUpdated,

      userId: userId,  }) {

      offerId: 'fallback_1',    return RewardServiceStateData(

      title: 'Mystery Reward',      isLoading: isLoading ?? this.isLoading,

      description: 'Complete your streak for surprise rewards!',      error: error,

      type: rewardType,      lastUpdated: lastUpdated ?? this.lastUpdated,

      rewardAmount: amount,    );

      trackingLink: 'https://example.com/track',  }

      status: RewardStatus.unlocked,}

      createdAt: DateTime.now(),

    );class RewardServiceState extends StateNotifier<RewardServiceStateData> {

  }  final Ref _ref;



  UserEarningsModel _getDefaultEarnings(String userId) {  RewardServiceState(this._ref) : super(const RewardServiceStateData());

    return UserEarningsModel(

      userId: userId,  void setLoading(bool loading) {

      totalCpcEarnings: 0.0,    state = state.copyWith(isLoading: loading);

      totalCpsEarnings: 0.0,  }

      totalClicks: 0,

      totalSales: 0,  void setError(String? error) {

      pendingPayout: 0.0,    state = state.copyWith(error: error);

      clickHistory: [],  }

      salesHistory: [],

    );  void setLastUpdated() {

  }    state = state.copyWith(lastUpdated: DateTime.now());

  }

  List<String> _getDefaultCategories() {

    return [  void reset() {

      'Shopping',    state = const RewardServiceStateData();

      'Food & Dining',  }

      'Travel',}
      'Entertainment',
      'Fashion',
      'Electronics',
      'Health & Beauty',
      'Finance',
      'Education',
      'Gaming',
    ];
  }

  void dispose() {
    _cache.close();
  }
}

// Custom exceptions
class RewardServiceException implements Exception {
  final String message;
  final String? code;
  
  const RewardServiceException(this.message, [this.code]);
  
  @override
  String toString() => 'RewardServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends RewardServiceException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class AuthenticationException extends RewardServiceException {
  const AuthenticationException(String message) : super(message, 'AUTH_ERROR');
}

class RateLimitException extends RewardServiceException {
  const RateLimitException(String message) : super(message, 'RATE_LIMIT');
}