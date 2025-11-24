// lib/services/mqtt_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/app_config.dart';
import 'user_state.dart';
import 'notification_service.dart';

// 1. โมเดลข้อมูล Log
class MqttLog {
  final String deviceId;
  final double magnitude;
  final DateTime timestamp;
  final String location;
  final String type;
  final String ownerId;
  final String sensorType; // earthquake, tsunami, tilt

  MqttLog({
    required this.deviceId,
    required this.magnitude,
    required this.timestamp,
    required this.location,
    required this.type,
    required this.ownerId,
    required this.sensorType,
  });
}

class MqttManager extends ChangeNotifier {
  // *** Dependencies ***
  final UserState userState;
  
  MqttClient? client;
  
  // *** MQTT Broker Configuration (now uses AppConfig) ***
  String get _hostname => AppConfig.mqttHost;
  int get _port => kIsWeb ? AppConfig.mqttWebSocketPort : AppConfig.mqttPort;
  String get _username => AppConfig.mqttUsername;
  String get _password => AppConfig.mqttPassword;
  // Subscribe to all topics under eqnode.tarita/hub
  final String _dataTopic = 'eqnode.tarita/hub/#';
  final String _alertTopic = 'eqnode.tarita/hub/alert';
  final String _statusTopic = 'eqnode.tarita/hub/status';
  // Also subscribe to legacy topics for backward compatibility
  final String _legacyDataTopic = 'earthquake/data';
  final String _legacyAlertTopic = 'earthquake/alert'; 
  
  // *** State ***
  MqttConnectionState _connectionState = MqttConnectionState.disconnected;
  final List<MqttLog> _recentLogs = [];

  MqttConnectionState get connectionState => _connectionState;
  List<MqttLog> get recentLogs => _recentLogs;

  // *** Constructor ***
  MqttManager({required this.userState}) {
    // ไม่เชื่อมต่อ MQTT ทันทีตอนสร้าง instance
    // จะเชื่อมต่อเมื่อเรียก connect() เท่านั้น
    if (AppConfig.enableDebugLogging) {
      print('MqttManager created (not connected yet)');
    }
  }
  
  // Public method to manually connect MQTT
  Future<void> connect() async {
    if (_connectionState == MqttConnectionState.connected) {
      if (AppConfig.enableDebugLogging) {
        print('MQTT already connected');
      }
      return;
    }
    _initializeMqttClient();
  }
  
  // Public method to disconnect MQTT
  void disconnect() {
    client?.disconnect();
    _connectionState = MqttConnectionState.disconnected;
    notifyListeners();
  }

  // --- MQTT Client Setup (Real Production Connection) ---
  void _initializeMqttClient() {
    try {
      // Mobile/Desktop - use server client (ไม่รองรับ web)
      final serverClient = MqttServerClient(_hostname, 'flutter_eq_${DateTime.now().millisecondsSinceEpoch}');
      client = serverClient;
      client!.port = _port;
      
      // Common settings
      client!.logging(on: AppConfig.enableDebugLogging);
      client!.keepAlivePeriod = 30;
      client!.autoReconnect = true;
      
      // Set callbacks
      client!.onConnected = _onConnected;
      client!.onDisconnected = _onDisconnected;
      client!.onSubscribed = _onSubscribed;
      
      // Connect
      _connect();
      
    } catch (e) {
      print('MQTT Client initialization failed: $e');
      // ไม่ใช้ mock data - แสดงข้อผิดพลาดให้ผู้ใช้ทราบ
      _connectionState = MqttConnectionState.faulted;
      notifyListeners();
    }
  }
  
  void _connect() async {
    try {
      _connectionState = MqttConnectionState.connecting;
      notifyListeners();
      
      // Create connection message with authentication
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .authenticateAs(_username, _password)
          .withWillTopic('earthquake/status')
          .withWillMessage('Flutter client disconnected')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      client!.connectionMessage = connMessage;

      // Attempt connection
      await client!.connect();
      
    } catch (e) {
      _connectionState = MqttConnectionState.faulted;
      notifyListeners();
      client?.disconnect();
      print('MQTT CONNECTION FAILED: $e');
      
      // ไม่ใช้ mock data - แสดงข้อผิดพลาดให้ผู้ใช้ทราบ
    }
  }

  void _onConnected() {
    if (AppConfig.enableDebugLogging) {
      print('MQTT Connected to ${_hostname}:${_port}');
    }
    _connectionState = MqttConnectionState.connected;
    
    // ใช้ข้อมูลจริงจาก MQTT เท่านั้น
    // PMAC = Earthquake, TPO = Tilt, PEMS = Tsunami
    
    notifyListeners();
    
    // Subscribe to relevant topics
    client!.subscribe(_dataTopic, MqttQos.atLeastOnce);
    client!.subscribe(_alertTopic, MqttQos.atLeastOnce);
    client!.subscribe(_statusTopic, MqttQos.atMostOnce);
    // Subscribe to legacy topics for backward compatibility
    client!.subscribe(_legacyDataTopic, MqttQos.atLeastOnce);
    client!.subscribe(_legacyAlertTopic, MqttQos.atLeastOnce);
    // Subscribe to all EQNODE hubs
    client!.subscribe('eqnode.cnx/hub/#', MqttQos.atLeastOnce);
    // Subscribe to PMAC and TPO device topics
    client!.subscribe('pmac/#', MqttQos.atLeastOnce);
    client!.subscribe('TPO/#', MqttQos.atLeastOnce);
    
    if (AppConfig.enableDebugLogging) {
      print('✅ Subscribed to all earthquake monitoring topics');
    }
    
    // Listen for incoming messages
    client!.updates!.listen(_onMessageReceived);
  }

  void _onDisconnected() {
    if (AppConfig.enableDebugLogging) {
      print('MQTT Disconnected from ${_hostname}');
    }
    _connectionState = MqttConnectionState.disconnected;
    notifyListeners();
    
    // ไม่ใช้ mock data - ให้ผู้ใช้เห็นสถานะ disconnected จริงๆ
  }
  
  void _onSubscribed(String topic) {
    if (AppConfig.enableDebugLogging) {
      print('MQTT Subscribed to topic: $topic');
    }
  }
  
  Future<void> _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) async {
    for (final message in messages) {
      final topic = message.topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
        (message.payload as MqttPublishMessage).payload.message
      );
      
      if (AppConfig.enableDebugLogging) {
        print('MQTT Message received on $topic: $payload');
      }
      
      try {
        final data = jsonDecode(payload);
        _processRealMqttData(topic, data);
      } catch (e) {
        if (AppConfig.enableDebugLogging) {
          print('Error parsing MQTT message: $e');
        }
      }
    }
  }
  
  Future<void> _processRealMqttData(String topic, Map<String, dynamic> data) async {
    // ตรวจสอบประเภทข้อมูลจาก topic
    
    // 1. ข้อมูลแผ่นดินไหวจาก EQNODE eqdata
    if (topic.contains('/eqdata')) {
      await _processEarthquakeData(topic, data);
    }
    // 2. ข้อมูลคลื่นซึนามิจาก EQNODE tsunami
    else if (topic.contains('/tsunami')) {
      await _processTsunamiData(topic, data);
    }
    // 3. ข้อมูลความเอียงจาก EQNODE tilt
    else if (topic.contains('/tilt')) {
      await _processTiltData(topic, data);
    }
    // 4. ข้อมูลจาก earthquake topic (simulator หรือ real)
    else if (topic.contains('earthquake/data')) {
      await _processEarthquakeData(topic, data);
    }
    // 5. ข้อมูลสถานะอุปกรณ์ (ping, status) - ไม่แสดงในหน้า MQTT Real-time
    else if (topic.contains('/ping/') || topic.contains('/status')) {
      if (AppConfig.enableDebugLogging) {
        final deviceId = data['did'] ?? data['device_id'] ?? 'unknown';
        print('📱 Device status: $deviceId');
      }
    }
    // 6. ข้อมูลอื่นๆ - log เท่านั้น
    else {
      if (AppConfig.enableDebugLogging) {
        print('📨 Other data from: $topic');
      }
    }
  }
  
  Future<void> _processEarthquakeData(String topic, Map<String, dynamic> data) async {
    // 1. ดึง Device ID
    String deviceId = 'UNKNOWN';
    if (data.containsKey('did')) {
      deviceId = data['did'];
    } else if (data.containsKey('deviceId')) {
      deviceId = data['deviceId'];
    } else if (data.containsKey('device_id')) {
      deviceId = data['device_id'];
    }
    
    // 2. กำหนดประเภทเซ็นเซอร์จาก Device ID หรือ topic
    String sensorType = 'earthquake'; // default
    
    // จาก Device ID
    if (deviceId.contains('EQC-') || deviceId.contains('EQNODE')) {
      sensorType = 'earthquake'; // เซ็นเซอร์แผ่นดินไหว
    } else if (deviceId.contains('TSU-') || deviceId.contains('TSUNAMI')) {
      sensorType = 'tsunami'; // เซ็นเซอร์คลื่นซึนามิ
    } else if (deviceId.contains('TILT-') || deviceId.contains('INCLINE')) {
      sensorType = 'tilt'; // เซ็นเซอร์วัดความเอียง
    } else if (deviceId.contains('PMAC-')) {
      sensorType = 'earthquake'; // PMAC เป็นเซ็นเซอร์แผ่นดินไหว
    }
    
    // จาก topic (ถ้า Device ID ไม่ชัดเจน)
    if (topic.contains('tsunami')) {
      sensorType = 'tsunami';
    } else if (topic.contains('tilt') || topic.contains('incline')) {
      sensorType = 'tilt';
    }
    
    // จาก data type field (ถ้ามี)
    if (data.containsKey('type')) {
      final dataType = data['type'].toString().toLowerCase();
      if (dataType.contains('tsunami')) {
        sensorType = 'tsunami';
      } else if (dataType.contains('tilt') || dataType.contains('incline')) {
        sensorType = 'tilt';
      }
    }
    
    // 3. คำนวณ Magnitude
    double magnitude = 0.0;
    
    // จากข้อมูล EQNODE จริง - ใช้ PGA (Peak Ground Acceleration)
    if (data.containsKey('pga')) {
      final pga = (data['pga'] ?? 0.0).toDouble();
      // คำนวณ magnitude จาก PGA (in g)
      // สูตร: Magnitude ≈ log10(PGA * 1000) + offset
      if (pga > 0) {
        magnitude = (pga * 1000).clamp(0.1, 10.0); // แปลง PGA เป็น magnitude โดยประมาณ
      }
    }
    // จากข้อมูล simulator หรือแหล่งอื่น
    else if (data.containsKey('magnitude')) {
      magnitude = (data['magnitude'] ?? 0.0).toDouble();
    } else if (data.containsKey('mag')) {
      magnitude = (data['mag'] ?? 0.0).toDouble();
    }
    // สำหรับเซ็นเซอร์วัดความเอียง - ใช้ angle
    else if (data.containsKey('angle') && sensorType == 'tilt') {
      magnitude = (data['angle'] ?? 0.0).toDouble();
    }
    // สำหรับเซ็นเซอร์คลื่นซึนามิ - ใช้ wave height
    else if (data.containsKey('wave_height') && sensorType == 'tsunami') {
      magnitude = (data['wave_height'] ?? 0.0).toDouble();
    }
    
    // 4. ดึงตำแหน่ง
    String location = 'Unknown Location';
    
    // ถ้ามี location ชัดเจน
    if (data.containsKey('location')) {
      location = data['location'];
    } 
    // ถ้ามี lat/lon ให้แสดงพิกัด
    else if (data.containsKey('lat') && data.containsKey('lon')) {
      final lat = data['lat'];
      final lon = data['lon'];
      location = 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
    }
    
    // 5. ดึง Timestamp
    DateTime timestamp = DateTime.now();
    if (data.containsKey('ts')) {
      // Format: "2025-11-21 00:31:27.716"
      try {
        timestamp = DateTime.parse(data['ts'].toString().replaceAll(' ', 'T'));
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else if (data.containsKey('timestamp')) {
      timestamp = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();
    }
    
    // 6. กรองข้อมูลที่มี magnitude > 0
    if (magnitude > 0.0) {
      final log = MqttLog(
        deviceId: deviceId,
        magnitude: magnitude,
        timestamp: timestamp,
        location: location,
        type: 'earthquake',
        ownerId: 'system',
        sensorType: sensorType,
      );
      
      _processLog(log);
      
      // แจ้งเตือนตาม threshold ของแต่ละประเภทเซ็นเซอร์
      if (_shouldAlert(log)) {
        await _sendEarthquakeAlert(log);
      }
    }
  }
  
  // ตรวจสอบว่าควรแจ้งเตือนหรือไม่ ตาม threshold ของแต่ละเซ็นเซอร์
  bool _shouldAlert(MqttLog log) {
    switch (log.sensorType) {
      case 'earthquake':
        // แผ่นดินไหว: >= 4.0 Richter (รู้สึกได้ชัดเจน อาจมีความเสียหาย)
        return log.magnitude >= 4.0;
      
      case 'tsunami':
        // คลื่นซึนามิ: >= 0.5 เมตร (เริ่มอันตราย ตามมาตรฐาน PTWC)
        return log.magnitude >= 0.5;
      
      case 'tilt':
        // ความเอียงตึก: >= 0.5 องศา (เริ่มมีความเสี่ยง ตามมาตรฐานวิศวกรรม)
        return log.magnitude >= 0.5;
      
      default:
        return log.magnitude >= 4.0;
    }
  }

  // --- Process Tsunami Data from MQTT ---
  Future<void> _processTsunamiData(String topic, Map<String, dynamic> data) async {
    // ข้อมูลคลื่นซึนามิจาก eqnode.tarita/hub/1/tsunami
    
    String deviceId = 'TSU-UNKNOWN';
    if (data.containsKey('deviceId')) {
      deviceId = data['deviceId'];
    } else if (data.containsKey('device_id')) {
      deviceId = data['device_id'];
    } else if (data.containsKey('did')) {
      deviceId = 'TSU-${data['did']}';
    }
    
    // ดึงความสูงคลื่น (wave height)
    double waveHeight = 0.0;
    if (data.containsKey('magnitude')) {
      waveHeight = (data['magnitude'] ?? 0.0).toDouble();
    } else if (data.containsKey('wave_height')) {
      waveHeight = (data['wave_height'] ?? 0.0).toDouble();
    } else if (data.containsKey('height')) {
      waveHeight = (data['height'] ?? 0.0).toDouble();
    }
    
    // ดึงตำแหน่ง
    String location = 'Unknown Location';
    if (data.containsKey('location')) {
      location = data['location'];
    } else if (data.containsKey('latitude') && data.containsKey('longitude')) {
      final lat = data['latitude'];
      final lon = data['longitude'];
      location = 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
    }
    
    // ดึง Timestamp
    DateTime timestamp = DateTime.now();
    if (data.containsKey('timestamp')) {
      timestamp = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();
    } else if (data.containsKey('ts')) {
      try {
        timestamp = DateTime.parse(data['ts'].toString().replaceAll(' ', 'T'));
      } catch (e) {
        timestamp = DateTime.now();
      }
    }
    
    // กรองข้อมูลที่มี wave height > 0
    if (waveHeight > 0.0) {
      final log = MqttLog(
        deviceId: deviceId,
        magnitude: waveHeight,
        timestamp: timestamp,
        location: location,
        type: 'tsunami',
        ownerId: 'system',
        sensorType: 'tsunami',
      );
      
      _processLog(log);
      
      if (AppConfig.enableDebugLogging) {
        print('🌊 Tsunami: $deviceId - Wave Height: ${waveHeight.toStringAsFixed(2)}m');
      }
    }
  }
  
  // --- Process Tilt Data from MQTT ---
  Future<void> _processTiltData(String topic, Map<String, dynamic> data) async {
    // ข้อมูลความเอียงจาก eqnode.tarita/hub/1/tilt
    
    String deviceId = 'TILT-UNKNOWN';
    if (data.containsKey('deviceId')) {
      deviceId = data['deviceId'];
    } else if (data.containsKey('device_id')) {
      deviceId = data['device_id'];
    } else if (data.containsKey('did')) {
      deviceId = 'TILT-${data['did']}';
    }
    
    // ดึงมุมเอียง (tilt angle)
    double tiltAngle = 0.0;
    if (data.containsKey('magnitude')) {
      tiltAngle = (data['magnitude'] ?? 0.0).toDouble();
    } else if (data.containsKey('angle')) {
      tiltAngle = (data['angle'] ?? 0.0).toDouble();
    } else if (data.containsKey('tilt')) {
      tiltAngle = (data['tilt'] ?? 0.0).toDouble();
    }
    
    // ดึงตำแหน่ง
    String location = 'Unknown Location';
    if (data.containsKey('location')) {
      location = data['location'];
    } else if (data.containsKey('latitude') && data.containsKey('longitude')) {
      final lat = data['latitude'];
      final lon = data['longitude'];
      location = 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
    }
    
    // ดึง Timestamp
    DateTime timestamp = DateTime.now();
    if (data.containsKey('timestamp')) {
      timestamp = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();
    } else if (data.containsKey('ts')) {
      try {
        timestamp = DateTime.parse(data['ts'].toString().replaceAll(' ', 'T'));
      } catch (e) {
        timestamp = DateTime.now();
      }
    }
    
    // กรองข้อมูลที่มี tilt angle > 0
    if (tiltAngle > 0.0) {
      final log = MqttLog(
        deviceId: deviceId,
        magnitude: tiltAngle,
        timestamp: timestamp,
        location: location,
        type: 'tilt',
        ownerId: 'system',
        sensorType: 'tilt',
      );
      
      _processLog(log);
      
      if (AppConfig.enableDebugLogging) {
        print('📐 Tilt: $deviceId - Angle: ${tiltAngle.toStringAsFixed(2)}°');
      }
    }
  }
  
  // Throttling - จำกัดการอัพเดท UI
  DateTime? _lastUiUpdate;
  static const _uiUpdateInterval = Duration(milliseconds: 500); // อัพเดท UI ทุก 500ms
  
  // Logic การประมวลผล Log และ Notification
  Future<void> _processLog(MqttLog newLog) async {
      // 1. ตรวจสอบและส่ง Alert Notification
      if (newLog.type == 'earthquake' && newLog.magnitude >= 3.0) {
        await _sendEarthquakeAlert(newLog);
      }

      // 2. บันทึก Log
      _recentLogs.insert(0, newLog);
      if (_recentLogs.length > 100) { // เพิ่มจาก 20 เป็น 100
        _recentLogs.removeLast();
      }

      // 3. Throttle UI updates - อัพเดท UI ไม่เกิน 2 ครั้งต่อวินาที
      final now = DateTime.now();
      if (_lastUiUpdate == null || now.difference(_lastUiUpdate!) >= _uiUpdateInterval) {
        _lastUiUpdate = now;
        notifyListeners();
      }
      
      if (AppConfig.enableDebugLogging) {
        print(
          'MQTT Data: ${newLog.sensorType} - ID: ${newLog.deviceId} - Mag: ${newLog.magnitude.toStringAsFixed(2)}',
        );
      }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
  
  // Check if MQTT is connected
  bool get isConnected => _connectionState == MqttConnectionState.connected;

  // Alert notification system with cooldown
  DateTime? _lastAlertTime;
  
  Future<void> _sendEarthquakeAlert(MqttLog log) async {
    // Check cooldown period to prevent spam (ลดเหลือ 3 วินาที)
    final now = DateTime.now();
    final cooldown = const Duration(seconds: 3);
    
    if (_lastAlertTime != null && now.difference(_lastAlertTime!) < cooldown) {
      if (AppConfig.enableDebugLogging) {
        final remaining = cooldown.inSeconds - now.difference(_lastAlertTime!).inSeconds;
        print('⏳ Alert skipped - cooldown: ${remaining}s remaining');
      }
      return;
    }
    
    _lastAlertTime = now;
    
    // Determine alert severity (ตาม sensor type)
    String severity = _getAlertSeverity(log.magnitude, log.sensorType);
    String alertTitle = _getAlertTitle(log.sensorType, severity);
    String alertBody = _getAlertBody(log);
    
    if (AppConfig.enableDebugLogging) {
      print('🔔 Sending notification: $alertTitle');
      print('   Magnitude: ${log.magnitude}');
      print('   Location: ${log.location}');
    }
    
    try {
      // Send local notification
      await NotificationService.showEarthquakeAlert(
        alertTitle,
        alertBody,
        magnitude: log.magnitude,
      );
      
      if (AppConfig.enableDebugLogging) {
        print('✅ ALERT SENT: $alertTitle');
      }
      
    } catch (e) {
      print('❌ Error sending earthquake alert: $e');
      if (AppConfig.enableDebugLogging) {
        print('   Stack trace: ${StackTrace.current}');
      }
    }
  }
  
  String _getAlertSeverity(double magnitude, String sensorType) {
    switch (sensorType) {
      case 'earthquake':
        // แผ่นดินไหว (Richter scale) - ตามมาตรฐาน USGS
        if (magnitude >= 7.0) return 'critical';  // >= 7.0 Major earthquake (ทำลายล้างสูง)
        if (magnitude >= 6.0) return 'high';      // 6.0-6.9 Strong earthquake (เสียหายมาก)
        if (magnitude >= 5.0) return 'moderate';  // 5.0-5.9 Moderate earthquake (เสียหายบ้าง)
        return 'low';                              // 4.0-4.9 Light earthquake (รู้สึกได้)
      
      case 'tsunami':
        // คลื่นซึนามิ (เมตร) - ตามมาตรฐาน PTWC (Pacific Tsunami Warning Center)
        if (magnitude >= 3.0) return 'critical';  // >= 3.0 เมตร (อันตรายมาก ท่วมพื้นที่กว้าง)
        if (magnitude >= 1.0) return 'high';      // 1.0-2.9 เมตร (อันตรายสูง ท่วมชายฝั่ง)
        if (magnitude >= 0.5) return 'moderate';  // 0.5-0.9 เมตร (ระวัง อาจท่วมบริเวณต่ำ)
        return 'low';                              // < 0.5 เมตร (เฝ้าระวัง)
      
      case 'tilt':
        // ความเอียงตึก (องศา) - ตามมาตรฐานวิศวกรรมโครงสร้าง
        if (magnitude >= 2.0) return 'critical';  // >= 2.0 องศา (อันตรายมาก อาจพังได้)
        if (magnitude >= 1.0) return 'high';      // 1.0-1.9 องศา (อันตราย ต้องอพยพ)
        if (magnitude >= 0.5) return 'moderate';  // 0.5-0.9 องศา (เสี่ยง ต้องตรวจสอบ)
        return 'low';                              // < 0.5 องศา (เฝ้าระวัง)
      
      default:
        if (magnitude >= 7.0) return 'critical';
        if (magnitude >= 6.0) return 'high';
        if (magnitude >= 5.0) return 'moderate';
        return 'low';
    }
  }
  
  String _getAlertTitle(String sensorType, String severity) {
    String eventType = 'Earthquake';
    String icon = '🌍';
    
    if (sensorType == 'tsunami') {
      eventType = 'Tsunami';
      icon = '🌊';
    } else if (sensorType == 'tilt') {
      eventType = 'Building Tilt';
      icon = '📐';
    }
    
    switch (severity) {
      case 'critical':
        return '🚨 CRITICAL $eventType ALERT';
      case 'high':
        return '⚠️ HIGH $eventType ALERT';
      case 'moderate':
        return '$icon $eventType Alert';
      default:
        return '🔔 $eventType Detected';
    }
  }
  
  String _getAlertBody(MqttLog log) {
    String unit = 'Richter';
    String label = 'Magnitude';
    
    if (log.sensorType == 'tsunami') {
      unit = 'meters';
      label = 'Wave height';
    } else if (log.sensorType == 'tilt') {
      unit = 'degrees';
      label = 'Tilt angle';
    }
    
    return '$label ${log.magnitude.toStringAsFixed(1)} $unit detected at ${log.location}. '
           'Device: ${log.deviceId}. Time: ${_formatTime(log.timestamp)}.';
  }
  
  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
  
  // Get alert statistics
  Map<String, dynamic> getAlertStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastWeek = now.subtract(const Duration(days: 7));
    
    final recent24h = _recentLogs.where((log) => 
        log.timestamp.isAfter(last24Hours) && log.magnitude >= 3.0).length;
    final recentWeek = _recentLogs.where((log) => 
        log.timestamp.isAfter(lastWeek) && log.magnitude >= 3.0).length;
    
    return {
      'alertsLast24Hours': recent24h,
      'alertsLastWeek': recentWeek,
      'totalLogs': _recentLogs.length,
      'lastAlertTime': _lastAlertTime?.toIso8601String(),
      'connectionStatus': _connectionState.name,
    };
  }
  
  // Manual alert test
  Future<void> sendTestAlert() async {
    final testLog = MqttLog(
      deviceId: 'TEST-001',
      magnitude: 4.5,
      timestamp: DateTime.now(),
      location: 'Test Location',
      type: 'earthquake',
      ownerId: 'test@example.com',
      sensorType: 'earthquake',
    );
    
    await _sendEarthquakeAlert(testLog);
  }
}

