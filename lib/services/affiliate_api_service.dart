import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// API Service for Streaky Affiliate Engine
/// Handles communication with Cloudflare Workers backend
class AffiliateApiService {
  // For local testing - replace with your actual Cloudflare Worker URL after deployment
  static const String baseUrl = "http://localhost:3000/api";
  
  static const Duration _timeout = Duration(seconds: 30);
  
  /// Fetch all available offers
  static Future<List<dynamic>> fetchOffers() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/offers"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to fetch offers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching offers: $e');
    }
  }
  
  /// Fetch ranked offers (globally optimized)
  static Future<List<dynamic>> fetchRankedOffers() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/offers/ranked"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to fetch ranked offers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching ranked offers: $e');
    }
  }
  
  /// Fetch personalized offers for a specific user
  static Future<Map<String, dynamic>> fetchPersonalizedOffers(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/offers/personalized?uid=$userId"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch personalized offers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching personalized offers: $e');
    }
  }
  
  /// Track click and redirect to offer URL
  static Future<void> trackClick({
    required String offerUrl,
    required String userId,
    required String offerId,
  }) async {
    try {
      final trackingUrl = Uri.parse("$baseUrl/click").replace(queryParameters: {
        'offer_url': offerUrl,
        'user_id': userId,
        'offer_id': offerId,
      });
      
      // Launch the tracking URL which will redirect to the actual offer
      if (await canLaunchUrl(trackingUrl)) {
        await launchUrl(
          trackingUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch offer URL');
      }
    } catch (e) {
      throw Exception('Error tracking click: $e');
    }
  }
  
  /// Get user profile data
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/user/profile?uid=$userId"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching user profile: $e');
    }
  }
  
  /// Get daily analytics metrics
  static Future<Map<String, dynamic>> getDailyMetrics([String? date]) async {
    try {
      final queryDate = date ?? DateTime.now().toIso8601String().split('T')[0];
      final response = await http
          .get(
            Uri.parse("$baseUrl/analytics/daily?date=$queryDate"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch daily metrics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching daily metrics: $e');
    }
  }
  
  /// Trigger manual offer ranking update
  static Future<Map<String, dynamic>> triggerRanking() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/rank"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to trigger ranking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error triggering ranking: $e');
    }
  }
  
  /// Check worker status
  static Future<Map<String, dynamic>> getWorkerStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/status"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to check worker status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error checking worker status: $e');
    }
  }
}