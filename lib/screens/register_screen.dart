// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // สำหรับใช้จำลองการลงทะเบียน

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _agreedToTerms = false;
  bool _isButtonEnabled = false;

  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String _name = '';
  String _email = '';
  String _password = '';
  String _phone = '';
  String _address = '';

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
      validator: (value) =>
          value == null || value.isEmpty ? 'กรุณากรอกข้อมูล' : null,
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

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _agreedToTerms;
    });
  }

  Future<void> _submitRegister() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณายอมรับข้อกำหนดและเงื่อนไข'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    form.save();

    // Register user (backend will check if email exists)
    final result = await ApiService.registerUser(
      name: _name,
      email: _email,
      password: _password,
      phone: _phone,
      address: _address,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ลงทะเบียนสำเร็จ! สามารถเข้าสู่ระบบด้วยอีเมล $_email ได้เลย',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                  // 1. โลโก้ 'eQNode Earthquake!'
                  const Text(
                    'eQNode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Earthquake!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. ฟอร์มลงทะเบียน
                  _buildTextField(
                    hintText: 'ชื่อ นามสกุล',
                    icon: Icons.person,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    hintText: 'Email Address',
                    icon: Icons.email,
                    onSaved: (value) => _email = value!,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    hintText: 'รหัสผ่าน',
                    icon: Icons.lock,
                    isPassword: true,
                    onSaved: (value) => _password = value!,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    hintText: 'เบอร์โทรศัพท์',
                    icon: Icons.phone,
                    onSaved: (value) => _phone = value!,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    hintText: 'ที่อยู่',
                    icon: Icons.location_on,
                    onSaved: (value) => _address = value!,
                  ),
                  const SizedBox(height: 25),

                  // 3. Checkbox "ฉันยอมรับ..."
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _agreedToTerms = newValue ?? false;
                            _updateButtonState();
                          });
                        },
                        activeColor: Colors.red,
                        checkColor: Colors.white,
                      ),
                      const Expanded(
                        child: Text(
                          'ฉันยอมรับข้อกำหนดและเงื่อนไขส่วนตัว',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 4. ปุ่ม ลงทะเบียน (ควบคุมด้วย _isButtonEnabled)
                  ElevatedButton(
                    onPressed: _isButtonEnabled ? _submitRegister : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.red.withOpacity(0.5),
                    ),
                    child: const Text(
                      'ลงทะเบียน',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. ปุ่ม กลับไป Login
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                      style: TextStyle(color: Colors.white70),
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
