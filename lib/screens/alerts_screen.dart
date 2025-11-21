// lib/screens/alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_manager.dart';
import '../services/storage_service.dart';
import '../services/user_state.dart';
import '../config/app_config.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _notificationsEnabled = true;
  double _alertThreshold = 3.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load notification settings
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await StorageService.loadUserSettings();
      
      if (mounted) {
        setState(() {
          _notificationsEnabled = settings.notificationsEnabled;
          _alertThreshold = settings.alertThreshold;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Toggle notifications
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    
    // Save to storage
    await StorageService.setNotificationsEnabled(value);
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'เปิดการแจ้งเตือนแล้ว' : 'ปิดการแจ้งเตือนแล้ว'
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Filter alerts by user's devices and threshold
  List<Map<String, dynamic>> _filterAlerts(
    MqttManager mqttManager,
    UserState userState,
  ) {
    final userDeviceIds = userState.userDevices
        .map((d) => d['id'] as String?)
        .where((id) => id != null)
        .toSet();

    // Get alerts from MQTT logs
    return mqttManager.recentLogs
        .where((log) {
          // Filter by threshold
          if (log.magnitude < _alertThreshold) return false;
          
          // Filter by user's devices (if user has devices)
          if (userDeviceIds.isNotEmpty && !userDeviceIds.contains(log.deviceId)) {
            return false;
          }
          
          return true;
        })
        .map((log) => {
              'id': '${log.deviceId}_${log.timestamp.millisecondsSinceEpoch}',
              'title': log.magnitude >= 5.0
                  ? '🔴 WARNING: แผ่นดินไหวรุนแรง'
                  : '🟡 ALERT: แผ่นดินไหวปานกลาง',
              'detail': 'ตรวจพบแผ่นดินไหวขนาด ${log.magnitude.toStringAsFixed(1)} Richter',
              'magnitude': log.magnitude,
              'time': '${log.timestamp.hour.toString().padLeft(2, '0')}:'
                      '${log.timestamp.minute.toString().padLeft(2, '0')} น.',
              'isWarning': log.magnitude >= 5.0,
              'type': log.type,
              'deviceId': log.deviceId,
              'deviceName': log.location,
              'location': log.location,
              'timestamp': log.timestamp,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MqttManager, UserState>(
      builder: (context, mqttManager, userState, child) {
        // Filter alerts by user's devices and threshold
        final alerts = _filterAlerts(mqttManager, userState);

        return _buildAlertScreen(context, alerts);
      },
    );
  }

  Widget _buildAlertScreen(BuildContext context, List<Map<String, dynamic>> alerts) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ส่วน Toggle เปิด/ปิดการแจ้งเตือนรวม
          _buildToggleAlerts(),

          // แสดงจำนวนการแจ้งเตือน
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'การแจ้งเตือนทั้งหมด: ${alerts.length} รายการ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // รายการแจ้งเตือน
          Expanded(
            child: alerts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'ไม่มีการแจ้งเตือน',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'รอข้อมูลจาก MQTT...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleAlerts() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 8),
      color: _notificationsEnabled ? Colors.green.shade50 : Colors.red.shade50,
      child: SwitchListTile(
        title: Text(
          _notificationsEnabled ? 'การแจ้งเตือนเปิดอยู่' : 'การแจ้งเตือนปิดอยู่'
        ),
        subtitle: Text(
          _notificationsEnabled
              ? 'แจ้งเตือนเมื่อขนาด >= ${_alertThreshold.toStringAsFixed(1)} Richter'
              : 'คุณจะไม่ได้รับการแจ้งเตือน'
        ),
        value: _notificationsEnabled,
        onChanged: _toggleNotifications,
        activeColor: Colors.green,
        secondary: Icon(
          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: _notificationsEnabled ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    // กำหนด Icon ตามประเภทการแจ้งเตือน
    IconData icon = Icons.crisis_alert;
    Color iconColor = Colors.orange;
    if (alert['isWarning']) {
      icon = Icons.warning;
      iconColor = Colors.red;
    } else if (alert['type'] == 'tsunami') {
      icon = Icons.waves;
      iconColor = Colors.blue;
    } else if (alert['type'] == 'tilt') {
      icon = Icons.device_hub;
      iconColor = Colors.brown;
    }

    return Card(
      color: alert['isWarning'] ? Colors.red.shade50 : Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          '${alert['title']} (${alert['deviceName']})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${alert['detail']}\nID: ${alert['deviceId']} | ${alert['time']}',
        ),
        isThreeLine: true,
        trailing: alert['isWarning']
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: () {
          // TODO: แสดงรายละเอียดเพิ่มเติม (ควรนำทางไปหน้า DeviceDetailScreen)
          print('View Alert Detail for ${alert['deviceId']}');
        },
      ),
    );
  }
}
