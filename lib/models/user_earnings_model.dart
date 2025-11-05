import 'package:hive/hive.dart';

part 'user_earnings_model.g.dart';

@HiveType(typeId: 5)
class UserEarnings extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final double totalCpcEarnings;

  @HiveField(2)
  final double totalCpsEarnings;

  @HiveField(3)
  final int totalClicks;

  @HiveField(4)
  final int totalSales;

  @HiveField(5)
  final double pendingPayout;

  @HiveField(6)
  final DateTime? lastActivity;

  @HiveField(7)
  final List<ClickHistory> clickHistory;

  @HiveField(8)
  final List<SaleHistory> salesHistory;

  @HiveField(9)
  final DateTime lastUpdated;

  @HiveField(10)
  final Map<String, double> earningsBySource; // earnings per affiliate network

  @HiveField(11)
  final Map<String, int> clicksByCategory; // clicks per category

  @HiveField(12)
  final double lifetimeEarnings; // total earnings ever (including withdrawn)

  @HiveField(13)
  final double totalWithdrawn; // total amount withdrawn

  @HiveField(14)
  final List<WithdrawalHistory> withdrawalHistory;

  UserEarnings({
    required this.userId,
    this.totalCpcEarnings = 0.0,
    this.totalCpsEarnings = 0.0,
    this.totalClicks = 0,
    this.totalSales = 0,
    this.pendingPayout = 0.0,
    this.lastActivity,
    this.clickHistory = const [],
    this.salesHistory = const [],
    required this.lastUpdated,
    this.earningsBySource = const {},
    this.clicksByCategory = const {},
    this.lifetimeEarnings = 0.0,
    this.totalWithdrawn = 0.0,
    this.withdrawalHistory = const [],
  });

  factory UserEarnings.fromJson(Map<String, dynamic> json) {
    return UserEarnings(
      userId: json['userId'] as String,
      totalCpcEarnings: (json['totalCpcEarnings'] as num?)?.toDouble() ?? 0.0,
      totalCpsEarnings: (json['totalCpsEarnings'] as num?)?.toDouble() ?? 0.0,
      totalClicks: json['totalClicks'] as int? ?? 0,
      totalSales: json['totalSales'] as int? ?? 0,
      pendingPayout: (json['pendingPayout'] as num?)?.toDouble() ?? 0.0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'] as String)
          : null,
      clickHistory: (json['clickHistory'] as List<dynamic>?)
              ?.map((item) => ClickHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      salesHistory: (json['salesHistory'] as List<dynamic>?)
              ?.map((item) => SaleHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      earningsBySource: (json['earningsBySource'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {},
      clicksByCategory: (json['clicksByCategory'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          {},
      lifetimeEarnings: (json['lifetimeEarnings'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      withdrawalHistory: (json['withdrawalHistory'] as List<dynamic>?)
              ?.map((item) => WithdrawalHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalCpcEarnings': totalCpcEarnings,
      'totalCpsEarnings': totalCpsEarnings,
      'totalClicks': totalClicks,
      'totalSales': totalSales,
      'pendingPayout': pendingPayout,
      'lastActivity': lastActivity?.toIso8601String(),
      'clickHistory': clickHistory.map((item) => item.toJson()).toList(),
      'salesHistory': salesHistory.map((item) => item.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'earningsBySource': earningsBySource,
      'clicksByCategory': clicksByCategory,
      'lifetimeEarnings': lifetimeEarnings,
      'totalWithdrawn': totalWithdrawn,
      'withdrawalHistory': withdrawalHistory.map((item) => item.toJson()).toList(),
    };
  }

  // Computed properties
  double get totalEarnings => totalCpcEarnings + totalCpsEarnings;
  
  double get conversionRate => totalClicks > 0 ? (totalSales / totalClicks) * 100 : 0.0;
  
  double get averageClickValue => totalClicks > 0 ? totalCpcEarnings / totalClicks : 0.0;
  
  double get averageSaleValue => totalSales > 0 ? totalCpsEarnings / totalSales : 0.0;
  
  bool get canWithdraw => pendingPayout >= 10.0; // Minimum withdrawal amount
  
  String get topEarningSource {
    if (earningsBySource.isEmpty) return 'None';
    return earningsBySource.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  String get mostClickedCategory {
    if (clicksByCategory.isEmpty) return 'None';
    return clicksByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  Duration get daysSinceLastActivity {
    if (lastActivity == null) return Duration.zero;
    return DateTime.now().difference(lastActivity!);
  }
  
  List<ClickHistory> get recentClicks {
    final sorted = [...clickHistory];
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(10).toList();
  }
  
  List<SaleHistory> get recentSales {
    final sorted = [...salesHistory];
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(10).toList();
  }

  // Helper methods
  double getEarningsForSource(String source) {
    return earningsBySource[source] ?? 0.0;
  }
  
  int getClicksForCategory(String category) {
    return clicksByCategory[category] ?? 0;
  }
  
  List<ClickHistory> getClicksForToday() {
    final today = DateTime.now();
    return clickHistory.where((click) {
      return click.timestamp.year == today.year &&
             click.timestamp.month == today.month &&
             click.timestamp.day == today.day;
    }).toList();
  }
  
  double getTodayEarnings() {
    return getClicksForToday().fold(0.0, (sum, click) => sum + click.amount);
  }
  
  UserEarnings copyWith({
    String? userId,
    double? totalCpcEarnings,
    double? totalCpsEarnings,
    int? totalClicks,
    int? totalSales,
    double? pendingPayout,
    DateTime? lastActivity,
    List<ClickHistory>? clickHistory,
    List<SaleHistory>? salesHistory,
    DateTime? lastUpdated,
    Map<String, double>? earningsBySource,
    Map<String, int>? clicksByCategory,
    double? lifetimeEarnings,
    double? totalWithdrawn,
    List<WithdrawalHistory>? withdrawalHistory,
  }) {
    return UserEarnings(
      userId: userId ?? this.userId,
      totalCpcEarnings: totalCpcEarnings ?? this.totalCpcEarnings,
      totalCpsEarnings: totalCpsEarnings ?? this.totalCpsEarnings,
      totalClicks: totalClicks ?? this.totalClicks,
      totalSales: totalSales ?? this.totalSales,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      lastActivity: lastActivity ?? this.lastActivity,
      clickHistory: clickHistory ?? this.clickHistory,
      salesHistory: salesHistory ?? this.salesHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      earningsBySource: earningsBySource ?? this.earningsBySource,
      clicksByCategory: clicksByCategory ?? this.clicksByCategory,
      lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      withdrawalHistory: withdrawalHistory ?? this.withdrawalHistory,
    );
  }

  @override
  String toString() {
    return 'UserEarnings(userId: $userId, total: ${totalEarnings.toStringAsFixed(2)}, clicks: $totalClicks, sales: $totalSales)';
  }
}

@HiveType(typeId: 6)
class ClickHistory extends HiveObject {
  @HiveField(0)
  final String clickId;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String source;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String offerId;

  @HiveField(5)
  final String? category;

  ClickHistory({
    required this.clickId,
    required this.amount,
    required this.source,
    required this.timestamp,
    required this.offerId,
    this.category,
  });

  factory ClickHistory.fromJson(Map<String, dynamic> json) {
    return ClickHistory(
      clickId: json['clickId'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: json['source'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      offerId: json['offerId'] as String,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clickId': clickId,
      'amount': amount,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
      'offerId': offerId,
      'category': category,
    };
  }
}

@HiveType(typeId: 7)
class SaleHistory extends HiveObject {
  @HiveField(0)
  final String saleId;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String source;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String offerId;

  @HiveField(5)
  final double orderValue;

  @HiveField(6)
  final String status; // confirmed, pending, rejected

  SaleHistory({
    required this.saleId,
    required this.amount,
    required this.source,
    required this.timestamp,
    required this.offerId,
    required this.orderValue,
    this.status = 'confirmed',
  });

  factory SaleHistory.fromJson(Map<String, dynamic> json) {
    return SaleHistory(
      saleId: json['saleId'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: json['source'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      offerId: json['offerId'] as String,
      orderValue: (json['orderValue'] as num).toDouble(),
      status: json['status'] as String? ?? 'confirmed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'amount': amount,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
      'offerId': offerId,
      'orderValue': orderValue,
      'status': status,
    };
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

@HiveType(typeId: 8)
class WithdrawalHistory extends HiveObject {
  @HiveField(0)
  final String withdrawalId;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String status; // pending, completed, failed

  @HiveField(4)
  final String? transactionId;

  @HiveField(5)
  final String method; // bank_transfer, upi, etc.

  WithdrawalHistory({
    required this.withdrawalId,
    required this.amount,
    required this.timestamp,
    this.status = 'pending',
    this.transactionId,
    this.method = 'bank_transfer',
  });

  factory WithdrawalHistory.fromJson(Map<String, dynamic> json) {
    return WithdrawalHistory(
      withdrawalId: json['withdrawalId'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String? ?? 'pending',
      transactionId: json['transactionId'] as String?,
      method: json['method'] as String? ?? 'bank_transfer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'withdrawalId': withdrawalId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'transactionId': transactionId,
      'method': method,
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

// Factory class for creating empty instances
class UserEarningsFactory {
  static UserEarnings createEmpty(String userId) {
    return UserEarnings(
      userId: userId,
      lastUpdated: DateTime.now(),
    );
  }

  static UserEarnings createFromOfflineData({
    required String userId,
    required List<Map<String, dynamic>> offlineClicks,
  }) {
    double totalCpc = 0.0;
    int clickCount = 0;
    final clickHistory = <ClickHistory>[];
    final earningsBySource = <String, double>{};
    final clicksByCategory = <String, int>{};

    for (final click in offlineClicks) {
      final amount = (click['amount'] as num).toDouble();
      final source = click['source'] as String;
      final category = click['category'] as String?;

      totalCpc += amount;
      clickCount++;

      clickHistory.add(ClickHistory(
        clickId: click['id'] as String,
        amount: amount,
        source: source,
        timestamp: DateTime.parse(click['timestamp'] as String),
        offerId: click['offerId'] as String,
        category: category,
      ));

      earningsBySource[source] = (earningsBySource[source] ?? 0.0) + amount;
      if (category != null) {
        clicksByCategory[category] = (clicksByCategory[category] ?? 0) + 1;
      }
    }

    return UserEarnings(
      userId: userId,
      totalCpcEarnings: totalCpc,
      totalClicks: clickCount,
      clickHistory: clickHistory,
      earningsBySource: earningsBySource,
      clicksByCategory: clicksByCategory,
      pendingPayout: totalCpc,
      lifetimeEarnings: totalCpc,
      lastUpdated: DateTime.now(),
      lastActivity: clickHistory.isNotEmpty ? clickHistory.last.timestamp : null,
    );
  }
}