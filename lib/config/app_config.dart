// lib/config/app_config.dart

enum Environment { development, staging, production }

class AppConfig {
  static Environment _environment = Environment.development;
  
  // Environment Detection
  static Environment get environment => _environment;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  // API Configuration
  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://10.0.2.2:3000/api/v1'; // 10.0.2.2 = localhost สำหรับ Android Emulator
      case Environment.staging:
        return 'https://staging-api.eqnode.com/api/v1';
      case Environment.production:
        return 'https://api.eqnode.com/api/v1';
    }
  }
  
  // MQTT Configuration
  static String get mqttHost {
    switch (_environment) {
      case Environment.development:
        return 'mqtt.uiot.cloud'; // Real MQTT broker
      case Environment.staging:
        return 'staging-mqtt.eqnode.com';
      case Environment.production:
        return 'mqtt.eqnode.com';
    }
  }
  
  // MQTT Topics
  static String get mqttDataTopic => 'eqnode.tarita/hub/#';
  static String get mqttAlertTopic => 'eqnode.tarita/hub/alert';
  static String get mqttStatusTopic => 'eqnode.tarita/hub/status';
  
  static int get mqttPort {
    switch (_environment) {
      case Environment.development:
        return 1883;
      case Environment.staging:
        return 1883;
      case Environment.production:
        return 8883; // TLS port for production
    }
  }
  
  static int get mqttWebSocketPort {
    switch (_environment) {
      case Environment.development:
        return 8083;
      case Environment.staging:
        return 8083;
      case Environment.production:
        return 8084; // Secure WebSocket port
    }
  }
  
  static String get mqttUsername {
    switch (_environment) {
      case Environment.development:
        return 'ethernet'; // Current development credentials
      case Environment.staging:
        return const String.fromEnvironment('MQTT_USERNAME_STAGING', defaultValue: 'staging_user');
      case Environment.production:
        return const String.fromEnvironment('MQTT_USERNAME_PROD', defaultValue: 'prod_user');
    }
  }
  
  static String get mqttPassword {
    switch (_environment) {
      case Environment.development:
        return 'ei8jZz87wx'; // Current development credentials
      case Environment.staging:
        return const String.fromEnvironment('MQTT_PASSWORD_STAGING', defaultValue: 'staging_pass');
      case Environment.production:
        return const String.fromEnvironment('MQTT_PASSWORD_PROD', defaultValue: 'prod_pass');
    }
  }
  
  // Database Configuration (for local SQLite)
  static String get databaseName {
    switch (_environment) {
      case Environment.development:
        return 'eqnode_dev.db';
      case Environment.staging:
        return 'eqnode_staging.db';
      case Environment.production:
        return 'eqnode_prod.db';
    }
  }
  
  // Firebase Configuration
  static String get firebaseProjectId {
    switch (_environment) {
      case Environment.development:
        return 'eqnode-dev';
      case Environment.staging:
        return 'eqnode-staging';
      case Environment.production:
        return 'eqnode-prod';
    }
  }
  
  // Feature Flags
  static bool get enableMockData {
    switch (_environment) {
      case Environment.development:
        return false; // ✅ ปิด Mock Data - ใช้ของจริงทั้งหมด
      case Environment.staging:
        return false; // Use real data in staging
      case Environment.production:
        return false; // Never use mock data in production
    }
  }
  
  static bool get showMqttDevicesTab {
    // Show MQTT devices tab for monitoring real-time connections
    return true; // Always show in all environments for debugging
  }
  
  static bool get enableQRScanner {
    // Enable QR code scanning for device registration
    return true;
  }
  
  static bool get enableDebugLogging {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false; // Disable debug logs in production
    }
  }
  
  static bool get enableCrashReporting {
    switch (_environment) {
      case Environment.development:
        return false; // Don't send crash reports from dev
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }
  
  // Security Configuration
  static bool get useHttps {
    switch (_environment) {
      case Environment.development:
        return false; // Allow HTTP for local development
      case Environment.staging:
        return true;
      case Environment.production:
        return true; // Always use HTTPS in production
    }
  }
  
  static bool get enableCertificatePinning {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return false;
      case Environment.production:
        return true; // Enable certificate pinning in production
    }
  }
  
  // App Configuration
  static String get appName {
    switch (_environment) {
      case Environment.development:
        return 'eQNode Dev';
      case Environment.staging:
        return 'eQNode Staging';
      case Environment.production:
        return 'eQNode';
    }
  }
  
  static String get appVersion => '1.0.0';
  
  static String get buildNumber {
    return const String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');
  }
  
  // Notification Configuration
  static Duration get notificationCooldown {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 10); // Short cooldown for testing
      case Environment.staging:
        return const Duration(minutes: 1);
      case Environment.production:
        return const Duration(minutes: 5); // Prevent notification spam
    }
  }
  
  // Default Alert Settings (can be overridden by user settings)
  static double get defaultAlertThreshold => 3.0; // Richter scale
  static int get defaultMaxNotificationCount => 3; // Max notifications per event
  static int get minNotificationCount => 1;
  static int get maxNotificationCount => 10;
  
  // Badge Counter Configuration
  static bool get enableBadgeCounter => true;
  static int get maxBadgeCount => 99; // Show "99+" for counts above this
  
  // Performance Configuration
  static int get maxDevicesPerUser {
    switch (_environment) {
      case Environment.development:
        return 100; // High limit for testing
      case Environment.staging:
        return 50;
      case Environment.production:
        return 10; // Reasonable limit for production
    }
  }
  
  static Duration get apiTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 30); // Longer timeout for debugging
      case Environment.staging:
        return const Duration(seconds: 15);
      case Environment.production:
        return const Duration(seconds: 10); // Fast timeout for production
    }
  }
  
  static int get maxEventsToCache => 100; // Maximum events to keep in memory
  static Duration get cacheExpiration => const Duration(minutes: 5);
  
  // QR Code Configuration
  static String get qrCodePrefix => 'EQNODE://'; // Expected QR code format prefix
  static Duration get qrScanTimeout => const Duration(seconds: 30);
  
  // Global Events Configuration
  static bool get enableGlobalEvents => true;
  static int get globalEventsPageSize => 20;
  static double get globalEventsMinMagnitude => 2.0;
  
  // Utility Methods
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  static Map<String, dynamic> toJson() {
    return {
      'environment': _environment.name,
      'baseUrl': baseUrl,
      'mqttHost': mqttHost,
      'mqttPort': mqttPort,
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'enableMockData': enableMockData,
      'enableDebugLogging': enableDebugLogging,
      'useHttps': useHttps,
      'showMqttDevicesTab': showMqttDevicesTab,
      'enableQRScanner': enableQRScanner,
      'defaultAlertThreshold': defaultAlertThreshold,
      'enableBadgeCounter': enableBadgeCounter,
      'enableGlobalEvents': enableGlobalEvents,
    };
  }
  
  static void printConfig() {
    if (enableDebugLogging) {
      print('=== App Configuration ===');
      print('Environment: ${_environment.name}');
      print('Base URL: $baseUrl');
      print('MQTT Host: $mqttHost:$mqttPort');
      print('App Name: $appName');
      print('Version: $appVersion ($buildNumber)');
      print('Mock Data: $enableMockData');
      print('Debug Logging: $enableDebugLogging');
      print('HTTPS: $useHttps');
      print('MQTT Devices Tab: $showMqttDevicesTab');
      print('QR Scanner: $enableQRScanner');
      print('Alert Threshold: $defaultAlertThreshold');
      print('Badge Counter: $enableBadgeCounter');
      print('Global Events: $enableGlobalEvents');
      print('========================');
    }
  }
}