// lib/services/performance_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class PerformanceService {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final List<PerformanceMetric> _metrics = [];
  static Timer? _reportingTimer;
  
  // Initialize performance monitoring
  static void initialize() {
    if (AppConfig.isProduction || AppConfig.isStaging) {
      // Start periodic reporting
      _reportingTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _reportMetrics(),
      );
    }
  }
  
  // Start timing an operation
  static void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }
  
  // End timing an operation
  static void endOperation(String operationName, {
    bool success = true,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime);
    
    final metric = PerformanceMetric(
      operationName: operationName,
      duration: duration,
      success: success,
      error: error,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
    
    _metrics.add(metric);
    
    // Log slow operations
    if (duration.inMilliseconds > 5000) { // 5 seconds
      _logSlowOperation(metric);
    }
    
    // Keep only recent metrics
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, 500);
    }
    
    if (AppConfig.enableDebugLogging) {
      print('PERF: $operationName took ${duration.inMilliseconds}ms');
    }
  }
  
  // Time a future operation
  static Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    startOperation(operationName);
    
    try {
      final result = await operation();
      endOperation(operationName, success: true, metadata: metadata);
      return result;
    } catch (e) {
      endOperation(
        operationName,
        success: false,
        error: e.toString(),
        metadata: metadata,
      );
      rethrow;
    }
  }
  
  // Log memory usage
  static void logMemoryUsage(String context) {
    if (AppConfig.enableDebugLogging) {
      // Note: Actual memory monitoring would require platform-specific code
      print('MEMORY: Context - $context');
    }
  }
  
  // Log network request performance
  static void logNetworkRequest({
    required String url,
    required String method,
    required int statusCode,
    required Duration duration,
    int? responseSize,
  }) {
    final metric = NetworkMetric(
      url: url,
      method: method,
      statusCode: statusCode,
      duration: duration,
      responseSize: responseSize,
      timestamp: DateTime.now(),
    );
    
    if (AppConfig.enableDebugLogging) {
      print('NETWORK: $method $url - ${statusCode} (${duration.inMilliseconds}ms)');
    }
    
    // Log slow network requests
    if (duration.inMilliseconds > 10000) { // 10 seconds
      _logSlowNetworkRequest(metric);
    }
  }
  
  // Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    if (_metrics.isEmpty) {
      return {
        'totalOperations': 0,
        'averageDuration': 0,
        'successRate': 100.0,
        'slowOperations': 0,
      };
    }
    
    final totalOperations = _metrics.length;
    final successfulOperations = _metrics.where((m) => m.success).length;
    final totalDuration = _metrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    final slowOperations = _metrics
        .where((m) => m.duration.inMilliseconds > 5000)
        .length;
    
    return {
      'totalOperations': totalOperations,
      'averageDuration': totalDuration / totalOperations,
      'successRate': (successfulOperations / totalOperations) * 100,
      'slowOperations': slowOperations,
      'operationBreakdown': _getOperationBreakdown(),
    };
  }
  
  static Map<String, dynamic> _getOperationBreakdown() {
    final breakdown = <String, Map<String, dynamic>>{};
    
    for (final metric in _metrics) {
      final name = metric.operationName;
      if (!breakdown.containsKey(name)) {
        breakdown[name] = {
          'count': 0,
          'totalDuration': 0,
          'successCount': 0,
        };
      }
      
      breakdown[name]!['count'] = breakdown[name]!['count'] + 1;
      breakdown[name]!['totalDuration'] = 
          breakdown[name]!['totalDuration'] + metric.duration.inMilliseconds;
      
      if (metric.success) {
        breakdown[name]!['successCount'] = breakdown[name]!['successCount'] + 1;
      }
    }
    
    // Calculate averages and success rates
    for (final entry in breakdown.entries) {
      final data = entry.value;
      data['averageDuration'] = data['totalDuration'] / data['count'];
      data['successRate'] = (data['successCount'] / data['count']) * 100;
    }
    
    return breakdown;
  }
  
  static void _logSlowOperation(PerformanceMetric metric) {
    if (AppConfig.enableDebugLogging) {
      print('SLOW OPERATION: ${metric.operationName} took ${metric.duration.inMilliseconds}ms');
    }
    
    // TODO: Send to monitoring service in production
    if (AppConfig.isProduction) {
      _sendToMonitoringService('slow_operation', {
        'operation': metric.operationName,
        'duration': metric.duration.inMilliseconds,
        'error': metric.error,
        'metadata': metric.metadata,
      });
    }
  }
  
  static void _logSlowNetworkRequest(NetworkMetric metric) {
    if (AppConfig.enableDebugLogging) {
      print('SLOW NETWORK: ${metric.method} ${metric.url} took ${metric.duration.inMilliseconds}ms');
    }
    
    // TODO: Send to monitoring service in production
    if (AppConfig.isProduction) {
      _sendToMonitoringService('slow_network', {
        'url': metric.url,
        'method': metric.method,
        'duration': metric.duration.inMilliseconds,
        'statusCode': metric.statusCode,
      });
    }
  }
  
  static void _reportMetrics() {
    if (_metrics.isEmpty) return;
    
    final stats = getPerformanceStats();
    
    if (AppConfig.enableDebugLogging) {
      print('PERFORMANCE REPORT: ${jsonEncode(stats)}');
    }
    
    // TODO: Send to analytics service in production
    if (AppConfig.isProduction) {
      _sendToMonitoringService('performance_report', stats);
    }
  }
  
  static void _sendToMonitoringService(String eventType, Map<String, dynamic> data) {
    // TODO: Implement actual monitoring service integration
    // This could be Firebase Analytics, Datadog, New Relic, etc.
    if (AppConfig.enableDebugLogging) {
      print('MONITORING: $eventType - ${jsonEncode(data)}');
    }
  }
  
  // Dispose resources
  static void dispose() {
    _reportingTimer?.cancel();
    _operationStartTimes.clear();
    _metrics.clear();
  }
  
  // App lifecycle performance tracking
  static void trackAppStart() {
    startOperation('app_startup');
  }
  
  static void trackAppReady() {
    endOperation('app_startup', success: true);
  }
  
  // Screen navigation performance
  static void trackScreenNavigation(String screenName) {
    startOperation('navigate_to_$screenName');
  }
  
  static void trackScreenLoaded(String screenName) {
    endOperation('navigate_to_$screenName', success: true);
  }
  
  // API call performance wrapper
  static Future<T> trackApiCall<T>(
    String apiName,
    Future<T> Function() apiCall,
  ) async {
    return timeOperation('api_$apiName', apiCall);
  }
  
  // Database operation performance
  static Future<T> trackDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    return timeOperation('db_$operationName', operation);
  }
}

// Performance metric data classes
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  
  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.success,
    this.error,
    this.metadata,
    required this.timestamp,
  });
}

class NetworkMetric {
  final String url;
  final String method;
  final int statusCode;
  final Duration duration;
  final int? responseSize;
  final DateTime timestamp;
  
  NetworkMetric({
    required this.url,
    required this.method,
    required this.statusCode,
    required this.duration,
    this.responseSize,
    required this.timestamp,
  });
}