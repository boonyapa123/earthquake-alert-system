// lib/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import '../config/app_config.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'นโยบายความเป็นส่วนตัว',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'นโยบายความเป็นส่วนตัว',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'อัปเดตล่าสุด: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'การเก็บรวบรวมข้อมูล',
              'แอปพลิเคชัน eQNode เก็บรวบรวมข้อมูลดังต่อไปนี้:\n\n'
              '• ข้อมูลส่วนบุคคล: ชื่อ, อีเมล, หมายเลขโทรศัพท์\n'
              '• ข้อมูลตำแหน่ง: พิกัด GPS สำหรับการติดตั้งอุปกรณ์\n'
              '• ข้อมูลอุปกรณ์: รหัสอุปกรณ์, ประเภทอุปกรณ์, สถานะการทำงาน\n'
              '• ข้อมูลการใช้งาน: บันทึกการเข้าใช้แอป, การตั้งค่า\n'
              '• ข้อมูลเซ็นเซอร์: ข้อมูลแผ่นดินไหวจากอุปกรณ์ IoT',
            ),
            
            _buildSection(
              context,
              'การใช้ข้อมูล',
              'เราใช้ข้อมูลที่เก็บรวบรวมเพื่อ:\n\n'
              '• ให้บริการแจ้งเตือนแผ่นดินไหวแบบ Real-time\n'
              '• จัดการบัญชีผู้ใช้และอุปกรณ์\n'
              '• ปรับปรุงคุณภาพการบริการ\n'
              '• วิเคราะห์และพัฒนาระบบ\n'
              '• ส่งการแจ้งเตือนความปลอดภัย',
            ),
            
            _buildSection(
              context,
              'การแชร์ข้อมูล',
              'เราไม่แชร์ข้อมูลส่วนบุคคลของคุณกับบุคคลที่สาม ยกเว้น:\n\n'
              '• หน่วยงานราชการในกรณีฉุกเฉิน\n'
              '• ผู้ให้บริการคลาวด์ที่มีข้อตกลงรักษาความลับ\n'
              '• กรณีที่กฎหมายกำหนด\n\n'
              'ข้อมูลแผ่นดินไหวอาจถูกแชร์เพื่อประโยชน์ทางวิทยาศาสตร์ โดยไม่เปิดเผยข้อมูลส่วนบุคคล',
            ),
            
            _buildSection(
              context,
              'ความปลอดภัยของข้อมูล',
              'เราใช้มาตรการรักษาความปลอดภัยดังนี้:\n\n'
              '• เข้ารหัสข้อมูลทั้งในการส่งและจัดเก็บ\n'
              '• ระบบยืนยันตัวตนแบบ JWT Token\n'
              '• การควบคุมการเข้าถึงข้อมูล\n'
              '• การสำรองข้อมูลอย่างสม่ำเสมอ\n'
              '• การตรวจสอบความปลอดภัยเป็นประจำ',
            ),
            
            _buildSection(
              context,
              'สิทธิของผู้ใช้',
              'คุณมีสิทธิในการ:\n\n'
              '• เข้าถึงและแก้ไขข้อมูลส่วนบุคคล\n'
              '• ลบบัญชีและข้อมูลทั้งหมด\n'
              '• ปฏิเสธการเก็บข้อมูลบางประเภท\n'
              '• ขอสำเนาข้อมูลส่วนบุคคล\n'
              '• ร้องเรียนการใช้ข้อมูลที่ไม่เหมาะสม',
            ),
            
            _buildSection(
              context,
              'การใช้คุกกี้และเทคโนโลยีติดตาม',
              'แอปใช้เทคโนโลยีดังนี้:\n\n'
              '• Local Storage สำหรับการตั้งค่า\n'
              '• Push Notification Tokens\n'
              '• Analytics เพื่อปรับปรุงบริการ\n'
              '• Crash Reporting เพื่อแก้ไขปัญหา\n\n'
              'คุณสามารถปิดการใช้งานได้ในการตั้งค่าแอป',
            ),
            
            _buildSection(
              context,
              'การเปลี่ยนแปลงนโยบาย',
              'เราอาจปรับปรุงนโยบายนี้เป็นครั้งคราว การเปลี่ยนแปลงที่สำคัญจะแจ้งให้ทราบผ่านแอปหรืออีเมล\n\n'
              'การใช้แอปต่อไปถือว่าคุณยอมรับนโยบายที่ปรับปรุงแล้ว',
            ),
            
            _buildSection(
              context,
              'ติดต่อเรา',
              'หากมีคำถามเกี่ยวกับนโยบายนี้ กรุณาติดต่อ:\n\n'
              'อีเมล: privacy@eqnode.com\n'
              'โทรศัพท์: 02-xxx-xxxx\n'
              'ที่อยู่: กรุงเทพมหานคร ประเทศไทย\n\n'
              'เวอร์ชันแอป: ${AppConfig.appVersion}\n'
              'สภาพแวดล้อม: ${AppConfig.environment.name}',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'หมายเหตุสำคัญ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'นโยบายนี้ใช้สำหรับแอป eQNode เท่านั้น ไม่รวมถึงเว็บไซต์หรือบริการอื่นที่เชื่อมโยง',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}