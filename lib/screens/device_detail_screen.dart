// lib/screens/device_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_manager.dart'; // สำหรับดึง Log ที่เกี่ยวข้อง

class DeviceDetailScreen extends StatelessWidget {
  final String deviceType;

  const DeviceDetailScreen({super.key, required this.deviceType});

  @override
  Widget build(BuildContext context) {
    // ใช้ Consumer เพื่อดู Log ที่เกี่ยวข้องกับอุปกรณ์ประเภทนี้
    return Consumer<MqttManager>(
      builder: (context, mqttManager, child) {
        // กรองเฉพาะ Log ที่ตรงกับประเภทอุปกรณ์ที่กำลังดูอยู่
        final relevantLogs = mqttManager.recentLogs
            .where(
              (log) => log.type == deviceType.toLowerCase().split(' ').last,
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              deviceType,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade900,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: relevantLogs.isEmpty
              ? const Center(
                  child: Text(
                    'ไม่พบข้อมูลการแจ้งเตือนล่าสุดสำหรับอุปกรณ์นี้',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: relevantLogs.length,
                  itemBuilder: (context, index) {
                    final log = relevantLogs[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          log.type == 'earthquake' ? Icons.warning : Icons.info,
                          color: log.magnitude > 3.0
                              ? Colors.red
                              : Colors.orange,
                        ),
                        title: Text(
                          '${deviceType} | ${log.magnitude.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: ${log.deviceId} | ที่: ${log.location}\nเวลา: ${log.timestamp.toLocal().toString().split('.')[0]}',
                        ),
                        onTap: () {
                          // TODO: นำทางไปหน้าจอแสดงกราฟ/ข้อมูลเฉพาะของ Log นี้
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
