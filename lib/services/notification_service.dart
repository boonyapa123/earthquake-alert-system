// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_app_badger/flutter_app_badger.dart'; // Removed due to build issues
import '../config/app_config.dart';
import 'firebase_service.dart';
import 'storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static String? _fcmToken;
  static Function(Map<String, dynamic>)? _onMessageReceived;

  // การตั้งค่าเริ่มต้น
  static Future<void> initialize({
    Function(Map<String, dynamic>)? onMessageReceived,
  }) async {
    if (_isInitialized) return;
    
    _onMessageReceived = onMessageReceived;
    
    // Request notification permission
    await _requestPermissions();
    
    // Create notification channels for Android
    await _createNotificationChannels();
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (AppConfig.enableDebugLogging) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        }
        
        // Handle notification tap
        if (response.payload != null && _onMessageReceived != null) {
          try {
            final data = <String, dynamic>{'payload': response.payload};
            _onMessageReceived!(data);
          } catch (e) {
            if (AppConfig.enableDebugLogging) {
              debugPrint('Error handling notification tap: $e');
            }
          }
        }
      },
    );
    
    // Initialize FCM if not in mock mode
    if (!AppConfig.enableMockData) {
      await _initializeFCM();
    }
    
    _isInitialized = true;
  }

  // Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    // Critical alerts channel (for lock screen)
    const AndroidNotificationChannel criticalChannel = AndroidNotificationChannel(
      'critical_alerts',
      'Critical Alerts',
      description: 'High priority earthquake alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // General alerts channel
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_alerts',
      'General Alerts',
      description: 'General earthquake notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(criticalChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  // Initialize Firebase Cloud Messaging
  static Future<void> _initializeFCM() async {
    try {
      // TODO: Initialize Firebase app if not already initialized
      // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // TODO: Get FCM token
      // final messaging = FirebaseMessaging.instance;
      // _fcmToken = await messaging.getToken();
      
      // For now, use a mock token in development
      if (AppConfig.isDevelopment) {
        _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      if (_fcmToken != null) {
        // Register token with backend
        await FirebaseService.registerFCMToken(_fcmToken!);
        
        if (AppConfig.enableDebugLogging) {
          debugPrint('FCM Token registered: $_fcmToken');
        }
      }
      
      // TODO: Set up message handlers
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('Error initializing FCM: $e');
      }
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(Map<String, dynamic> message) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('Foreground message received: $message');
    }
    
    // Show local notification for foreground messages
    final notification = message['notification'];
    if (notification != null) {
      showGeneralNotification(
        notification['title'] ?? 'Notification',
        notification['body'] ?? 'You have a new message',
      );
    }
    
    // Call callback if provided
    if (_onMessageReceived != null) {
      _onMessageReceived!(message);
    }
  }

  // Handle message opened app
  static void _handleMessageOpenedApp(Map<String, dynamic> message) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('Message opened app: $message');
    }
    
    // Call callback if provided
    if (_onMessageReceived != null) {
      _onMessageReceived!(message);
    }
  }
  
  static Future<void> _requestPermissions() async {
    // Request notification permission for Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // ฟังก์ชันแสดงการแจ้งเตือนแผ่นดินไหว (รองรับ overload)
  static Future<void> showEarthquakeAlert(String title, String body, {double? magnitude}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final isCritical = magnitude != null && magnitude >= 5.0;
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isCritical ? 'critical_alerts' : 'general_alerts',
      isCritical ? 'Critical Alerts' : 'General Alerts',
      channelDescription: isCritical 
          ? 'High priority earthquake alerts'
          : 'General earthquake notifications',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      fullScreenIntent: isCritical, // Show on lock screen for critical alerts
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public, // Show on lock screen
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical, // iOS critical alert
    );
    
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
      title,
      body,
      platformDetails,
      payload: 'earthquake_${magnitude ?? 0.0}',
    );
  }
  
  // ฟังก์ชันแสดงการแจ้งเตือนทั่วไป
  static Future<void> showGeneralNotification(String title, String body) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_channel', 
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance, 
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
    );
  }

  // FCM Token Management
  static String? get fcmToken => _fcmToken;
  
  static Future<String?> getFCMToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    if (AppConfig.enableMockData) {
      _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      return _fcmToken;
    }
    
    try {
      // TODO: Get real FCM token
      // final messaging = FirebaseMessaging.instance;
      // _fcmToken = await messaging.getToken();
      return _fcmToken;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('Error getting FCM token: $e');
      }
      return null;
    }
  }
  
  static Future<void> refreshFCMToken() async {
    try {
      if (AppConfig.enableMockData) {
        _fcmToken = 'refreshed_mock_token_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // TODO: Refresh real FCM token
        // final messaging = FirebaseMessaging.instance;
        // await messaging.deleteToken();
        // _fcmToken = await messaging.getToken();
      }
      
      if (_fcmToken != null) {
        await FirebaseService.registerFCMToken(_fcmToken!);
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('Error refreshing FCM token: $e');
      }
    }
  }

  // Subscribe to earthquake alerts for specific region
  static Future<void> subscribeToRegionAlerts(String region) async {
    final token = await getFCMToken();
    if (token != null) {
      await FirebaseService.subscribeToTopic(
        token: token,
        topic: 'earthquake_alerts_$region',
      );
    }
  }

  // Unsubscribe from region alerts
  static Future<void> unsubscribeFromRegionAlerts(String region) async {
    final token = await getFCMToken();
    if (token != null) {
      await FirebaseService.unsubscribeFromTopic(
        token: token,
        topic: 'earthquake_alerts_$region',
      );
    }
  }

  // Send test notification (for development/testing)
  static Future<void> sendTestNotification() async {
    final token = await getFCMToken();
    if (token != null) {
      await FirebaseService.sendNotification(
        token: token,
        title: '🧪 Test Notification',
        body: 'This is a test notification from eQNode app',
        data: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  // Get notification settings
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    return await FirebaseService.getNotificationSettings();
  }

  // Update notification settings
  static Future<Map<String, dynamic>> updateNotificationSettings(
      Map<String, dynamic> settings) async {
    return await FirebaseService.updateNotificationSettings(settings);
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (AppConfig.enableMockData) {
      return true;
    }
    
    // Check system notification permission
    final permission = await Permission.notification.status;
    return permission.isGranted;
  }

  // Open notification settings
  static Future<void> openNotificationSettings() async {
    await Permission.notification.request();
  }

  // ==================== Badge Counter ====================

  /// Update app badge count
  static Future<void> updateBadge(int count) async {
    if (!AppConfig.enableBadgeCounter) return;

    try {
      // Badge counter functionality temporarily disabled due to package compatibility issues
      // TODO: Implement using platform channels or alternative package
      
      // Save to storage
      await StorageService.setBadgeCount(count);
      
      if (AppConfig.enableDebugLogging) {
        debugPrint('Badge count saved to storage: $count (visual badge disabled)');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('Error updating badge: $e');
      }
    }
  }

  /// Increment badge count
  static Future<void> incrementBadge() async {
    if (!AppConfig.enableBadgeCounter) return;

    try {
      final currentCount = await StorageService.getBadgeCount();
      await updateBadge(currentCount + 1);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('Error incrementing badge: $e');
      }
    }
  }

  /// Reset badge count to zero
  static Future<void> resetBadge() async {
    if (!AppConfig.enableBadgeCounter) return;

    try {
      // Badge counter functionality temporarily disabled
      await StorageService.resetBadgeCount();
      
      if (AppConfig.enableDebugLogging) {
        debugPrint('Badge count reset to 0 in storage');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('Error resetting badge: $e');
      }
    }
  }

  /// Get current badge count
  static Future<int> getBadgeCount() async {
    return await StorageService.getBadgeCount();
  }
}
