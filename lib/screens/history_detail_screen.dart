// lib/screens/history_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_manager.dart';
import '../services/user_state.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  String _filterType = 'all'; // all, earthquake, tsunami, tilt
  bool _showOnlyUserDevices = true;

  String _getThaiEventType(String type) {
    switch (type.toLowerCase()) {
      case 'earthquake': return 'แผ่นดินไหว';
      case 'tsunami': return 'สึนามิ';
      case 'tilt': return 'ความเอียง';
      default: return type;
    }
  }

  Color _getSeverityColor(double magnitude) {
    if (magnitude >= 4.0) return Colors.red;
    if (magnitude >= 3.0) return Colors.orange;
    if (magnitude >= 2.0) return Colors.yellow.shade700;
    return Colors.green;
  }

  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'earthquake': return Icons.show_chart;
      case 'tsunami': return Icons.waves;
      case 'tilt': return Icons.swap_vert;
      default: return Icons.sensors;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MqttManager, UserState>(
      builder: (context, mqttManager, userState, child) {
        final allLogs = mqttManager.recentLogs;
        final userDeviceIds = userState.userDevices.map((d) => d['id']).toSet();
        
        // Filter logs based on user preferences
        final filteredLogs = allLogs.where((log) {
          // Filter by device ownership
          if (_showOnlyUserDevices && !userDeviceIds.contains(log.deviceId)) {
            return false;
          }
          
          // Filter by event type
          if (_filterType != 'all' && log.type.toLowerCase() != _filterType) {
            return false;
          }
          
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'บันทึกเหตุการณ์',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade900,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onSelected: (value) {
                  setState(() {
                    _filterType = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('ทั้งหมด')),
                  const PopupMenuItem(value: 'earthquake', child: Text('แผ่นดินไหว')),
                  const PopupMenuItem(value: 'tsunami', child: Text('สึนามิ')),
                  const PopupMenuItem(value: 'tilt', child: Text('ความเอียง')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter controls
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'แสดง ${filteredLogs.length} รายการจากทั้งหมด ${allLogs.length} รายการ',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: _showOnlyUserDevices,
                      onChanged: (value) {
                        setState(() {
                          _showOnlyUserDevices = value;
                        });
                      },
                      activeColor: Colors.red.shade700,
                    ),
                    const Text('อุปกรณ์ของฉัน', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              
              // Logs list
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlyUserDevices 
                                  ? 'ไม่มีบันทึกจากอุปกรณ์ที่คุณลงทะเบียน'
                                  : 'ยังไม่มีบันทึกเหตุการณ์',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final isUserDevice = userDeviceIds.contains(log.deviceId);
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getSeverityColor(log.magnitude).withOpacity(0.2),
                                child: Icon(
                                  _getEventIcon(log.type),
                                  color: _getSeverityColor(log.magnitude),
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_getThaiEventType(log.type)} | ขนาด ${log.magnitude.toStringAsFixed(1)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (isUserDevice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'ของฉัน',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('อุปกรณ์: ${log.deviceId}'),
                                  Text('สถานที่: ${log.location}'),
                                  Text(
                                    'เวลา: ${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios, 
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              onTap: () {
                                // Show detailed dialog
                                _showLogDetails(context, log, isUserDevice);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogDetails(BuildContext context, MqttLog log, bool isUserDevice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายละเอียดเหตุการณ์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ประเภท', _getThaiEventType(log.type)),
            _buildDetailRow('ขนาด/ความรุนแรง', log.magnitude.toStringAsFixed(2)),
            _buildDetailRow('อุปกรณ์ ID', log.deviceId),
            _buildDetailRow('สถานที่', log.location),
            _buildDetailRow('เจ้าของ', isUserDevice ? 'อุปกรณ์ของคุณ' : 'อุปกรณ์อื่น'),
            _buildDetailRow('วันที่-เวลา', 
              '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} '
              '${log.timestamp.hour.toString().padLeft(2, '0')}:'
              '${log.timestamp.minute.toString().padLeft(2, '0')}:'
              '${log.timestamp.second.toString().padLeft(2, '0')}'
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
