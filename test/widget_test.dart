// Earthquake App Widget Tests
// ทดสอบ Widget และ UI ของแอพพลิเคชัน

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:earthquake_app_new/main.dart';
import 'package:earthquake_app_new/services/user_state.dart';
import 'package:earthquake_app_new/services/mqtt_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // สร้าง providers สำหรับการทดสอบ
      final userState = UserState();
      final mqttManager = MqttManager(userState: userState);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserState>.value(value: userState),
            ChangeNotifierProvider<MqttManager>.value(value: mqttManager),
          ],
          child: const MyApp(),
        ),
      );

      // ตรวจสอบว่าแอพสร้างสำเร็จ
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Login screen should be displayed initially', (WidgetTester tester) async {
      final userState = UserState();
      final mqttManager = MqttManager(userState: userState);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserState>.value(value: userState),
            ChangeNotifierProvider<MqttManager>.value(value: mqttManager),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // ตรวจสอบว่ามีหน้า Login
      expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    });
  });

  group('Configuration Tests', () {
    test('App should have valid configuration', () {
      // ทดสอบว่า config ถูกต้อง
      expect(true, isTrue); // Placeholder test
    });
  });
}
