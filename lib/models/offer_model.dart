import 'package:hive/hive.dart';

part 'offer_model.g.dart';

@HiveType(typeId: 4)
class OfferModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String source; // cuelinks, admitad, vcommission, etc.

  @HiveField(5)
  final double cpcRate; // Cost per click earnings

  @HiveField(6)
  final double cpsRate; // Cost per sale percentage

  @HiveField(7)
  final String url; // Original affiliate URL

  @HiveField(8)
  final String? imageUrl;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime? expiresAt;

  @HiveField(12)
  final bool isActive;

  @HiveField(13)
  final Map<String, dynamic> metadata; // Additional offer-specific data

  @HiveField(14)
  final double? minOrderValue; // Minimum order for CPS

  @HiveField(15)
  final double? maxCommission; // Maximum CPS commission

  @HiveField(16)
  final String? couponCode; // If offer includes a coupon

  @HiveField(17)
  final int priority; // Display priority (higher = shown first)

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.source,
    required this.cpcRate,
    required this.cpsRate,
    required this.url,
    this.imageUrl,
    this.tags = const [],
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.metadata = const {},
    this.minOrderValue,
    this.maxCommission,
    this.couponCode,
    this.priority = 0,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      source: json['source'] as String,
      cpcRate: (json['cpcRate'] as num).toDouble(),
      cpsRate: (json['cpsRate'] as num).toDouble(),
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      maxCommission: (json['maxCommission'] as num?)?.toDouble(),
      couponCode: json['couponCode'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'source': source,
      'cpcRate': cpcRate,
      'cpsRate': cpsRate,
      'url': url,
      'imageUrl': imageUrl,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
      'minOrderValue': minOrderValue,
      'maxCommission': maxCommission,
      'couponCode': couponCode,
      'priority': priority,
    };
  }

  // Computed properties
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  bool get isValidNow => isActive && !isExpired;
  
  String get displayCategory => category.substring(0, 1).toUpperCase() + 
                               category.substring(1).toLowerCase();
  
  String get networkDisplayName {
    switch (source.toLowerCase()) {
      case 'cuelinks':
        return 'Cuelinks';
      case 'admitad':
        return 'Admitad';
      case 'vcommission':
        return 'vCommission';
      case 'awin':
        return 'Awin';
      case 'involve_asia':
        return 'Involve Asia';
      case 'impact':
        return 'Impact';
      default:
        return source.toUpperCase();
    }
  }

  String get currencySymbol {
    switch (source.toLowerCase()) {
      case 'cuelinks':
      case 'vcommission':
        return '₹';
      case 'admitad':
      case 'awin':
      case 'involve_asia':
      case 'impact':
        return '\$';
      default:
        return '₹';
    }
  }

  double get estimatedEarningPer100Clicks {
    // Assume 2% conversion rate for CPS
    final cpsEarnings = (2 * cpsRate * 50); // Assume ₹50 average order
    final cpcEarnings = 100 * cpcRate;
    return cpcEarnings + cpsEarnings;
  }

  String get earningPotentialText {
    final potential = estimatedEarningPer100Clicks;
    return 'Earn ~${currencySymbol}${potential.toStringAsFixed(0)} per 100 clicks';
  }

  // Helper methods
  bool matchesSearch(String query) {
    final searchTerm = query.toLowerCase();
    return title.toLowerCase().contains(searchTerm) ||
           description.toLowerCase().contains(searchTerm) ||
           category.toLowerCase().contains(searchTerm) ||
           tags.any((tag) => tag.toLowerCase().contains(searchTerm));
  }

  OfferModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? source,
    double? cpcRate,
    double? cpsRate,
    String? url,
    String? imageUrl,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
    double? minOrderValue,
    double? maxCommission,
    String? couponCode,
    int? priority,
  }) {
    return OfferModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      source: source ?? this.source,
      cpcRate: cpcRate ?? this.cpcRate,
      cpsRate: cpsRate ?? this.cpsRate,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxCommission: maxCommission ?? this.maxCommission,
      couponCode: couponCode ?? this.couponCode,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() {
    return 'OfferModel(id: $id, title: $title, source: $source, cpc: $cpcRate, cps: $cpsRate%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfferModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Helper class for offer categories
class OfferCategory {
  static const String shopping = 'shopping';
  static const String travel = 'travel';
  static const String food = 'food';
  static const String electronics = 'electronics';
  static const String fashion = 'fashion';
  static const String beauty = 'beauty';
  static const String home = 'home';
  static const String sports = 'sports';
  static const String books = 'books';
  static const String entertainment = 'entertainment';
  static const String finance = 'finance';
  static const String health = 'health';
  static const String education = 'education';
  static const String automotive = 'automotive';
  static const String services = 'services';

  static const List<String> allCategories = [
    shopping,
    travel,
    food,
    electronics,
    fashion,
    beauty,
    home,
    sports,
    books,
    entertainment,
    finance,
    health,
    education,
    automotive,
    services,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case shopping:
        return 'Shopping';
      case travel:
        return 'Travel & Hotels';
      case food:
        return 'Food & Dining';
      case electronics:
        return 'Electronics';
      case fashion:
        return 'Fashion & Clothing';
      case beauty:
        return 'Beauty & Personal Care';
      case home:
        return 'Home & Garden';
      case sports:
        return 'Sports & Fitness';
      case books:
        return 'Books & Media';
      case entertainment:
        return 'Entertainment';
      case finance:
        return 'Finance & Insurance';
      case health:
        return 'Health & Wellness';
      case education:
        return 'Education & Courses';
      case automotive:
        return 'Automotive';
      case services:
        return 'Services';
      default:
        return category.substring(0, 1).toUpperCase() + 
               category.substring(1).toLowerCase();
    }
  }

  static String getIcon(String category) {
    switch (category) {
      case shopping:
        return '🛍️';
      case travel:
        return '✈️';
      case food:
        return '🍕';
      case electronics:
        return '📱';
      case fashion:
        return '👕';
      case beauty:
        return '💄';
      case home:
        return '🏠';
      case sports:
        return '⚽';
      case books:
        return '📚';
      case entertainment:
        return '🎬';
      case finance:
        return '💳';
      case health:
        return '⚕️';
      case education:
        return '🎓';
      case automotive:
        return '🚗';
      case services:
        return '🔧';
      default:
        return '🏷️';
    }
  }
}