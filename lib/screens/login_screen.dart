// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ต้องแน่ใจว่า path เหล่านี้ถูกต้อง
import 'register_screen.dart';
import 'main_screen.dart';
import 'forgot_password_screen.dart';
import '../services/api_service.dart';
import '../services/user_state.dart';
import '../services/mqtt_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  // Widget Helper สำหรับสร้างช่องกรอกข้อมูล (เหมือนเดิม)
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    FormFieldSetter<String>? onSaved,
  }) {
    return TextFormField(
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black),
      onSaved: onSaved,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอกข้อมูล';
        }
        if (hintText.contains('Email') && !value.contains('@')) {
          return 'รูปแบบอีเมลไม่ถูกต้อง';
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  // Logic สำหรับการ Login
  void _submitLogin() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    form.save();
    setState(() => _isLoading = true);

    final result = await ApiService.login(email: _email, password: _password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 2. จัดการผลลัพธ์
    if (result['success'] == true) {
      final userData = ApiService.getRegisteredUser(_email);

      // *** FIX: การเข้าถึง Provider ใน _submitLogin ต้องใช้ context ของ State ***
      // ถ้า provider ถูกกำหนดใน main.dart แล้ว วิธีนี้จะถูกต้องที่สุด
      final userState = Provider.of<UserState>(context, listen: false);
      userState.setUser(
        _email,
        result['name'] ?? 'ผู้ใช้ใหม่',
        userData?['phone'] ?? '08x-xxx-xxxx',
      );

      // เชื่อมต่อ MQTT หลังจาก Login สำเร็จ
      final mqttManager = Provider.of<MqttManager>(context, listen: false);
      mqttManager.connect();

      // Login สำเร็จ: นำทางไป MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Login ล้มเหลว: แสดงข้อความ Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ไม่มี Builder ห่อหุ้มแล้ว (เพราะ Provider อยู่ที่ main.dart)
    return Scaffold(
      body: Container(
        // ตั้งค่า Gradient Background
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
                  // 1. โลโก้ 'eQNode Earthquake!' (เหมือนเดิม)
                  const Text(
                    'eQNode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 10.0, color: Colors.black38),
                      ],
                    ),
                  ),
                  const Text(
                    'Earthquake!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 80),

                  // 2. ช่องกรอก Email
                  _buildTextField(
                    hintText: 'Email Address',
                    icon: Icons.email,
                    onSaved: (value) => _email = value!.trim(),
                  ),
                  const SizedBox(height: 20),

                  // 3. ช่องกรอก Password
                  _buildTextField(
                    hintText: 'Password',
                    icon: Icons.lock,
                    isPassword: true,
                    onSaved: (value) => _password = value!,
                  ),
                  const SizedBox(height: 40),

                  // 4. ปุ่ม Login
                  ElevatedButton(
                    // เรียก _submitLogin โดยไม่ส่ง context
                    onPressed: _isLoading ? null : _submitLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.red.withOpacity(0.5),
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
                            'Log in',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // 5. ลิงก์ Register และ Forgot Password (เหมือนเดิม)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'สร้างบัญชีใหม่?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
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
