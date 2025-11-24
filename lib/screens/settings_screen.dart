// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_state.dart';
import '../services/mqtt_manager.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  double _alertThreshold = 3.0;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _maxNotificationCount = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await StorageService.loadUserSettings();
      
      if (mounted) {
        setState(() {
          _notificationsEnabled = settings.notificationsEnabled;
          _alertThreshold = settings.alertThreshold;
          _soundEnabled = settings.soundEnabled;
          _vibrationEnabled = settings.vibrationEnabled;
          _maxNotificationCount = settings.maxNotificationCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('ไม่สามารถโหลดการตั้งค่าได้: $e', isError: true);
      }
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    final settings = UserSettings(
      notificationsEnabled: _notificationsEnabled,
      alertThreshold: _alertThreshold,
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
      maxNotificationCount: _maxNotificationCount,
      theme: 'system',
      language: 'th',
    );

    final success = await StorageService.saveUserSettings(settings);
    
    if (success) {
      _showMessage('บันทึกการตั้งค่าสำเร็จ');
    } else {
      _showMessage('ไม่สามารถบันทึกการตั้งค่าได้', isError: true);
    }
  }

  // Show snackbar message
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ส่วนข้อมูลผู้ใช้
                _buildUserSection(context),
                const Divider(height: 32),

                // ส่วนการแจ้งเตือน
                _buildNotificationSection(),
                const Divider(height: 32),

                // ส่วนข้อมูลระบบ
                _buildSystemSection(context),
                const Divider(height: 32),

                // ปุ่ม Logout
                _buildLogoutButton(context),
              ],
            ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final user = userState.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลผู้ใช้',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade700,
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user?.email ?? 'ไม่ระบุ'),
              subtitle: const Text('User Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'การแจ้งเตือน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            SwitchListTile(
              title: const Text('เปิดการแจ้งเตือน'),
              subtitle: const Text('รับการแจ้งเตือนเมื่อเกิดแผ่นดินไหว'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _saveSettings();
              },
              activeColor: Colors.red.shade700,
            ),
            
            const Divider(),
            
            ListTile(
              title: const Text('เกณฑ์การแจ้งเตือน'),
              subtitle: Text('แจ้งเตือนเมื่อขนาด >= ${_alertThreshold.toStringAsFixed(1)} Richter'),
            ),
            Slider(
              value: _alertThreshold,
              min: 1.0,
              max: 7.0,
              divisions: 60,
              label: _alertThreshold.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _alertThreshold = value);
              },
              onChangeEnd: (value) async {
                await _saveSettings();
              },
              activeColor: Colors.red.shade700,
            ),
            
            const Divider(),
            
            ListTile(
              title: const Text('จำนวนครั้งการแจ้งเตือนสูงสุด'),
              subtitle: Text('แจ้งเตือนสูงสุด $_maxNotificationCount ครั้งต่อเหตุการณ์'),
            ),
            Slider(
              value: _maxNotificationCount.toDouble(),
              min: AppConfig.minNotificationCount.toDouble(),
              max: AppConfig.maxNotificationCount.toDouble(),
              divisions: AppConfig.maxNotificationCount - AppConfig.minNotificationCount,
              label: _maxNotificationCount.toString(),
              onChanged: (value) {
                setState(() => _maxNotificationCount = value.toInt());
              },
              onChangeEnd: (value) async {
                await _saveSettings();
              },
              activeColor: Colors.red.shade700,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('เสียงแจ้งเตือน'),
              value: _soundEnabled,
              onChanged: (value) async {
                setState(() => _soundEnabled = value);
                await _saveSettings();
              },
              activeColor: Colors.red.shade700,
            ),
            
            SwitchListTile(
              title: const Text('สั่นเตือน'),
              value: _vibrationEnabled,
              onChanged: (value) async {
                setState(() => _vibrationEnabled = value);
                await _saveSettings();
              },
              activeColor: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSection(BuildContext context) {
    final mqttManager = Provider.of<MqttManager>(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลระบบ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            ListTile(
              leading: Icon(
                mqttManager.connectionState == MqttConnectionState.connected
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: mqttManager.connectionState == MqttConnectionState.connected
                    ? Colors.green
                    : Colors.red,
              ),
              title: const Text('สถานะ MQTT'),
              subtitle: Text(mqttManager.connectionState.toString().split('.').last.toUpperCase()),
            ),
            
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.blue),
              title: const Text('Backend API'),
              subtitle: Text(AppConfig.baseUrl),
            ),
            
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.orange),
              title: const Text('MQTT Broker'),
              subtitle: Text('${AppConfig.mqttHost}:${AppConfig.mqttPort}'),
            ),
            
            ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: const Text('เวอร์ชัน'),
              subtitle: Text('${AppConfig.appVersion} (${AppConfig.buildNumber})'),
            ),
            
            ListTile(
              leading: const Icon(Icons.developer_mode, color: Colors.purple),
              title: const Text('Environment'),
              subtitle: Text(AppConfig.environment.name.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutDialog(context);
        },
        icon: const Icon(Icons.logout),
        label: const Text('ออกจากระบบ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              // Disconnect MQTT before logout
              final mqttManager = Provider.of<MqttManager>(context, listen: false);
              mqttManager.disconnect();
              
              // Logout user
              final userState = Provider.of<UserState>(context, listen: false);
              userState.logout();
              
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('ออกจากระบบ', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}
