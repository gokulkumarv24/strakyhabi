// Copilot Prompt:
// Create a Dart model for a reward coupon containing offer_id, user_id, title, type (cpc/cps), reward_amount, tracking_link, status, and timestamps.

import 'package:json_annotation/json_annotation.dart';

part 'reward_model.g.dart';

@JsonSerializable()
class RewardModel {
  @JsonKey(name: 'coupon_id')
  final String couponId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'offer_id')
  final String offerId;
  
  final String title;
  final String description;
  final RewardType type;
  
  @JsonKey(name: 'reward_amount')
  final double rewardAmount;
  
  @JsonKey(name: 'tracking_link')
  final String trackingLink;
  
  final RewardStatus status;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  
  @JsonKey(name: 'claimed_at')
  final DateTime? claimedAt;
  
  final String? imageUrl;
  final String? brand;
  final String? category;
  final Map<String, dynamic>? metadata;

  const RewardModel({
    required this.couponId,
    required this.userId,
    required this.offerId,
    required this.title,
    required this.description,
    required this.type,
    required this.rewardAmount,
    required this.trackingLink,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.claimedAt,
    this.imageUrl,
    this.brand,
    this.category,
    this.metadata,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) => _$RewardModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$RewardModelToJson(this);

  RewardModel copyWith({
    String? couponId,
    String? userId,
    String? offerId,
    String? title,
    String? description,
    RewardType? type,
    double? rewardAmount,
    String? trackingLink,
    RewardStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? claimedAt,
    String? imageUrl,
    String? brand,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      couponId: couponId ?? this.couponId,
      userId: userId ?? this.userId,
      offerId: offerId ?? this.offerId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      trackingLink: trackingLink ?? this.trackingLink,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      claimedAt: claimedAt ?? this.claimedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isClaimed => status == RewardStatus.claimed;

  bool get isUnlocked => status == RewardStatus.unlocked;

  bool get isPending => status == RewardStatus.pending;

  String get formattedReward {
    if (type == RewardType.cpc) {
      return '₹${rewardAmount.toStringAsFixed(2)}';
    } else {
      return '${rewardAmount.toStringAsFixed(1)}%';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case RewardType.cpc:
        return 'Instant Reward';
      case RewardType.cps:
        return 'Cashback';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardModel && other.couponId == couponId;
  }

  @override
  int get hashCode => couponId.hashCode;

  @override
  String toString() {
    return 'RewardModel(couponId: $couponId, title: $title, type: $type, amount: $rewardAmount, status: $status)';
  }
}

@JsonEnum()
enum RewardType {
  @JsonValue('cpc')
  cpc,
  @JsonValue('cps')
  cps,
}

@JsonEnum()
enum RewardStatus {
  @JsonValue('locked')
  locked,
  @JsonValue('unlocked')
  unlocked,
  @JsonValue('claimed')
  claimed,
  @JsonValue('expired')
  expired,
  @JsonValue('pending')
  pending,
}

@JsonSerializable()
class OfferModel {
  @JsonKey(name: 'offer_id')
  final String offerId;
  
  final String title;
  final String description;
  final String brand;
  final String category;
  final String imageUrl;
  final String trackingUrl;
  
  @JsonKey(name: 'cpc_rate')
  final double cpcRate;
  
  @JsonKey(name: 'cps_rate')
  final double cpsRate;
  
  final String source;
  final String currency;
  final Map<String, dynamic>? terms;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const OfferModel({
    required this.offerId,
    required this.title,
    required this.description,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.trackingUrl,
    required this.cpcRate,
    required this.cpsRate,
    required this.source,
    required this.currency,
    this.terms,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) => _$OfferModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$OfferModelToJson(this);

  double get estimatedEarning => cpcRate + (cpsRate * 0.02 * 100); // 2% conversion, ₹100 avg order

  String get formattedCpc => '₹${cpcRate.toStringAsFixed(2)}';
  
  String get formattedCps => '${cpsRate.toStringAsFixed(1)}%';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfferModel && other.offerId == offerId;
  }

  @override
  int get hashCode => offerId.hashCode;
}

@JsonSerializable()
class UserEarningsModel {
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'total_cpc_earnings')
  final double totalCpcEarnings;
  
  @JsonKey(name: 'total_cps_earnings')
  final double totalCpsEarnings;
  
  @JsonKey(name: 'total_clicks')
  final int totalClicks;
  
  @JsonKey(name: 'total_sales')
  final int totalSales;
  
  @JsonKey(name: 'pending_payout')
  final double pendingPayout;
  
  @JsonKey(name: 'last_activity')
  final DateTime? lastActivity;
  
  @JsonKey(name: 'click_history')
  final List<ClickHistoryModel> clickHistory;
  
  @JsonKey(name: 'sales_history')
  final List<SaleHistoryModel> salesHistory;

  const UserEarningsModel({
    required this.userId,
    required this.totalCpcEarnings,
    required this.totalCpsEarnings,
    required this.totalClicks,
    required this.totalSales,
    required this.pendingPayout,
    this.lastActivity,
    required this.clickHistory,
    required this.salesHistory,
  });

  factory UserEarningsModel.fromJson(Map<String, dynamic> json) => _$UserEarningsModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserEarningsModelToJson(this);

  double get totalEarnings => totalCpcEarnings + totalCpsEarnings;

  double get conversionRate {
    if (totalClicks == 0) return 0.0;
    return (totalSales / totalClicks) * 100;
  }

  bool get canWithdraw => pendingPayout >= 100; // Minimum ₹100

  String get formattedTotalEarnings => '₹${totalEarnings.toStringAsFixed(2)}';
  
  String get formattedPendingPayout => '₹${pendingPayout.toStringAsFixed(2)}';
  
  String get formattedConversionRate => '${conversionRate.toStringAsFixed(1)}%';
}

@JsonSerializable()
class ClickHistoryModel {
  @JsonKey(name: 'click_id')
  final String clickId;
  
  @JsonKey(name: 'offer_id')
  final String offerId;
  
  final double amount;
  final String source;
  final DateTime timestamp;

  const ClickHistoryModel({
    required this.clickId,
    required this.offerId,
    required this.amount,
    required this.source,
    required this.timestamp,
  });

  factory ClickHistoryModel.fromJson(Map<String, dynamic> json) => _$ClickHistoryModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ClickHistoryModelToJson(this);

  Map<String, dynamic> toMap() => {
    'click_id': clickId,
    'offer_id': offerId,
    'amount': amount,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
  };
}

@JsonSerializable()
class SaleHistoryModel {
  @JsonKey(name: 'sale_id')
  final String saleId;
  
  @JsonKey(name: 'offer_id')
  final String offerId;
  
  final double amount;
  
  @JsonKey(name: 'order_value')
  final double orderValue;
  
  final String source;
  final DateTime timestamp;
  final String status;

  const SaleHistoryModel({
    required this.saleId,
    required this.offerId,
    required this.amount,
    required this.orderValue,
    required this.source,
    required this.timestamp,
    required this.status,
  });

  factory SaleHistoryModel.fromJson(Map<String, dynamic> json) => _$SaleHistoryModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$SaleHistoryModelToJson(this);

  Map<String, dynamic> toMap() => {
    'sale_id': saleId,
    'offer_id': offerId,
    'amount': amount,
    'order_value': orderValue,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
  };
}