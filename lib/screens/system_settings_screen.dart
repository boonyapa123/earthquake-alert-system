// lib/screens/system_settings_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart'; 
import '../services/user_state.dart'; 
import 'device_registration_screen.dart';
import 'qr_scanner_screen.dart';
import '../services/notification_service.dart'; 

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  // Mock State สำหรับตั้งค่าการแจ้งเตือน
  int _alertRepetitions = 1; 
  final int _alertIntervalSeconds = 1; 
  final List<int> _repetitionOptions = [1, 2, 3]; 
  bool _isTesting = false; 

  // Function สำหรับการสแกน QR Code (ใช้ QR Scanner จริง)
  void _scanQrAndRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onDeviceScanned: (deviceData) {
            // เมื่อสแกนสำเร็จและลงทะเบียนเสร็จแล้ว
            Provider.of<UserState>(context, listen: false).addOrUpdateDevice(deviceData);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ลงทะเบียนอุปกรณ์ ${deviceData['id']} สำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  // Mock Function สำหรับการถอนติดตั้ง
  void _uninstallDevice(String id) {
    Provider.of<UserState>(context, listen: false).removeDevice(id);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ถอนติดตั้งอุปกรณ์ $id สำเร็จ')));
  }

  // Mock Function สำหรับการลงทะเบียนใหม่ (Reinstall)
  void _reinstallDevice(Map<String, dynamic> device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceRegistrationScreen(
          deviceId: device['id'],
          isReinstall: true,
          initialName: device['name'], 
          initialTag: device['tag'], 
          onDeviceRegistered: (updatedDevice) {
            Provider.of<UserState>(context, listen: false).addOrUpdateDevice(updatedDevice);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ย้ายและลงทะเบียนอุปกรณ์ ${device['id']} สำเร็จ'),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Function สำหรับทดสอบการแจ้งเตือน (ใช้ NotificationService จริง)
  void _testAlert() async {
    if (_isTesting) return; 
    setState(() => _isTesting = true);

    try {
      // ทดสอบการแจ้งเตือนตามจำนวนครั้งที่ตั้งไว้
      for (int i = 1; i <= _alertRepetitions; i++) {
        if (!mounted) break;

        // แสดง SnackBar เพื่อแจ้งสถานะ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 ทดสอบการแจ้งเตือนครั้งที่ $i/$_alertRepetitions'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(milliseconds: 800),
          ),
        );

        // ส่งการแจ้งเตือนจริงผ่าน NotificationService
        await NotificationService.showEarthquakeAlert(
          'ทดสอบการแจ้งเตือน',
          'นี่คือการทดสอบระบบแจ้งเตือนแผ่นดินไหว ครั้งที่ $i',
          magnitude: 4.5,
        );
        
        // หน่วงเวลาระหว่างการแจ้งเตือน
        if (i < _alertRepetitions) {
          await Future.delayed(Duration(seconds: _alertIntervalSeconds));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ การทดสอบการแจ้งเตือนเสร็จสมบูรณ์'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการทดสอบ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        final userDevices = userState.userDevices;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ตั้งค่าระบบ', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade900,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // =======================================================
                // 1. การแจ้งเตือน
                // =======================================================
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('การแจ้งเตือน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        
                        // Row เลือกจำนวนครั้ง
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('จำนวนการแจ้งเตือน:', style: TextStyle(fontSize: 14)),
                            Row(
                              children: _repetitionOptions.map((count) {
                                final isSelected = _alertRepetitions == count;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ChoiceChip(
                                    label: Text('$count'),
                                    selected: isSelected,
                                    selectedColor: Colors.red.shade700,
                                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.red.shade700, fontWeight: FontWeight.bold),
                                    backgroundColor: isSelected ? Colors.red.shade700 : Colors.red.shade100,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _alertRepetitions = count);
                                      }
                                    },
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // ปุ่ม ทดสอบการแจ้งเตือน
                        ElevatedButton(
                          onPressed: _isTesting ? null : _testAlert, // ปิดปุ่มเมื่อกำลังทดสอบ
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isTesting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('ทดสอบการแจ้งเตือน', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // =======================================================
                // 2. ลงทะเบียนอุปกรณ์ใหม่
                // =======================================================
                const SizedBox(height: 30),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ลงทะเบียนอุปกรณ์ใหม่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        const Text('สแกน QR Code เพื่อลงทะเบียนและระบุพิกัด', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 15),
                        
                        // ปุ่ม สแกน QR Code
                        ElevatedButton(
                          onPressed: _scanQrAndRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('สแกน QR Code', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),

                // =======================================================
                // 3. จัดการอุปกรณ์ (Device List)
                // =======================================================
                const SizedBox(height: 30),
                const Text('จัดการอุปกรณ์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // แสดงรายการอุปกรณ์จริงจาก UserState
                ...userDevices.map((device) {
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(device['name']),
                      subtitle: Text('ID: ${device['id']} | สถานที่: ${device['location']} (${device['tag']?.toUpperCase()})'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ปุ่มถอนการติดตั้ง
                          TextButton(
                            onPressed: () => _uninstallDevice(device['id']),
                            child: Text('ถอนการติดตั้ง', style: TextStyle(color: Colors.red.shade700)),
                          ),
                          // ปุ่ม Reinstall/Menu (ถ้ามี Logic เพิ่มเติม)
                          PopupMenuButton<String>(
                            onSelected: (String result) {
                              if (result == 'reinstall') {
                                _reinstallDevice(device);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(value: 'reinstall', child: Text('ย้ายตำแหน่ง/ลงทะเบียนใหม่')),
                                ],
                          ),
                        ],
                      ),
                      onTap: () {
                         // นำทางไปหน้า Device Detail
                      }
                    ),
                  );
                }).toList(),

                if (userDevices.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: Text('ยังไม่มีอุปกรณ์ติดตั้ง'))),
              ],
            ),
          ),
        );
      },
    );
  }
}