// lib/services/firebase_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class FirebaseService {
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  
  // FCM Server Key (should be stored securely in production)
  static String get _serverKey {
    switch (AppConfig.environment) {
      case Environment.development:
        return const String.fromEnvironment('FCM_SERVER_KEY_DEV', 
            defaultValue: 'dev_server_key_placeholder');
      case Environment.staging:
        return const String.fromEnvironment('FCM_SERVER_KEY_STAGING', 
            defaultValue: 'staging_server_key_placeholder');
      case Environment.production:
        return const String.fromEnvironment('FCM_SERVER_KEY_PROD', 
            defaultValue: 'prod_server_key_placeholder');
    }
  }

  // Register FCM token with backend
  static Future<Map<String, dynamic>> registerFCMToken(String token) async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'message': 'FCM token registered successfully',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getStoredToken()}',
        },
        body: jsonEncode({
          'fcmToken': token,
          'platform': defaultTargetPlatform.name,
          'appVersion': AppConfig.appVersion,
        }),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to register FCM token',
        };
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error registering FCM token: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send push notification (server-side functionality for testing)
  static Future<Map<String, dynamic>> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (AppConfig.enableDebugLogging) {
        print('Mock FCM notification sent: $title - $body');
      }
      return {
        'success': true,
        'messageId': 'mock_message_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    try {
      final payload = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(payload),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['success'] == 1,
          'messageId': result['results']?[0]?['message_id'],
          'error': result['results']?[0]?['error'],
        };
      } else {
        return {
          'success': false,
          'message': 'FCM request failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error sending FCM notification: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send notification to multiple tokens
  static Future<Map<String, dynamic>> sendMulticastNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (AppConfig.enableDebugLogging) {
        print('Mock FCM multicast notification sent to ${tokens.length} devices: $title');
      }
      return {
        'success': true,
        'successCount': tokens.length,
        'failureCount': 0,
      };
    }

    try {
      final payload = {
        'registration_ids': tokens,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(payload),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'successCount': result['success'] ?? 0,
          'failureCount': result['failure'] ?? 0,
          'results': result['results'],
        };
      } else {
        return {
          'success': false,
          'message': 'FCM multicast request failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error sending FCM multicast notification: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send topic-based notification
  static Future<Map<String, dynamic>> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (AppConfig.enableDebugLogging) {
        print('Mock FCM topic notification sent to topic "$topic": $title');
      }
      return {
        'success': true,
        'messageId': 'mock_topic_message_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    try {
      final payload = {
        'to': '/topics/$topic',
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'timestamp': DateTime.now().toIso8601String(),
          'topic': topic,
          ...?data,
        },
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(payload),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['message_id'] != null,
          'messageId': result['message_id'],
        };
      } else {
        return {
          'success': false,
          'message': 'FCM topic request failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error sending FCM topic notification: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Subscribe to topic
  static Future<Map<String, dynamic>> subscribeToTopic({
    required String token,
    required String topic,
  }) async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (AppConfig.enableDebugLogging) {
        print('Mock FCM topic subscription: $topic');
      }
      return {
        'success': true,
        'message': 'Subscribed to topic successfully',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('https://iid.googleapis.com/iid/v1/$token/rel/topics/$topic'),
        headers: {
          'Authorization': 'key=$_serverKey',
        },
      ).timeout(AppConfig.apiTimeout);

      return {
        'success': response.statusCode == 200,
        'message': response.statusCode == 200 
            ? 'Subscribed to topic successfully'
            : 'Failed to subscribe to topic',
      };
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error subscribing to FCM topic: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Unsubscribe from topic
  static Future<Map<String, dynamic>> unsubscribeFromTopic({
    required String token,
    required String topic,
  }) async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (AppConfig.enableDebugLogging) {
        print('Mock FCM topic unsubscription: $topic');
      }
      return {
        'success': true,
        'message': 'Unsubscribed from topic successfully',
      };
    }

    try {
      final response = await http.delete(
        Uri.parse('https://iid.googleapis.com/iid/v1/$token/rel/topics/$topic'),
        headers: {
          'Authorization': 'key=$_serverKey',
        },
      ).timeout(AppConfig.apiTimeout);

      return {
        'success': response.statusCode == 200,
        'message': response.statusCode == 200 
            ? 'Unsubscribed from topic successfully'
            : 'Failed to unsubscribe from topic',
      };
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error unsubscribing from FCM topic: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Helper method to get stored token (placeholder)
  static Future<String?> _getStoredToken() async {
    // This should integrate with your secure storage
    // For now, return null as placeholder
    return null;
  }

  // Validate FCM token format
  static bool isValidFCMToken(String token) {
    // Basic validation - FCM tokens are typically 152+ characters
    return token.isNotEmpty && token.length > 100;
  }

  // Get notification settings from backend
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'success': true,
        'settings': {
          'earthquakeAlerts': true,
          'tsunamiAlerts': true,
          'maintenanceAlerts': false,
          'weeklyReports': true,
          'soundEnabled': true,
          'vibrationEnabled': true,
          'quietHours': {
            'enabled': false,
            'startTime': '22:00',
            'endTime': '07:00',
          },
        }
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/notification-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getStoredToken()}',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get notification settings',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update notification settings
  static Future<Map<String, dynamic>> updateNotificationSettings(
      Map<String, dynamic> settings) async {
    if (AppConfig.enableMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'success': true,
        'message': 'Notification settings updated successfully',
      };
    }

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/auth/notification-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getStoredToken()}',
        },
        body: jsonEncode(settings),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to update notification settings',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}