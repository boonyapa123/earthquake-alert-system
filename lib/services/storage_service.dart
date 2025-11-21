// lib/services/storage_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Service for managing app data storage
/// Uses flutter_secure_storage for sensitive data and shared_preferences for UI preferences
class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;

  // Storage Keys
  static const String _keyUserSettings = 'user_settings';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyAlertThreshold = 'alert_threshold';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyMaxNotificationCount = 'max_notification_count';
  static const String _keyBadgeCount = 'badge_count';
  static const String _keyTheme = 'theme';
  static const String _keyLanguage = 'language';
  static const String _keyLastSync = 'last_sync';

  /// Initialize storage service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (AppConfig.enableDebugLogging) {
      print('StorageService initialized');
    }
  }

  /// Ensure preferences are initialized
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== User Settings ====================

  /// Save complete user settings
  static Future<bool> saveUserSettings(UserSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      await _secureStorage.write(key: _keyUserSettings, value: json);
      
      // Also save to shared preferences for quick access
      final prefs = await _getPrefs();
      await prefs.setBool(_keyNotificationsEnabled, settings.notificationsEnabled);
      await prefs.setDouble(_keyAlertThreshold, settings.alertThreshold);
      await prefs.setBool(_keySoundEnabled, settings.soundEnabled);
      await prefs.setBool(_keyVibrationEnabled, settings.vibrationEnabled);
      await prefs.setInt(_keyMaxNotificationCount, settings.maxNotificationCount);
      
      if (AppConfig.enableDebugLogging) {
        print('User settings saved successfully');
      }
      return true;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error saving user settings: $e');
      }
      return false;
    }
  }

  /// Load user settings
  static Future<UserSettings> loadUserSettings() async {

    try {
      final json = await _secureStorage.read(key: _keyUserSettings);
      if (json != null) {
        final data = jsonDecode(json);
        return UserSettings.fromJson(data);
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error loading user settings: $e');
      }
    }
    
    // Return default settings if not found or error
    return UserSettings.defaultSettings();
  }

  // ==================== Individual Settings ====================

  /// Get notifications enabled status
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Set notifications enabled status
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    return await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Get alert threshold
  static Future<double> getAlertThreshold() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keyAlertThreshold) ?? AppConfig.defaultAlertThreshold;
  }

  /// Set alert threshold
  static Future<bool> setAlertThreshold(double threshold) async {
    final prefs = await _getPrefs();
    return await prefs.setDouble(_keyAlertThreshold, threshold);
  }

  /// Get sound enabled status
  static Future<bool> getSoundEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  /// Set sound enabled status
  static Future<bool> setSoundEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    return await prefs.setBool(_keySoundEnabled, enabled);
  }

  /// Get vibration enabled status
  static Future<bool> getVibrationEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyVibrationEnabled) ?? true;
  }

  /// Set vibration enabled status
  static Future<bool> setVibrationEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    return await prefs.setBool(_keyVibrationEnabled, enabled);
  }

  /// Get max notification count
  static Future<int> getMaxNotificationCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyMaxNotificationCount) ?? AppConfig.defaultMaxNotificationCount;
  }

  /// Set max notification count
  static Future<bool> setMaxNotificationCount(int count) async {
    final prefs = await _getPrefs();
    return await prefs.setInt(_keyMaxNotificationCount, count);
  }

  // ==================== Badge Counter ====================

  /// Get badge count
  static Future<int> getBadgeCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyBadgeCount) ?? 0;
  }

  /// Set badge count
  static Future<bool> setBadgeCount(int count) async {
    final prefs = await _getPrefs();
    return await prefs.setInt(_keyBadgeCount, count);
  }

  /// Increment badge count
  static Future<int> incrementBadgeCount() async {
    final currentCount = await getBadgeCount();
    final newCount = currentCount + 1;
    await setBadgeCount(newCount);
    return newCount;
  }

  /// Reset badge count
  static Future<bool> resetBadgeCount() async {
    return await setBadgeCount(0);
  }

  // ==================== UI Preferences ====================

  /// Get theme preference
  static Future<String> getTheme() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyTheme) ?? 'system';
  }

  /// Set theme preference
  static Future<bool> setTheme(String theme) async {
    final prefs = await _getPrefs();
    return await prefs.setString(_keyTheme, theme);
  }

  /// Get language preference
  static Future<String> getLanguage() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyLanguage) ?? 'th';
  }

  /// Set language preference
  static Future<bool> setLanguage(String language) async {
    final prefs = await _getPrefs();
    return await prefs.setString(_keyLanguage, language);
  }

  // ==================== Sync Management ====================

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getInt(_keyLastSync);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Set last sync timestamp
  static Future<bool> setLastSyncTime(DateTime time) async {
    final prefs = await _getPrefs();
    return await prefs.setInt(_keyLastSync, time.millisecondsSinceEpoch);
  }

  // ==================== Secure Data ====================

  /// Save sensitive data securely
  static Future<bool> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error saving secure data: $e');
      }
      return false;
    }
  }

  /// Read sensitive data securely
  static Future<String?> readSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error reading secure data: $e');
      }
      return null;
    }
  }

  /// Delete sensitive data
  static Future<bool> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return true;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error deleting secure data: $e');
      }
      return false;
    }
  }

  /// Clear all secure data
  static Future<bool> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error clearing secure data: $e');
      }
      return false;
    }
  }

  // ==================== Clear All Data ====================

  /// Clear all stored data (logout)
  static Future<bool> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await _getPrefs();
      await prefs.clear();
      if (AppConfig.enableDebugLogging) {
        print('All storage cleared');
      }
      return true;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error clearing storage: $e');
      }
      return false;
    }
  }
}

// ==================== User Settings Model ====================

class UserSettings {
  final bool notificationsEnabled;
  final double alertThreshold;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int maxNotificationCount;
  final String theme;
  final String language;

  UserSettings({
    required this.notificationsEnabled,
    required this.alertThreshold,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.maxNotificationCount,
    required this.theme,
    required this.language,
  });

  factory UserSettings.defaultSettings() {
    return UserSettings(
      notificationsEnabled: true,
      alertThreshold: AppConfig.defaultAlertThreshold,
      soundEnabled: true,
      vibrationEnabled: true,
      maxNotificationCount: AppConfig.defaultMaxNotificationCount,
      theme: 'system',
      language: 'th',
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      alertThreshold: (json['alertThreshold'] ?? AppConfig.defaultAlertThreshold).toDouble(),
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      maxNotificationCount: json['maxNotificationCount'] ?? AppConfig.defaultMaxNotificationCount,
      theme: json['theme'] ?? 'system',
      language: json['language'] ?? 'th',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'alertThreshold': alertThreshold,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'maxNotificationCount': maxNotificationCount,
      'theme': theme,
      'language': language,
    };
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    double? alertThreshold,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? maxNotificationCount,
    String? theme,
    String? language,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      maxNotificationCount: maxNotificationCount ?? this.maxNotificationCount,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }
}
