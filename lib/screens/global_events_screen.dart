// lib/screens/global_events_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class GlobalEventsScreen extends StatefulWidget {
  const GlobalEventsScreen({super.key});

  @override
  State<GlobalEventsScreen> createState() => _GlobalEventsScreenState();
}

class _GlobalEventsScreenState extends State<GlobalEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _minMagnitude = AppConfig.globalEventsMinMagnitude;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getEarthquakeEvents(
        page: _currentPage,
        limit: AppConfig.globalEventsPageSize,
        minMagnitude: _minMagnitude,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _events = List<Map<String, dynamic>>.from(result['events'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'ไม่สามารถโหลดข้อมูลได้';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาด: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEvents() async {
    _currentPage = 1;
    await _loadEvents();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('กรองข้อมูล'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ขนาดต่ำสุด (Richter)'),
            Slider(
              value: _minMagnitude,
              min: 1.0,
              max: 7.0,
              divisions: 60,
              label: _minMagnitude.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _minMagnitude = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshEvents();
            },
            child: const Text('ใช้งาน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'แผ่นดินไหวทั่วโลก',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
            tooltip: 'กรองข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshEvents,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshEvents,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'ไม่พบข้อมูลแผ่นดินไหว',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองปรับเกณฑ์การกรอง',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final magnitude = (event['magnitude'] ?? 0.0).toDouble();
    final location = event['location'] ?? 'Unknown';
    final timestamp = event['timestamp'] != null
        ? DateTime.tryParse(event['timestamp'])
        : null;
    
    final isHighMagnitude = magnitude >= 5.0;
    final isModerateMagnitude = magnitude >= 3.0 && magnitude < 5.0;

    Color cardColor = Colors.white;
    Color magnitudeColor = Colors.green;
    
    if (isHighMagnitude) {
      cardColor = Colors.red.shade50;
      magnitudeColor = Colors.red;
    } else if (isModerateMagnitude) {
      cardColor = Colors.orange.shade50;
      magnitudeColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: magnitudeColor,
          child: Text(
            magnitude.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          location,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Magnitude: ${magnitude.toStringAsFixed(1)} Richter'),
            if (timestamp != null)
              Text(
                '${timestamp.day}/${timestamp.month}/${timestamp.year} '
                '${timestamp.hour.toString().padLeft(2, '0')}:'
                '${timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: Icon(
          isHighMagnitude
              ? Icons.warning
              : isModerateMagnitude
                  ? Icons.info
                  : Icons.check_circle,
          color: magnitudeColor,
        ),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รายละเอียดเหตุการณ์'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ขนาด', '${event['magnitude']} Richter'),
              _buildDetailRow('สถานที่', event['location'] ?? 'N/A'),
              if (event['latitude'] != null)
                _buildDetailRow('ละติจูด', event['latitude'].toString()),
              if (event['longitude'] != null)
                _buildDetailRow('ลองจิจูด', event['longitude'].toString()),
              if (event['type'] != null)
                _buildDetailRow('ประเภท', event['type']),
              if (event['timestamp'] != null)
                _buildDetailRow('เวลา', event['timestamp']),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
