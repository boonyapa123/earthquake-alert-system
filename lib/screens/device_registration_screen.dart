// lib/screens/device_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class DeviceRegistrationScreen extends StatefulWidget {
  final String deviceId;
  final bool isReinstall;
  final String initialName; 
  final String initialTag; // สำหรับระบุประเภทอุปกรณ์ที่มาจาก QR Scan
  final Function(Map<String, dynamic>) onDeviceRegistered;

  const DeviceRegistrationScreen({
    super.key,
    required this.deviceId,
    this.isReinstall = false,
    required this.onDeviceRegistered,
    this.initialName = '', 
    this.initialTag = 'earthquake', // ค่าเริ่มต้นสำหรับ Tag
  });

  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Location variables
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  String _locationStatus = 'ยังไม่ได้รับตำแหน่ง';

  // Form variables
  String _deviceName = '';
  String _address = '';
  String _province = '';
  String _district = '';
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _nameController = TextEditingController(
      text: widget.isReinstall
          ? widget.initialName
          : (widget.initialName.isNotEmpty
                ? widget.initialName
                : 'Sensor ID ${widget.deviceId}'),
    );
    _latController = TextEditingController();
    _lonController = TextEditingController();
    
    // Auto-get location on init
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'กำลังรับตำแหน่ง...';
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'ไม่ได้รับอนุญาตใช้ตำแหน่ง';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'การใช้ตำแหน่งถูกปฏิเสธถาวร';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _locationStatus = 'รับตำแหน่งสำเร็จ';
        _isLoadingLocation = false;
      });

    } catch (e) {
      setState(() {
        _locationStatus = 'เกิดข้อผิดพลาด: $e';
        _isLoadingLocation = false;
        // Set default Bangkok coordinates as fallback
        _latitude = 13.7563;
        _longitude = 100.5018;
        _latController.text = '13.7563';
        _lonController.text = '100.5018';
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('กำลังลงทะเบียนอุปกรณ์...'),
            ],
          ),
        ),
      );

      try {
        // Call API to register device
        final result = await ApiService.registerDevice(
          deviceId: widget.deviceId,
          deviceName: _deviceName,
          location: '$_province, $_district',
          latitude: _latitude ?? 13.7563,
          longitude: _longitude ?? 100.5018,
        );

        // Close loading dialog
        Navigator.pop(context);

        if (result['success']) {
          // Final Data Structure ที่จะส่งกลับไปบันทึกใน UserState
          final newDeviceData = {
            'id': widget.deviceId,
            'name': _deviceName,
            'location': '$_province, $_district',
            'address': _address,
            'lat': _latitude ?? 13.7563,
            'lon': _longitude ?? 100.5018,
            'status': 'Online',
            'tag': widget.initialTag,
          };

          // ส่งข้อมูลกลับไปยัง SystemSettingsScreen
          widget.onDeviceRegistered(newDeviceData);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'ลงทะเบียนสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );

          // นำทางกลับ
          Navigator.pop(context);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReinstall ? 'ย้าย/ลงทะเบียนใหม่' : 'ลงทะเบียนอุปกรณ์ใหม่',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // แสดง Device ID
              Text(
                'Device ID ที่สแกน: ${widget.deviceId} (${widget.initialTag.toUpperCase()})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 1. ชื่ออุปกรณ์ (ใช้ Controller เพื่อแสดงค่าเริ่มต้นจาก QR)
              _buildTextFormField(
                label: 'ชื่ออุปกรณ์ (เช่น Sensor อาคาร A)',
                controller: _nameController,
                onSaved: (value) => _deviceName = value!,
              ),
              const SizedBox(height: 15),

              // 2. ฟอร์มกรอกที่อยู่
              _buildTextFormField(
                label: 'ที่อยู่โดยละเอียด',
                onSaved: (value) => _address = value!,
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                label: 'จังหวัด',
                onSaved: (value) => _province = value!,
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                label: 'อำเภอ/เขต',
                onSaved: (value) => _district = value!,
              ),
              const SizedBox(height: 15),

              // 3. Location Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'ตำแหน่งที่ติดตั้ง',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (_isLoadingLocation)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _getCurrentLocation,
                            tooltip: 'รับตำแหน่งใหม่',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _locationStatus,
                      style: TextStyle(
                        color: _latitude != null ? Colors.green.shade700 : Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            label: 'Latitude',
                            controller: _latController,
                            keyboardType: TextInputType.number,
                            onSaved: (value) {
                              _latitude = double.tryParse(value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextFormField(
                            label: 'Longitude',
                            controller: _lonController,
                            keyboardType: TextInputType.number,
                            onSaved: (value) {
                              _longitude = double.tryParse(value ?? '');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 4. ปุ่ม Submit
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  widget.isReinstall ? 'อัปเดตสถานที่' : 'ลงทะเบียนอุปกรณ์',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper สำหรับ Text Form Field
  Widget _buildTextFormField({
    required String label,
    TextEditingController? controller,
    ValueChanged<String?>? onSaved,
    TextInputType keyboardType = TextInputType.text,
    String initialValue = '',
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      // ใช้ initialValue ก็ต่อเมื่อไม่มี Controller เท่านั้น
      initialValue: controller == null ? initialValue : null, 
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
      ),
      validator: (value) {
        if (enabled && (value == null || value.isEmpty)) {
          return 'กรุณากรอกข้อมูล $label';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}