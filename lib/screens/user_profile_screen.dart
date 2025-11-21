// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../services/user_state.dart'; // Import UserState
import 'login_screen.dart'; // ต้องมีสำหรับ Logout Logic (ถ้าใช้ใน MainScreen)

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ Consumer เพื่อดึงข้อมูลผู้ใช้ปัจจุบัน
    return Consumer<UserState>(
      builder: (context, userState, child) {
        final currentUser = userState.currentUser;

        // ถ้าไม่มีข้อมูล (ไม่ควรเกิดขึ้นถ้า Login สำเร็จ)
        if (currentUser == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'ข้อมูลผู้ใช้',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade900,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ส่วนที่ 1: Header และรูปโปรไฟล์
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'eQNode',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // รูปผู้ใช้
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ผู้ใช้ : ${currentUser.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ส่วนที่ 2: รายละเอียดผู้ใช้
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfoRow(
                          label: 'ชื่อ',
                          value: currentUser.name,
                          icon: Icons.badge,
                        ),
                        _buildUserInfoRow(
                          label: 'อีเมล',
                          value: currentUser.email,
                          icon: Icons.email,
                        ),
                        _buildUserInfoRow(
                          label: 'เบอร์โทรศัพท์',
                          value: currentUser.phone,
                          icon: Icons.phone,
                        ),
                        // ข้อมูลอื่น ๆ จะแสดงผลที่นี่
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    // ... (โค้ด Widget Helper ยังคงเดิม) ...
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
