// lib/services/user_state.dart

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'api_service.dart';

// โมเดลข้อมูลผู้ใช้
class UserModel {
  final String email;
  final String name;
  final String phone;

  UserModel({required this.email, required this.name, required this.phone});
}

class UserState extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  
  // List สำหรับเก็บอุปกรณ์ที่ลงทะเบียนโดยผู้ใช้คนนี้
  final List<Map<String, dynamic>> _userDevices = [];
  
  // API Service (ใช้ static methods)


  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getter สำหรับ userId (ใช้ email เป็น ID ในการกรอง Log)
  String? get userId => _currentUser?.email;
  // Getter สำหรับรายการอุปกรณ์
  List<Map<String, dynamic>> get userDevices => _userDevices;

  // Check if user is already logged in (auto-login)
  Future<bool> checkLoginStatus() async {
    try {
      _setLoading(true);
      
      // Check if token exists
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        if (AppConfig.enableDebugLogging) {
          print('No token found - user not logged in');
        }
        return false;
      }
      
      // Verify token by getting user profile
      final result = await ApiService.getUserProfile();
      
      if (result['success'] && result['user'] != null) {
        final user = result['user'];
        _currentUser = UserModel(
          email: user['email'] ?? '',
          name: user['name'] ?? '',
          phone: user['phone'] ?? '',
        );
        _isLoggedIn = true;
        _error = null;
        
        // Load user devices
        await _loadUserDevices();
        
        if (AppConfig.enableDebugLogging) {
          print('Auto-login successful: ${_currentUser?.email}');
        }
        
        return true;
      } else {
        // Token invalid or expired
        await ApiService.clearToken();
        if (AppConfig.enableDebugLogging) {
          print('Token invalid - clearing');
        }
        return false;
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error checking login status: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setUser(String email, String name, String phone) {
    _currentUser = UserModel(email: email, name: name, phone: phone);
    _isLoggedIn = true;
    _error = null;
    _userDevices.clear(); // เคลียร์อุปกรณ์เก่าเมื่อ Login ผู้ใช้ใหม่
    
    // Load user devices from API
    _loadUserDevices();
    
    notifyListeners();
  }

  // Load user devices from API
  Future<void> _loadUserDevices() async {
    if (!_isLoggedIn) return;
    
    try {
      _setLoading(true);
      final result = await ApiService.getUserDevices();
      
      if (result['success']) {
        _userDevices.clear();
        final devices = result['devices'] as List<dynamic>? ?? [];
        for (final device in devices) {
          _userDevices.add(Map<String, dynamic>.from(device));
        }
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to load devices';
      }
    } catch (e) {
      _error = 'Error loading devices: $e';
      if (AppConfig.enableDebugLogging) {
        print('Error loading user devices: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user devices
  Future<void> refreshDevices() async {
    await _loadUserDevices();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      // Call API logout
      await ApiService.logout();
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Error during logout: $e');
      }
    } finally {
      // Clear local state regardless of API result
      _currentUser = null;
      _isLoggedIn = false;
      _userDevices.clear();
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ฟังก์ชันเพิ่ม/แก้ไข/ลบอุปกรณ์ (เรียกจาก SystemSettingsScreen)
  Future<bool> addOrUpdateDevice(Map<String, dynamic> newDeviceData) async {
    try {
      _setLoading(true);
      _error = null;
      
      // ผูก Owner ID (email) เข้ากับข้อมูลอุปกรณ์
      newDeviceData['ownerId'] = _currentUser?.email ?? 'anonymous';
      
      final existingIndex = _userDevices.indexWhere((d) => d['id'] == newDeviceData['id']);
      
      Map<String, dynamic> result;
      
      if (existingIndex != -1) {
        // Update existing device
        result = await ApiService.updateDevice(
          deviceId: newDeviceData['id'],
          name: newDeviceData['name'],
          location: newDeviceData['location'],
          latitude: newDeviceData['lat'],
          longitude: newDeviceData['lon'],
        );
        
        if (result['success']) {
          // Update local data
          _userDevices[existingIndex]['name'] = newDeviceData['name'];
          _userDevices[existingIndex]['location'] = newDeviceData['location'];
          _userDevices[existingIndex]['address'] = newDeviceData['address'];
          _userDevices[existingIndex]['lat'] = newDeviceData['lat'];
          _userDevices[existingIndex]['lon'] = newDeviceData['lon'];
        }
      } else {
        // Register new device
        result = await ApiService.registerDevice(
          deviceId: newDeviceData['id'],
          deviceName: newDeviceData['name'],
          location: newDeviceData['location'],
          latitude: newDeviceData['lat'],
          longitude: newDeviceData['lon'],
        );
        
        if (result['success']) {
          // Add to local data
          _userDevices.add(newDeviceData);
        }
      }
      
      if (!result['success']) {
        _error = result['message'] ?? 'Device operation failed';
        return false;
      }
      
      return true;
      
    } catch (e) {
      _error = 'Error managing device: $e';
      if (AppConfig.enableDebugLogging) {
        print('Error in addOrUpdateDevice: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> removeDevice(String deviceId) async {
    try {
      _setLoading(true);
      _error = null;
      
      final result = await ApiService.deleteDevice(deviceId);
      
      if (result['success']) {
        _userDevices.removeWhere((d) => d['id'] == deviceId);
        return true;
      } else {
        _error = result['message'] ?? 'Failed to remove device';
        return false;
      }
      
    } catch (e) {
      _error = 'Error removing device: $e';
      if (AppConfig.enableDebugLogging) {
        print('Error in removeDevice: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get device details
  Future<Map<String, dynamic>?> getDeviceDetails(String deviceId) async {
    try {
      final result = await ApiService.getDeviceDetails(deviceId);
      
      if (result['success']) {
        return result['device'];
      } else {
        _error = result['message'] ?? 'Failed to get device details';
        return null;
      }
    } catch (e) {
      _error = 'Error getting device details: $e';
      if (AppConfig.enableDebugLogging) {
        print('Error in getDeviceDetails: $e');
      }
      return null;
    }
  }

  // Get device status
  Future<Map<String, dynamic>?> getDeviceStatus(String deviceId) async {
    try {
      final result = await ApiService.getDeviceStatus(deviceId);
      
      if (result['success']) {
        return result['status'];
      } else {
        _error = result['message'] ?? 'Failed to get device status';
        return null;
      }
    } catch (e) {
      _error = 'Error getting device status: $e';
      if (AppConfig.enableDebugLogging) {
        print('Error in getDeviceStatus: $e');
      }
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      final result = await ApiService.updateUserProfile(
        name: name,
        phone: phone,
      );
      
      if (result['success']) {
        // Update local user data
        _currentUser = UserModel(
          email: _currentUser!.email,
          name: name,
          phone: phone,
        );
        return true;
      } else {
        _error = result['message'] ?? 'Failed to update profile';
        return false;
      }
      
    } catch (e) {
      _error = 'Error updating profile: $e';
      if (AppConfig.enableDebugLogging) {
        print('Error in updateProfile: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}