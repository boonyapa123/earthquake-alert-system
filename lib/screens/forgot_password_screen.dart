// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ใช้ ApiService เพื่อจำลองการส่งอีเมล

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  String _email = '';
  bool _isLoading = false;

  void _submitRequest() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    form.save();
    setState(() => _isLoading = true);

    // TODO: ในโค้ดจริง คุณต้องสร้าง API endpoint สำหรับการส่งอีเมลกู้คืนรหัสผ่าน
    // ตอนนี้เราจะจำลองว่าสำเร็จเสมอ
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // แสดงผลสำเร็จ
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ส่งลิงก์เปลี่ยนรหัสผ่านไปที่ $_email เรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ),
    );

    // นำทางกลับไปหน้า Login
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลืมรหัสผ่าน', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // ใช้ Gradient Background เดียวกับหน้า Login
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade800, Colors.red.shade900],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'กรุณากรอกอีเมลเพื่อรับลิงก์สำหรับเปลี่ยนรหัสผ่าน',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // ช่องกรอก Email
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    onSaved: (value) => _email = value!,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'กรุณากรอกอีเมลที่ถูกต้อง'
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Email Address',
                      prefixIcon: const Icon(Icons.email, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ปุ่มส่งคำขอ
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'ส่งคำขอ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
