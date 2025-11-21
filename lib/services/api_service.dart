// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  // Backend API Configuration (now uses AppConfig)
  static String get _baseUrl => AppConfig.baseUrl;
  static bool get _mockMode => AppConfig.enableMockData;
  
  static const _storage = FlutterSecureStorage();
  
  // Mock database for development (will be replaced by real API calls)
  static final Map<String, Map<String, String>> _registeredUsers = {
    'user@eqnode.com': {
      'name': 'ผู้ใช้ทดสอบ',
      'password': 'password123',
      'phone': '090-000-0000',
      'address': 'Test Address',
    },
    'admin@earthquake.com': {
      'name': 'ผู้ดูแลระบบ',
      'password': 'admin123',
      'phone': '080-000-0000',
      'address': 'Admin Office',
    },
  };

  // Authentication Token Management
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // HTTP Headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
      'X-App-Version': AppConfig.appVersion,
      'X-Build-Number': AppConfig.buildNumber,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // HTTP Client with timeout configuration
  static http.Client _getHttpClient() {
    return http.Client();
  }

  // Make HTTP request with proper error handling and timeout
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final client = _getHttpClient();
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await client.get(uri, headers: headers)
              .timeout(AppConfig.apiTimeout);
          break;
        case 'POST':
          response = await client.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConfig.apiTimeout);
          break;
        case 'PUT':
          response = await client.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConfig.apiTimeout);
          break;
        case 'DELETE':
          response = await client.delete(uri, headers: headers)
              .timeout(AppConfig.apiTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (AppConfig.enableDebugLogging) {
        print('API Request: $method $uri');
        print('Response: ${response.statusCode} ${response.body}');
      }

      return response;
    } finally {
      client.close();
    }
  }

  // User Registration
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    if (_mockMode) {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_registeredUsers.containsKey(email)) {
        return {'success': false, 'message': 'อีเมลนี้ถูกใช้งานแล้ว'};
      }
      
      _registeredUsers[email] = {
        'name': name,
        'password': password,
        'phone': phone,
        'address': address,
      };
      
      return {'success': true, 'message': 'สมัครสมาชิกสำเร็จ'};
    }
    
    // Real API implementation
    try {
      final response = await _makeRequest(
        'POST',
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // User Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (_mockMode) {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!_registeredUsers.containsKey(email)) {
        return {'success': false, 'message': 'ไม่พบผู้ใช้ด้วยอีเมลนี้'};
      }

      final userData = _registeredUsers[email]!;

      if (userData['password'] == password) {
        final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        await saveToken(token);
        
        return {
          'success': true,
          'token': token,
          'name': userData['name'],
          'phone': userData['phone'],
        };
      } else {
        return {'success': false, 'message': 'รหัสผ่านไม่ถูกต้อง'};
      }
    }
    
    // Real API implementation
    try {
      final response = await _makeRequest(
        'POST',
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] && data['token'] != null) {
          await saveToken(data['token']);
        }
        
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // Device Registration
  static Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String deviceName,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    if (_mockMode) {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'success': true,
        'message': 'ลงทะเบียนอุปกรณ์สำเร็จ',
        'deviceId': deviceId,
        'device': {
          'id': DateTime.now().millisecondsSinceEpoch,
          'deviceId': deviceId,
          'name': deviceName,
          'type': 'earthquake',
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
        }
      };
    }
    
    // Real API implementation
    try {
      final response = await _makeRequest(
        'POST',
        '/devices/register',
        body: {
          'deviceId': deviceId,
          'name': deviceName,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Device registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // Get User Devices - Fetch all devices registered by the current user
  static Future<Map<String, dynamic>> getUserDevices() async {
    if (_mockMode) {
      // Mock implementation - return empty list, will be populated by UserState
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'devices': [], // UserState will manage mock devices
      };
    }
    
    // Real API implementation
    try {
      final response = await _makeRequest('GET', '/devices/user');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'devices': data['devices'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch devices',
          'devices': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
        'devices': [],
      };
    }
  }
  
  // Get Devices by Type - Filter user's devices by type
  static Future<Map<String, dynamic>> getUserDevicesByType(String type) async {
    final result = await getUserDevices();
    
    if (result['success'] == true) {
      final devices = result['devices'] as List;
      final filteredDevices = devices.where((device) => 
        device['type'] == type
      ).toList();
      
      return {
        'success': true,
        'devices': filteredDevices,
      };
    }
    
    return result;
  }

  // Get Earthquake News/Reports
  static Future<Map<String, dynamic>> getEarthquakeNews() async {
    if (_mockMode == 'true') {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 1200));
      return {
        'success': true,
        'news': [
          {
            'title': 'แผ่นดินไหวขนาด 4.2 ที่จังหวัดเชียงใหม่',
            'description': 'เกิดแผ่นดินไหวเมื่อเวลา 14:30 น. วันนี้',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'source': 'กรมอุตุนิยมวิทยา',
          },
          {
            'title': 'คลื่นสึนามิเตือนภัยในมหาสมุทรแปซิฟิก',
            'description': 'ประกาศเตือนภัยระดับ 2 สำหรับชายฝั่งตะวันออก',
            'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
            'source': 'ศูนย์เตือนภัยสึนามิ',
          },
        ],
      };
    }
    
    // Real API implementation - could integrate with TMD API or news APIs
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/news/earthquake'),
        headers: await _getHeaders(),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // Utility methods
  static Map<String, String>? getRegisteredUser(String email) {
    return _registeredUsers[email];
  }

  bool isEmailRegistered(String email) {
    return _registeredUsers.containsKey(email);
  }

  // User Profile Management
  static Future<Map<String, dynamic>> getUserProfile() async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'user': {
          'id': 'user_123',
          'email': 'user@eqnode.com',
          'name': 'ผู้ใช้ทดสอบ',
          'phone': '090-000-0000',
          'deviceLimit': 10,
          'createdAt': DateTime.now().toIso8601String(),
        }
      };
    }

    try {
      final response = await _makeRequest('GET', '/auth/profile');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'success': true,
        'message': 'อัปเดตโปรไฟล์สำเร็จ',
      };
    }

    try {
      final response = await _makeRequest(
        'PUT',
        '/auth/profile',
        body: {
          'name': name,
          'phone': phone,
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return {
        'success': true,
        'message': 'เปลี่ยนรหัสผ่านสำเร็จ',
      };
    }

    try {
      final response = await _makeRequest(
        'PUT',
        '/auth/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newToken = 'refreshed_token_${DateTime.now().millisecondsSinceEpoch}';
      await saveToken(newToken);
      return {
        'success': true,
        'token': newToken,
      };
    }

    try {
      final response = await _makeRequest('POST', '/auth/refresh');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } else {
        return {
          'success': false,
          'message': 'Token refresh failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      if (!_mockMode) {
        await _makeRequest('POST', '/auth/logout');
      }
      
      // Clear local token regardless of API response
      await clearToken();
      
      return {
        'success': true,
        'message': 'ออกจากระบบสำเร็จ',
      };
    } catch (e) {
      // Still clear token even if API call fails
      await clearToken();
      return {
        'success': true,
        'message': 'ออกจากระบบสำเร็จ',
      };
    }
  }

  // Device Management APIs
  static Future<Map<String, dynamic>> getDeviceDetails(String deviceId) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'success': true,
        'device': {
          'id': deviceId,
          'name': 'Mock Device $deviceId',
          'type': 'earthquake',
          'status': 'active',
          'location': 'Bangkok, Thailand',
          'latitude': 13.7563,
          'longitude': 100.5018,
          'lastSeen': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        }
      };
    }

    try {
      final response = await _makeRequest('GET', '/devices/$deviceId');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Device not found',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateDevice({
    required String deviceId,
    required String name,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'success': true,
        'message': 'อัปเดตอุปกรณ์สำเร็จ',
      };
    }

    try {
      final response = await _makeRequest(
        'PUT',
        '/devices/$deviceId',
        body: {
          'name': name,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update device',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteDevice(String deviceId) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'success': true,
        'message': 'ลบอุปกรณ์สำเร็จ',
      };
    }

    try {
      final response = await _makeRequest('DELETE', '/devices/$deviceId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'ลบอุปกรณ์สำเร็จ',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to delete device',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDeviceStatus(String deviceId) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'success': true,
        'status': {
          'deviceId': deviceId,
          'online': true,
          'lastSeen': DateTime.now().toIso8601String(),
          'batteryLevel': 85,
          'signalStrength': -45,
          'firmware': '1.2.3',
        }
      };
    }

    try {
      final response = await _makeRequest('GET', '/devices/$deviceId/status');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get device status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> transferDeviceOwnership({
    required String deviceId,
    required String newOwnerEmail,
  }) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return {
        'success': true,
        'message': 'โอนความเป็นเจ้าของอุปกรณ์สำเร็จ',
      };
    }

    try {
      final response = await _makeRequest(
        'PUT',
        '/devices/$deviceId/transfer',
        body: {
          'newOwnerEmail': newOwnerEmail,
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to transfer device',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // MQTT Data and Event Management APIs
  static Future<Map<String, dynamic>> getEarthquakeEvents({
    int page = 1,
    int limit = 20,
    String? deviceId,
    DateTime? startDate,
    DateTime? endDate,
    double? minMagnitude,
  }) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'success': true,
        'events': List.generate(limit, (index) => {
          'id': 'event_${page}_$index',
          'deviceId': deviceId ?? 'EQC-${index.toString().padLeft(3, '0')}',
          'magnitude': 2.0 + (index % 5) * 0.5,
          'location': 'Bangkok, Thailand',
          'latitude': 13.7563 + (index * 0.001),
          'longitude': 100.5018 + (index * 0.001),
          'type': 'earthquake',
          'timestamp': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
          'processed': true,
        }),
        'pagination': {
          'page': page,
          'limit': limit,
          'total': 100,
          'totalPages': 5,
        }
      };
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (deviceId != null) 'deviceId': deviceId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (minMagnitude != null) 'minMagnitude': minMagnitude.toString(),
      };

      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = '/events/earthquake${queryString.isNotEmpty ? '?$queryString' : ''}';
      final response = await _makeRequest('GET', endpoint);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get events',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> getEventDetails(String eventId) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'event': {
          'id': eventId,
          'deviceId': 'EQC-001',
          'magnitude': 4.2,
          'location': 'Bangkok, Thailand',
          'latitude': 13.7563,
          'longitude': 100.5018,
          'type': 'earthquake',
          'severity': 'moderate',
          'timestamp': DateTime.now().toIso8601String(),
          'processed': true,
          'notificationSent': true,
          'rawData': {
            'accelerationX': 0.15,
            'accelerationY': 0.12,
            'accelerationZ': 0.98,
            'frequency': 8.5,
          }
        }
      };
    }

    try {
      final response = await _makeRequest('GET', '/events/$eventId');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Event not found',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> reportFalsePositive(String eventId) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'success': true,
        'message': 'รายงาน False Positive สำเร็จ',
      };
    }

    try {
      final response = await _makeRequest(
        'PUT',
        '/events/$eventId/report-false-positive',
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to report false positive',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDeviceStatistics({
    required String deviceId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 700));
      return {
        'success': true,
        'statistics': {
          'deviceId': deviceId,
          'totalEvents': 45,
          'averageMagnitude': 2.8,
          'maxMagnitude': 4.5,
          'eventsThisWeek': 12,
          'eventsThisMonth': 45,
          'uptime': 98.5,
          'lastEvent': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        }
      };
    }

    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = '/devices/$deviceId/statistics${queryString.isNotEmpty ? '?$queryString' : ''}';
      final response = await _makeRequest('GET', endpoint);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get statistics',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // ==================== Alerts and Events API ====================

  /// Get alerts for current user's devices
  static Future<Map<String, dynamic>> getAlerts({
    int page = 1,
    int limit = 20,
    double? minMagnitude,
  }) async {
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'success': true,
        'alerts': [], // Will be populated from MQTT in real-time
        'pagination': {
          'page': page,
          'limit': limit,
          'total': 0,
        }
      };
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (minMagnitude != null) 'minMagnitude': minMagnitude.toString(),
      };

      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = '/events/alerts${queryString.isNotEmpty ? '?$queryString' : ''}';
      final response = await _makeRequest('GET', endpoint);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'alerts': data['alerts'] ?? data['events'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch alerts',
          'alerts': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
        'alerts': [],
      };
    }
  }
}
