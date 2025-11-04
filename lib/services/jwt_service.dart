import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// JWT service for authentication and token management
class JwtService {
  static const String _jwtSecret = 'your-256-bit-secret-key-here'; // In production, load from secure storage
  static const String _issuer = 'streaky-app';
  static const Duration _tokenExpiry = Duration(days: 30);

  /// Generate JWT token for user
  static String generateToken({
    required String userId,
    required String email,
    Map<String, dynamic>? additionalClaims,
  }) {
    final now = DateTime.now();
    final expiry = now.add(_tokenExpiry);

    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final payload = {
      'iss': _issuer,
      'sub': userId,
      'email': email,
      'iat': (now.millisecondsSinceEpoch ~/ 1000),
      'exp': (expiry.millisecondsSinceEpoch ~/ 1000),
      'userId': userId,
      ...?additionalClaims,
    };

    final headerEncoded = _base64UrlEncode(utf8.encode(jsonEncode(header)));
    final payloadEncoded = _base64UrlEncode(utf8.encode(jsonEncode(payload)));
    
    final signature = _generateSignature('$headerEncoded.$payloadEncoded');
    
    return '$headerEncoded.$payloadEncoded.$signature';
  }

  /// Verify JWT token
  static bool verifyToken(String token) {
    try {
      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        return false;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      final headerAndPayload = '${parts[0]}.${parts[1]}';
      final signature = parts[2];
      
      final expectedSignature = _generateSignature(headerAndPayload);
      
      return signature == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  /// Decode JWT token payload
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      if (!verifyToken(token)) {
        return null;
      }
      
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  /// Get user ID from token
  static String? getUserIdFromToken(String token) {
    final payload = decodeToken(token);
    return payload?['userId'] as String?;
  }

  /// Get user email from token
  static String? getUserEmailFromToken(String token) {
    final payload = decodeToken(token);
    return payload?['email'] as String?;
  }

  /// Check if token is expired
  static bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  /// Get token expiry date
  static DateTime? getTokenExpiry(String token) {
    try {
      final payload = decodeToken(token);
      if (payload == null) return null;
      
      final exp = payload['exp'] as int?;
      if (exp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }

  /// Refresh token if close to expiry
  static String? refreshTokenIfNeeded({
    required String token,
    required String userId,
    required String email,
    Duration refreshThreshold = const Duration(days: 7),
  }) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return null;
    
    final now = DateTime.now();
    final timeUntilExpiry = expiry.difference(now);
    
    if (timeUntilExpiry <= refreshThreshold) {
      return generateToken(userId: userId, email: email);
    }
    
    return token; // No refresh needed
  }

  /// Generate signature for JWT
  static String _generateSignature(String data) {
    final key = utf8.encode(_jwtSecret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return _base64UrlEncode(digest.bytes);
  }

  /// Base64 URL encode
  static String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Validate token structure
  static bool validateTokenStructure(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    
    try {
      // Try to decode each part
      _base64UrlDecode(parts[0]); // header
      _base64UrlDecode(parts[1]); // payload
      _base64UrlDecode(parts[2]); // signature
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Base64 URL decode
  static List<int> _base64UrlDecode(String str) {
    String normalized = str.replaceAll('-', '+').replaceAll('_', '/');
    
    // Add padding if needed
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }
    
    return base64Decode(normalized);
  }

  /// Generate device-specific token
  static Future<String> generateDeviceToken({
    required String userId,
    required String email,
  }) async {
    String deviceId;
    
    try {
      // Try to get device identifier
      if (Platform.isAndroid || Platform.isIOS) {
        // In a real app, use device_info_plus to get device ID
        deviceId = 'mobile-device-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        deviceId = 'web-device-${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      deviceId = 'unknown-device-${DateTime.now().millisecondsSinceEpoch}';
    }

    return generateToken(
      userId: userId,
      email: email,
      additionalClaims: {
        'deviceId': deviceId,
        'platform': Platform.operatingSystem,
      },
    );
  }

  /// Extract claims from token
  static Map<String, dynamic> extractClaims(String token) {
    final payload = decodeToken(token);
    return payload ?? {};
  }

  /// Check if token has specific claim
  static bool hasClaim(String token, String claimName) {
    final claims = extractClaims(token);
    return claims.containsKey(claimName);
  }

  /// Get claim value from token
  static T? getClaim<T>(String token, String claimName) {
    final claims = extractClaims(token);
    return claims[claimName] as T?;
  }

  /// Create premium token with subscription info
  static String generatePremiumToken({
    required String userId,
    required String email,
    required String subscriptionTier,
    DateTime? subscriptionExpiry,
  }) {
    final additionalClaims = <String, dynamic>{
      'subscriptionTier': subscriptionTier,
      'isPremium': true,
    };

    if (subscriptionExpiry != null) {
      additionalClaims['subscriptionExpiry'] = 
          (subscriptionExpiry.millisecondsSinceEpoch ~/ 1000);
    }

    return generateToken(
      userId: userId,
      email: email,
      additionalClaims: additionalClaims,
    );
  }

  /// Check if token has premium access
  static bool hasPremiumAccess(String token) {
    final claims = extractClaims(token);
    final isPremium = claims['isPremium'] as bool? ?? false;
    
    if (!isPremium) return false;

    // Check subscription expiry
    final expiryTimestamp = claims['subscriptionExpiry'] as int?;
    if (expiryTimestamp != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
      return DateTime.now().isBefore(expiryDate);
    }

    return true; // No expiry means lifetime access
  }

  /// Get subscription tier from token
  static String? getSubscriptionTier(String token) {
    return getClaim<String>(token, 'subscriptionTier');
  }
}