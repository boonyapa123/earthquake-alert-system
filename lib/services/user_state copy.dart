// lib/services/user_state.dart

import 'package:flutter/material.dart';

// *** 1. สร้างคลาส UserModel เพื่อใช้เก็บข้อมูลผู้ใช้เป็นก้อนเดียว ***
class UserModel {
  final String email;
  final String name;
  final String phone;

  UserModel({required this.email, required this.name, required this.phone});
}

class UserState extends ChangeNotifier {
  // เปลี่ยนมาเก็บข้อมูลผู้ใช้ในรูปแบบของ UserModel
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  // *** 2. กำหนด Getter 'currentUser' (Fixes the red line error) ***
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Setter สำหรับการเข้าสู่ระบบ
  void setUser(String email, String name, String phone) {
    // สร้าง instance ของ UserModel
    _currentUser = UserModel(email: email, name: name, phone: phone);
    _isLoggedIn = true;
    notifyListeners();
  }

  // Setter สำหรับการออกจากระบบ
  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
