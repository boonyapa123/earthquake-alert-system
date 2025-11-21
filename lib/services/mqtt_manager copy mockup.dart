// lib/services/mqtt_manager.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart'; // ต้อง import

// 1. โมเดลข้อมูล Log ที่จำลองการรับจาก MQTT
class MqttLog {
  final String deviceId;
  final double magnitude;
  final DateTime timestamp;
  final String location;
  final String type; // earthquake, tsunami, tilt

  MqttLog({
    required this.deviceId,
    required this.magnitude,
    required this.timestamp,
    required this.location,
    required this.type,
  });
}

class MqttManager extends ChangeNotifier {
  // สถานะการเชื่อมต่อ (Mockup)
  MqttConnectionState _connectionState = MqttConnectionState.connected;
  MqttConnectionState get connectionState => _connectionState;

  // ฐานข้อมูล Log จำลอง
  final List<MqttLog> _recentLogs = [];
  List<MqttLog> get recentLogs => _recentLogs;

  Timer? _mockTimer;
  final Random _random = Random();

  MqttManager() {
    // เริ่มจำลองการส่งข้อมูลเมื่อสร้าง MqttManager
    _startMockDataGenerator();
  }

  // จำลองการสร้างข้อมูล MQTT ทุกๆ 5 วินาที
  void _startMockDataGenerator() {
    // 1. สร้าง Log เริ่มต้น 2-3 อัน
    _recentLogs.add(_generateMockLog('earthquake', 2.4, 'เชียงใหม่'));
    _recentLogs.add(_generateMockLog('tsunami', 0.5, 'ภูเก็ต'));

    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final types = ['earthquake', 'tsunami', 'tilt'];
      final type = types[_random.nextInt(types.length)];
      final magnitude = _random.nextDouble() * 4.0 + 1.0; // 1.0 to 5.0
      final location = [
        'เชียงใหม่',
        'ภูเก็ต',
        'กรุงเทพ',
        'ระนอง',
        'ตาก',
      ][_random.nextInt(5)];

      final newLog = _generateMockLog(type, magnitude, location);
      _recentLogs.insert(0, newLog); // เพิ่ม Log ใหม่ที่ด้านบน

      // จำกัดจำนวน Log ไม่ให้มากเกินไป
      if (_recentLogs.length > 20) {
        _recentLogs.removeLast();
      }

      notifyListeners();
      print(
        'MQTT Mock Data Generated: ${newLog.type} - ${newLog.magnitude.toStringAsFixed(1)}',
      );
    });
  }

  MqttLog _generateMockLog(String type, double magnitude, String location) {
    return MqttLog(
      deviceId: type == 'earthquake'
          ? 'EQC-${_random.nextInt(999)}'
          : 'TSN-${_random.nextInt(999)}',
      magnitude: magnitude,
      timestamp: DateTime.now(),
      location: location,
      type: type,
    );
  }

  // ต้องล้าง Timer เมื่อ MqttManager ถูก dispose
  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }
}
