// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../services/mqtt_manager.dart';
import '../services/user_state.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'device_detail_screen.dart';
import 'history_detail_screen.dart';
import 'sensor_detail_screen.dart';

// Device type definitions with icons
final List<Map<String, dynamic>> _deviceTypes = [
  {
    'name': 'อุปกรณ์ตรวจจับแผ่นดินไหว',
    'icon': Icons.show_chart,
    'tag': 'earthquake',
  },
  {
    'name': 'อุปกรณ์ตรวจจับสึนามิ',
    'icon': Icons.device_thermostat,
    'tag': 'tsunami',
  },
  {
    'name': 'อุปกรณ์ตรวจจับความเอียง',
    'icon': Icons.swap_vert,
    'tag': 'tilt'
  },
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load devices on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDevices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Refresh devices from API
  Future<void> _refreshDevices() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.refreshDevices();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ไม่สามารถโหลดข้อมูลอุปกรณ์ได้: $e';
        });
      }
    }
  }

  // Helper function สำหรับชื่อเดือน
  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'มกราคม'; case 2: return 'กุมภาพันธ์'; case 3: return 'มีนาคม'; case 4: return 'เมษายน'; 
      case 5: return 'พฤษภาคม'; case 6: return 'มิถุนายน'; case 7: return 'กรกฎาคม'; case 8: return 'สิงหาคม'; 
      case 9: return 'กันยายน'; case 10: return 'ตุลาคม'; case 11: return 'พฤศจิกายน'; case 12: return 'ธันวาคม'; 
      default: return '';
    }
  }
  
  // Get device types that user actually has
  List<Map<String, dynamic>> _getAvailableDeviceTypes(List<Map<String, dynamic>> userDevices) {
    if (userDevices.isEmpty) {
      return _deviceTypes; // Show all types if no devices yet
    }
    
    // Get unique device types from user's devices
    final userDeviceTypes = userDevices.map((d) => d['tag'] as String?).where((t) => t != null).toSet();
    
    // Filter device types to show only those the user has
    return _deviceTypes.where((type) => userDeviceTypes.contains(type['tag'])).toList();
  }
  
  // Count devices by type
  int _countDevicesByType(List<Map<String, dynamic>> userDevices, String type) {
    return userDevices.where((d) => d['tag'] == type).length;
  }
  
  // Build MQTT devices list with grouping
  Widget _buildMqttDevicesList(MqttManager mqttManager) {
    final logs = mqttManager.recentLogs;
    
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'ไม่มีข้อมูล MQTT',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'รอข้อมูลจาก MQTT Broker...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // จัดกลุ่มข้อมูลตามประเภทเซ็นเซอร์
    final earthquakeLogs = logs.where((log) => log.sensorType == 'earthquake').toList();
    final tsunamiLogs = logs.where((log) => log.sensorType == 'tsunami').toList();
    final tiltLogs = logs.where((log) => log.sensorType == 'tilt').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. แผ่นดินไหว (Earthquake)
        if (earthquakeLogs.isNotEmpty) ...[
          _buildSensorTypeHeader(
            '🌍 เซ็นเซอร์แผ่นดินไหว',
            earthquakeLogs.length,
            Colors.red.shade700,
            Icons.show_chart,
            'earthquake',
            earthquakeLogs,
          ),
          const SizedBox(height: 8),
          ..._buildGroupedLogs(earthquakeLogs, 'earthquake'),
          const SizedBox(height: 16),
        ],
        
        // 2. คลื่นซึนามิ (Tsunami)
        if (tsunamiLogs.isNotEmpty) ...[
          _buildSensorTypeHeader(
            '🌊 เซ็นเซอร์คลื่นซึนามิ',
            tsunamiLogs.length,
            Colors.blue.shade700,
            Icons.waves,
            'tsunami',
            tsunamiLogs,
          ),
          const SizedBox(height: 8),
          ..._buildGroupedLogs(tsunamiLogs, 'tsunami'),
          const SizedBox(height: 16),
        ],
        
        // 3. วัดความเอียงตึก (Tilt)
        if (tiltLogs.isNotEmpty) ...[
          _buildSensorTypeHeader(
            '📐 เซ็นเซอร์วัดความเอียง',
            tiltLogs.length,
            Colors.purple.shade700,
            Icons.architecture,
            'tilt',
            tiltLogs,
          ),
          const SizedBox(height: 8),
          ..._buildGroupedLogs(tiltLogs, 'tilt'),
        ],
      ],
    );
  }
  
  // Build grouped logs by severity
  List<Widget> _buildGroupedLogs(List<dynamic> logs, String sensorType) {
    // แยกตามความรุนแรง
    final criticalLogs = logs.where((log) => log.magnitude >= 6.0).toList();
    final highLogs = logs.where((log) => log.magnitude >= 3.0 && log.magnitude < 6.0).toList();
    final normalLogs = logs.where((log) => log.magnitude < 3.0).toList();
    
    List<Widget> widgets = [];
    
    // Critical
    if (criticalLogs.isNotEmpty) {
      widgets.add(_buildSeveritySubHeader('🚨 รุนแรงมาก', criticalLogs.length, Colors.red.shade700));
      widgets.add(const SizedBox(height: 6));
      widgets.addAll(criticalLogs.map((log) => _buildMqttLogCard(log, 'critical')));
      widgets.add(const SizedBox(height: 8));
    }
    
    // High
    if (highLogs.isNotEmpty) {
      widgets.add(_buildSeveritySubHeader('⚠️ รุนแรง', highLogs.length, Colors.orange.shade700));
      widgets.add(const SizedBox(height: 6));
      widgets.addAll(highLogs.map((log) => _buildMqttLogCard(log, 'high')));
      widgets.add(const SizedBox(height: 8));
    }
    
    // Normal
    if (normalLogs.isNotEmpty) {
      widgets.add(_buildSeveritySubHeader('🟢 ปกติ', normalLogs.length, Colors.green.shade700));
      widgets.add(const SizedBox(height: 6));
      widgets.addAll(normalLogs.map((log) => _buildMqttLogCard(log, 'normal')));
    }
    
    return widgets;
  }
  
  // Build sensor type header (clickable)
  Widget _buildSensorTypeHeader(String title, int count, Color color, IconData icon, String sensorType, List<dynamic> logs) {
    return InkWell(
      onTap: () {
        // เปิดหน้ารายละเอียดแยกตามประเภทเซ็นเซอร์
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SensorDetailScreen(
              sensorType: sensorType,
              title: title,
              color: color,
              icon: icon,
              logs: logs,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$count รายการ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: color, size: 24),
          ],
        ),
      ),
    );
  }
  
  // Build severity sub-header
  Widget _buildSeveritySubHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build individual MQTT log card
  Widget _buildMqttLogCard(dynamic log, String severity) {
    Color cardColor;
    Color iconColor;
    Color badgeColor;
    IconData icon;
    String badgeText;
    
    switch (severity) {
      case 'critical':
        cardColor = Colors.red.shade50;
        iconColor = Colors.red.shade700;
        badgeColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
        badgeText = 'CRITICAL';
        break;
      case 'high':
        cardColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        badgeColor = Colors.orange.shade700;
        icon = Icons.warning;
        badgeText = 'HIGH';
        break;
      default:
        cardColor = Colors.white;
        iconColor = Colors.green.shade700;
        badgeColor = Colors.green.shade700;
        icon = Icons.show_chart;
        badgeText = 'NORMAL';
    }
    
    // แยกประเภทอุปกรณ์จาก Device ID
    String deviceType = 'Unknown';
    Color deviceTypeBadgeColor = Colors.blue.shade100;
    Color deviceTypeTextColor = Colors.blue.shade700;
    
    if (log.deviceId.startsWith('EQC-') || log.deviceId.startsWith('PMAC-')) {
      deviceType = 'EQNODE';
      deviceTypeBadgeColor = Colors.red.shade100;
      deviceTypeTextColor = Colors.red.shade700;
    } else if (log.deviceId.startsWith('TSU-')) {
      deviceType = 'TSUNAMI';
      deviceTypeBadgeColor = Colors.blue.shade100;
      deviceTypeTextColor = Colors.blue.shade700;
    } else if (log.deviceId.startsWith('TILT-')) {
      deviceType = 'TILT';
      deviceTypeBadgeColor = Colors.purple.shade100;
      deviceTypeTextColor = Colors.purple.shade700;
    } else if (log.deviceId.startsWith('TPO-')) {
      deviceType = 'TPO';
      deviceTypeBadgeColor = Colors.green.shade100;
      deviceTypeTextColor = Colors.green.shade700;
    }
    
    // กำหนดหน่วยและไอคอนตามประเภทเซ็นเซอร์
    String unit = 'Richter';
    IconData magnitudeIcon = Icons.speed;
    String magnitudeLabel = 'Magnitude';
    
    if (log.sensorType == 'tsunami') {
      unit = 'เมตร';
      magnitudeIcon = Icons.height;
      magnitudeLabel = 'ความสูงคลื่น';
    } else if (log.sensorType == 'tilt') {
      unit = 'องศา';
      magnitudeIcon = Icons.rotate_right;
      magnitudeLabel = 'มุมเอียง';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: severity == 'critical' ? 4 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: severity == 'critical' 
            ? BorderSide(color: Colors.red.shade700, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor,
                  radius: 20,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: deviceTypeBadgeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              deviceType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: deviceTypeTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              log.deviceId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
                        '${log.timestamp.second.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Magnitude Row
            Row(
              children: [
                Icon(magnitudeIcon, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '$magnitudeLabel: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${log.magnitude.toStringAsFixed(2)} $unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Location Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    log.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้าง Card อุปกรณ์แต่ละประเภท
  Widget _buildDeviceCard(
    BuildContext context,
    Map<String, dynamic> deviceType,
    List<Map<String, dynamic>> userDevices,
  ) {
    final deviceCount = _countDevicesByType(userDevices, deviceType['tag']);
    
    IconData cardIcon;
    switch (deviceType['tag']) {
      case 'earthquake': cardIcon = Icons.show_chart; break;
      case 'tsunami': cardIcon = Icons.device_thermostat; break;
      case 'tilt': cardIcon = Icons.swap_vert; break;
      default: cardIcon = Icons.device_hub;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DeviceDetailScreen(deviceType: deviceType['name']),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cardIcon, size: 36, color: Colors.red.shade700),
              const SizedBox(height: 5),
              Text(
                deviceType['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (deviceCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$deviceCount ตัว',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        // Get user's registered devices
        final List<Map<String, dynamic>> userDevices = userState.userDevices;
        final String? currentUserEmail = userState.currentUser?.email;

        if (currentUserEmail == null) {
          return const Scaffold(
            body: Center(
              child: Text("โปรดเข้าสู่ระบบเพื่อดูข้อมูลอุปกรณ์")
            )
          );
        }

        return Consumer<MqttManager>(
          builder: (context, mqttManager, child) {
            // Get MQTT logs
            final allLogs = mqttManager.recentLogs;
            final latestLog = allLogs.isNotEmpty ? allLogs.first : null;
            
            // Get device types that user has
            final availableDeviceTypes = _getAvailableDeviceTypes(userDevices);

            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'eQNode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24
                  )
                ),
                backgroundColor: Colors.red.shade900,
                elevation: 0,
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _isLoading ? null : _refreshDevices,
                    tooltip: 'รีเฟรชข้อมูล',
                  ),
                ],
                bottom: AppConfig.showMqttDevicesTab
                    ? TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.devices),
                            text: 'อุปกรณ์ของฉัน',
                          ),
                          Tab(
                            icon: Icon(Icons.wifi),
                            text: 'MQTT Real-time',
                          ),
                        ],
                      )
                    : null,
              ),

              body: AppConfig.showMqttDevicesTab
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: My Devices
                        _buildMyDevicesTab(userDevices, mqttManager, latestLog),
                        // Tab 2: MQTT Real-time
                        _buildMqttTab(mqttManager),
                      ],
                    )
                  : _buildMyDevicesTab(userDevices, mqttManager, latestLog),
            );
          },
        );
      },
    );
  }

  // Build My Devices Tab
  Widget _buildMyDevicesTab(
    List<Map<String, dynamic>> userDevices,
    MqttManager mqttManager,
    dynamic latestLog,
  ) {
    final availableDeviceTypes = _getAvailableDeviceTypes(userDevices);
    
    return RefreshIndicator(
      onRefresh: _refreshDevices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      // Loading indicator
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // MQTT Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: mqttManager.connectionState == MqttConnectionState.connected 
                              ? Colors.green.shade50 
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: mqttManager.connectionState == MqttConnectionState.connected 
                                ? Colors.green 
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  mqttManager.connectionState == MqttConnectionState.connected 
                                      ? Icons.wifi 
                                      : Icons.wifi_off,
                                  color: mqttManager.connectionState == MqttConnectionState.connected 
                                      ? Colors.green 
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'MQTT: ${mqttManager.connectionState.name.toUpperCase()}',
                                  style: TextStyle(
                                    color: mqttManager.connectionState == MqttConnectionState.connected 
                                        ? Colors.green.shade700 
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'อุปกรณ์ที่ลงทะเบียน: ${userDevices.length} ตัว | ข้อมูลล่าสุด: ${mqttManager.recentLogs.length} รายการ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            if (mqttManager.connectionState != MqttConnectionState.connected && AppConfig.enableMockData)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'กำลังใช้ข้อมูลจำลองเพื่อการทดสอบ',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ),
                    const Divider(),

                    // Device Type Cards
                    if (userDevices.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.devices_other,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ยังไม่มีอุปกรณ์ที่ลงทะเบียน',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'สแกน QR code เพื่อเพิ่มอุปกรณ์',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableDeviceTypes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final deviceType = availableDeviceTypes[index];
                          return _buildDeviceCard(context, deviceType, userDevices);
                        },
                      ),

                    const SizedBox(height: 30),

                    // Recent Events Section
                    const Text(
                      'ข้อมูลย้อนหลัง (Log ล่าสุด)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 10),

                    // Show latest log
                    if (latestLog == null)
                      const Text(
                        'ไม่พบข้อมูลเหตุการณ์ล่าสุด กรุณารอข้อมูลจาก MQTT...',
                        style: TextStyle(color: Colors.grey)
                      )
                    else
                      Card(
                        elevation: 4,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'แผ่นดินไหวขนาด ${latestLog.magnitude.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                )
                              ),
                              const SizedBox(height: 5),
                              Text('จากอุปกรณ์ ID: ${latestLog.deviceId}'),
                              Text(
                                'วันที่ ${latestLog.timestamp.day} ${_getMonthName(latestLog.timestamp.month)} ${latestLog.timestamp.year + 543} '
                                'เวลา ${latestLog.timestamp.hour.toString().padLeft(2, '0')}:'
                                '${latestLog.timestamp.minute.toString().padLeft(2, '0')}:'
                                '${latestLog.timestamp.second.toString().padLeft(2, '0')} น.'
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const HistoryDetailScreen()
                                      )
                                    );
                                  },
                                  child: const Text(
                                    'ดูบันทึกทั้งหมด >',
                                    style: TextStyle(color: Colors.red)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
  }

  // Build MQTT Tab
  Widget _buildMqttTab(MqttManager mqttManager) {
    return RefreshIndicator(
      onRefresh: _refreshDevices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MQTT Connection Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: mqttManager.connectionState == MqttConnectionState.connected
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: mqttManager.connectionState == MqttConnectionState.connected
                      ? Colors.green
                      : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    mqttManager.connectionState == MqttConnectionState.connected
                        ? Icons.wifi
                        : Icons.wifi_off,
                    color: mqttManager.connectionState == MqttConnectionState.connected
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MQTT Status: ${mqttManager.connectionState.name.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: mqttManager.connectionState == MqttConnectionState.connected
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                        Text(
                          'Total messages: ${mqttManager.recentLogs.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // MQTT Devices List
            const Text(
              'Real-time MQTT Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildMqttDevicesList(mqttManager),
          ],
        ),
      ),
    );
  }
}