// lib/screens/qr_scanner_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import 'device_registration_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onDeviceScanned;

  const QRScannerScreen({
    super.key,
    required this.onDeviceScanned,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  String _scanResult = '';

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    if (AppConfig.enableDebugLogging) {
      debugPrint('Camera permission status: $status');
    }
    
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        // แสดง dialog แทน snackbar เพื่อให้เห็นชัดเจน
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ต้องการสิทธิ์กล้อง'),
            content: Text(
              status.isPermanentlyDenied
                  ? 'กรุณาเปิดสิทธิ์กล้องในการตั้งค่าของแอป'
                  : 'แอปต้องการสิทธิ์ใช้กล้องเพื่อสแกน QR Code',
            ),
            actions: [
              if (status.isPermanentlyDenied)
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('เปิดการตั้งค่า'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('ปิด'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanning && capture.barcodes.isNotEmpty) {
      final String? qrData = capture.barcodes.first.rawValue;
      if (qrData != null) {
        _processQRCode(qrData);
      }
    }
  }

  void _processQRCode(String qrData) {
    setState(() {
      _isScanning = false;
      _scanResult = qrData;
    });

    try {
      // Check if QR code has expected prefix
      String processedData = qrData;
      if (qrData.startsWith(AppConfig.qrCodePrefix)) {
        processedData = qrData.substring(AppConfig.qrCodePrefix.length);
      }

      // Try to parse as JSON first (structured QR code)
      try {
        final Map<String, dynamic> deviceData = jsonDecode(processedData);
        
        // Validate required fields
        if (deviceData.containsKey('deviceId')) {
          // Ensure type field exists
          if (!deviceData.containsKey('type')) {
            deviceData['type'] = 'earthquake'; // Default type
          }
          
          if (AppConfig.enableDebugLogging) {
            debugPrint('QR Code parsed: $deviceData');
          }
          
          _navigateToRegistration(deviceData);
        } else {
          _showInvalidQRDialog('QR Code ไม่มีข้อมูล deviceId');
        }
      } catch (jsonError) {
        // If not JSON, treat as simple device ID
        if (processedData.isNotEmpty) {
          final deviceData = {
            'deviceId': processedData,
            'type': 'earthquake', // Default type
            'name': 'Sensor $processedData',
          };
          
          if (AppConfig.enableDebugLogging) {
            debugPrint('QR Code treated as device ID: $processedData');
          }
          
          _navigateToRegistration(deviceData);
        } else {
          _showInvalidQRDialog('QR Code ว่างเปล่า');
        }
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('Error processing QR code: $e');
      }
      _showInvalidQRDialog('เกิดข้อผิดพลาดในการประมวลผล QR Code');
    }
  }

  void _navigateToRegistration(Map<String, dynamic> deviceData) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceRegistrationScreen(
          deviceId: deviceData['deviceId'],
          initialName: deviceData['name'] ?? 'Sensor ${deviceData['deviceId']}',
          initialTag: deviceData['type'] ?? 'earthquake',
          onDeviceRegistered: widget.onDeviceScanned,
        ),
      ),
    );
  }

  void _showInvalidQRDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code ไม่ถูกต้อง'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isScanning = true;
                _scanResult = '';
              });
            },
            child: const Text('สแกนใหม่'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR Code'),
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ไม่สามารถเปิดกล้องได้',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ?? 'กรุณาตรวจสอบสิทธิ์กล้อง',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => openAppSettings(),
                        icon: const Icon(Icons.settings),
                        label: const Text('เปิดการตั้งค่า'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_scanResult.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black87,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'กำลังประมวลผล...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _scanResult,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(Icons.qr_code_scanner, size: 32, color: Colors.blue.shade700),
                const SizedBox(height: 8),
                const Text(
                  'วาง QR Code ในกรอบ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
