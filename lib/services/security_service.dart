// lib/services/security_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class SecurityService {
  static const String _keyPrefix = 'eqnode_';
  
  // Generate secure random string
  static String generateSecureToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Hash password securely
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Generate salt for password hashing
  static String generateSalt() {
    return generateSecureToken(32);
  }
  
  // Validate password strength
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final result = {
      'isValid': false,
      'score': 0,
      'feedback': <String>[],
    };
    
    int score = 0;
    final feedback = <String>[];
    
    // Length check
    if (password.length >= 8) {
      score += 1;
    } else {
      feedback.add('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    }
    
    // Uppercase check
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      feedback.add('ควรมีตัวอักษรพิมพ์ใหญ่');
    }
    
    // Lowercase check
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      feedback.add('ควรมีตัวอักษรพิมพ์เล็ก');
    }
    
    // Number check
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      feedback.add('ควรมีตัวเลข');
    }
    
    // Special character check
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
    } else {
      feedback.add('ควรมีอักขระพิเศษ');
    }
    
    // Common password check
    if (_isCommonPassword(password)) {
      score -= 2;
      feedback.add('รหัสผ่านนี้ใช้กันทั่วไป ควรเปลี่ยน');
    }
    
    result['score'] = score;
    result['feedback'] = feedback;
    result['isValid'] = score >= 3 && password.length >= 8;
    
    return result;
  }
  
  static bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
    ];
    return commonPasswords.contains(password.toLowerCase());
  }
  
  // Encrypt sensitive data
  static String encryptData(String data, String key) {
    if (AppConfig.isDevelopment) {
      // Simple base64 encoding for development
      return base64Encode(utf8.encode(data));
    }
    
    // TODO: Implement proper encryption for production
    // Use packages like encrypt or pointycastle
    return base64Encode(utf8.encode(data));
  }
  
  // Decrypt sensitive data
  static String decryptData(String encryptedData, String key) {
    if (AppConfig.isDevelopment) {
      // Simple base64 decoding for development
      try {
        return utf8.decode(base64Decode(encryptedData));
      } catch (e) {
        return encryptedData; // Return as-is if not encrypted
      }
    }
    
    // TODO: Implement proper decryption for production
    try {
      return utf8.decode(base64Decode(encryptedData));
    } catch (e) {
      return encryptedData;
    }
  }
  
  // Validate API response integrity
  static bool validateApiResponse(Map<String, dynamic> response) {
    // Check required fields
    if (!response.containsKey('success')) {
      return false;
    }
    
    // Validate timestamp if present
    if (response.containsKey('timestamp')) {
      try {
        final timestamp = DateTime.parse(response['timestamp']);
        final now = DateTime.now();
        final diff = now.difference(timestamp).abs();
        
        // Response should not be older than 5 minutes
        if (diff.inMinutes > 5) {
          if (AppConfig.enableDebugLogging) {
            print('API response timestamp too old: ${diff.inMinutes} minutes');
          }
          return false;
        }
      } catch (e) {
        if (AppConfig.enableDebugLogging) {
          print('Invalid timestamp in API response: $e');
        }
        return false;
      }
    }
    
    return true;
  }
  
  // Sanitize user input
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'''[<>"']'''), '')
        .replaceAll(RegExp(r'[&]'), '')
        .trim();
  }
  
  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
  
  // Validate phone number format (Thai format)
  static bool isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Thai mobile numbers: 08x-xxx-xxxx or 09x-xxx-xxxx (10 digits)
    // Thai landline: 02-xxx-xxxx (9 digits with area code)
    return RegExp(r'^(08|09)\d{8}$').hasMatch(digitsOnly) ||
           RegExp(r'^02\d{7}$').hasMatch(digitsOnly);
  }
  
  // Generate device fingerprint
  static Future<String> generateDeviceFingerprint() async {
    final components = <String>[];
    
    // Add platform info
    components.add(defaultTargetPlatform.name);
    
    // Add app version
    components.add(AppConfig.appVersion);
    
    // Add timestamp (for uniqueness)
    components.add(DateTime.now().millisecondsSinceEpoch.toString());
    
    // Create hash
    final combined = components.join('|');
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    
    return digest.toString().substring(0, 16);
  }
  
  // Rate limiting check
  static final Map<String, List<DateTime>> _rateLimitMap = {};
  
  static bool checkRateLimit(String key, int maxRequests, Duration window) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);
    
    // Initialize or clean old entries
    _rateLimitMap[key] ??= [];
    _rateLimitMap[key]!.removeWhere((time) => time.isBefore(windowStart));
    
    // Check if limit exceeded
    if (_rateLimitMap[key]!.length >= maxRequests) {
      return false;
    }
    
    // Add current request
    _rateLimitMap[key]!.add(now);
    return true;
  }
  
  // Clear rate limit for key
  static void clearRateLimit(String key) {
    _rateLimitMap.remove(key);
  }
  
  // Security headers for HTTP requests
  static Map<String, String> getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
    };
  }
  
  // Log security events
  static void logSecurityEvent(String event, Map<String, dynamic> details) {
    if (AppConfig.enableDebugLogging) {
      print('SECURITY EVENT: $event');
      print('Details: ${jsonEncode(details)}');
    }
    
    // TODO: Send to security monitoring service in production
    if (AppConfig.isProduction) {
      // Send to security logging service
    }
  }
}
