// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'services/user_state.dart';
import 'services/mqtt_manager.dart';
import 'services/notification_service.dart';
import 'services/performance_service.dart';

void main() async {
  // Track app startup performance
  PerformanceService.trackAppStart();
  
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure environment based on build mode
  _configureEnvironment();
  
  // Print configuration for debugging
  AppConfig.printConfig();
  
  // Initialize services
  await _initializeServices();
  
  runApp(
    MultiProvider(
      providers: [
        // 1. UserState Provider (สำหรับจัดการการเข้าสู่ระบบ)
        ChangeNotifierProvider(create: (context) => UserState()),
        
        // 2. MqttManager Provider (สำหรับจัดการ MQTT และ Real Data)
        ChangeNotifierProxyProvider<UserState, MqttManager>(
          create: (context) => MqttManager(
            userState: context.read<UserState>(),
          ),
          update: (context, userState, previous) => 
            previous ?? MqttManager(userState: userState),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

void _configureEnvironment() {
  // Detect environment from build configuration
  const String envString = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  Environment environment;
  switch (envString.toLowerCase()) {
    case 'production':
    case 'prod':
      environment = Environment.production;
      break;
    case 'staging':
    case 'stage':
      environment = Environment.staging;
      break;
    case 'development':
    case 'dev':
    default:
      environment = Environment.development;
      break;
  }
  
  // Override for debug builds
  if (kDebugMode && environment == Environment.production) {
    environment = Environment.development;
    if (AppConfig.enableDebugLogging) {
      print('WARNING: Overriding production environment to development in debug mode');
    }
  }
  
  AppConfig.setEnvironment(environment);
}

Future<void> _initializeServices() async {
  try {
    // Initialize performance monitoring
    PerformanceService.initialize();
    
    // Initialize notification service
    await PerformanceService.timeOperation(
      'initialize_notifications',
      () => NotificationService.initialize(),
    );
    
    // Initialize crash reporting for non-development environments
    if (AppConfig.enableCrashReporting) {
      // TODO: Initialize Firebase Crashlytics
      // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
    
    // Initialize analytics for production
    if (AppConfig.isProduction) {
      // TODO: Initialize Firebase Analytics
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    }
    
    // Mark app as ready
    PerformanceService.trackAppReady();
    
  } catch (e) {
    if (AppConfig.enableDebugLogging) {
      print('Error initializing services: $e');
    }
    // Don't crash the app if service initialization fails
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade900),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: AppConfig.enableDebugLogging,
      home: const LoginScreen(),
    );
  }
}
