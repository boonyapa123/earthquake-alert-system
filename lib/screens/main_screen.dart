// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_state.dart';
import 'login_screen.dart';
// Import หน้าจออื่นๆ ที่จะต้องสร้างต่อไป
import 'home_screen.dart';
import 'alerts_screen.dart';
import 'user_profile_screen.dart';
import 'system_settings_screen.dart';
// import 'settings_screen.dart'; // <<< ไม่ใช้แล้ว

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // รายการหน้าจอที่ใช้ใน Navigation Bar (4 หน้าจอหลัก + 1 Action)
  final List<Widget> _screens = [
    const HomeScreen(), // Index 0: หน้าหลัก
    const AlertsScreen(), // Index 1: แจ้งเตือน
    const SystemSettingsScreen(), // Index 2: ตั้งค่าระบบ (แทนที่ตั้งค่าเดิม)
    const UserProfileScreen(), // Index 3: ข้อมูล
    const Center(
      child: Text('Logging out...'),
    ), // Index 4: Placeholder สำหรับ Logout Action
  ];

  // Logic สำหรับ Logout (เหมือนเดิม)
  void _handleLogout() {
    final userState = Provider.of<UserState>(context, listen: false);
    userState.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _onItemTapped(int index) {
    // Index 4 คือ Logout
    if (index == 4) {
      _handleLogout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // <<< 1. ลบ AppBar ออกจาก MainScreen เพื่อให้ HomeScreen จัดการเอง >>>
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'แจ้งเตือน',
          ),
          // <<< 2. เปลี่ยน Index 2 เป็น 'ตั้งค่าระบบ' หรือลบ 'ตั้งค่า' ออกไปเลย >>>
          BottomNavigationBarItem(
            icon: Icon(Icons.tune), // ใช้ Icons.tune
            label: 'ตั้งค่าระบบ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'ข้อมูล'),
          // <<< 3. เพิ่มเมนู ออกจากระบบ (Index 4) >>>
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'ออกจากระบบ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
      ),
    );
  }
}
