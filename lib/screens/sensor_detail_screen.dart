// lib/screens/sensor_detail_screen.dart

import 'package:flutter/material.dart';

class SensorDetailScreen extends StatelessWidget {
  final String sensorType;
  final String title;
  final Color color;
  final IconData icon;
  final List<dynamic> logs;

  const SensorDetailScreen({
    super.key,
    required this.sensorType,
    required this.title,
    required this.color,
    required this.icon,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    // แยกตามความรุนแรง
    final criticalLogs = logs.where((log) {
      switch (sensorType) {
        case 'earthquake':
          return log.magnitude >= 7.0;
        case 'tsunami':
          return log.magnitude >= 3.0;
        case 'tilt':
          return log.magnitude >= 2.0;
        default:
          return log.magnitude >= 6.0;
      }
    }).toList();
    
    final highLogs = logs.where((log) {
      switch (sensorType) {
        case 'earthquake':
          return log.magnitude >= 6.0 && log.magnitude < 7.0;
        case 'tsunami':
          return log.magnitude >= 1.0 && log.magnitude < 3.0;
        case 'tilt':
          return log.magnitude >= 1.0 && log.magnitude < 2.0;
        default:
          return log.magnitude >= 5.0 && log.magnitude < 6.0;
      }
    }).toList();
    
    final moderateLogs = logs.where((log) {
      switch (sensorType) {
        case 'earthquake':
          return log.magnitude >= 5.0 && log.magnitude < 6.0;
        case 'tsunami':
          return log.magnitude >= 0.5 && log.magnitude < 1.0;
        case 'tilt':
          return log.magnitude >= 0.5 && log.magnitude < 1.0;
        default:
          return log.magnitude >= 4.0 && log.magnitude < 5.0;
      }
    }).toList();
    
    final lowLogs = logs.where((log) {
      switch (sensorType) {
        case 'earthquake':
          return log.magnitude >= 4.0 && log.magnitude < 5.0;
        case 'tsunami':
          return log.magnitude < 0.5;
        case 'tilt':
          return log.magnitude < 0.5;
        default:
          return log.magnitude < 4.0;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // สถิติ
            _buildStatisticsCard(),
            const SizedBox(height: 16),
            
            // รายการข้อมูล
            if (criticalLogs.isNotEmpty) ...[
              _buildSectionHeader('🚨 รุนแรงมาก', criticalLogs.length, Colors.red.shade700),
              const SizedBox(height: 8),
              ...criticalLogs.map((log) => _buildLogCard(log, 'critical')),
              const SizedBox(height: 16),
            ],
            
            if (highLogs.isNotEmpty) ...[
              _buildSectionHeader('⚠️ รุนแรง', highLogs.length, Colors.orange.shade700),
              const SizedBox(height: 8),
              ...highLogs.map((log) => _buildLogCard(log, 'high')),
              const SizedBox(height: 16),
            ],
            
            if (moderateLogs.isNotEmpty) ...[
              _buildSectionHeader('🟡 ปานกลาง', moderateLogs.length, Colors.amber.shade700),
              const SizedBox(height: 8),
              ...moderateLogs.map((log) => _buildLogCard(log, 'moderate')),
              const SizedBox(height: 16),
            ],
            
            if (lowLogs.isNotEmpty) ...[
              _buildSectionHeader('🟢 ต่ำ', lowLogs.length, Colors.green.shade700),
              const SizedBox(height: 8),
              ...lowLogs.map((log) => _buildLogCard(log, 'low')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = logs.length;
    final maxMagnitude = logs.isEmpty ? 0.0 : logs.map((log) => log.magnitude).reduce((a, b) => a > b ? a : b);
    final avgMagnitude = logs.isEmpty ? 0.0 : logs.map((log) => log.magnitude).reduce((a, b) => a + b) / logs.length;
    
    String unit = 'Richter';
    if (sensorType == 'tsunami') unit = 'เมตร';
    if (sensorType == 'tilt') unit = 'องศา';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถิติ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('ทั้งหมด', '$total', 'รายการ'),
                _buildStatItem('สูงสุด', maxMagnitude.toStringAsFixed(2), unit),
                _buildStatItem('เฉลี่ย', avgMagnitude.toStringAsFixed(2), unit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color headerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: headerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: headerColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(dynamic log, String severity) {
    Color cardColor;
    Color iconColor;
    IconData cardIcon;
    
    switch (severity) {
      case 'critical':
        cardColor = Colors.red.shade50;
        iconColor = Colors.red.shade700;
        cardIcon = Icons.warning_amber_rounded;
        break;
      case 'high':
        cardColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        cardIcon = Icons.warning;
        break;
      case 'moderate':
        cardColor = Colors.amber.shade50;
        iconColor = Colors.amber.shade700;
        cardIcon = Icons.info;
        break;
      default:
        cardColor = Colors.white;
        iconColor = Colors.green.shade700;
        cardIcon = Icons.check_circle;
    }
    
    String unit = 'Richter';
    String label = 'Magnitude';
    if (sensorType == 'tsunami') {
      unit = 'เมตร';
      label = 'ความสูงคลื่น';
    } else if (sensorType == 'tilt') {
      unit = 'องศา';
      label = 'มุมเอียง';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor,
              radius: 20,
              child: Icon(cardIcon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.deviceId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$label: ${log.magnitude.toStringAsFixed(2)} $unit',
                    style: TextStyle(
                      fontSize: 13,
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    log.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${log.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${log.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${log.timestamp.second.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
