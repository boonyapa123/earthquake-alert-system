// lib/screens/terms_of_service_screen.dart

import 'package:flutter/material.dart';
import '../config/app_config.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ข้อกำหนดการใช้บริการ',
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
              'ข้อกำหนดการใช้บริการ',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'มีผลบังคับใช้: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              '1. การยอมรับข้อกำหนด',
              'การใช้แอปพลิเคชัน eQNode ถือว่าคุณยอมรับข้อกำหนดและเงื่อนไขทั้งหมดในเอกสารนี้\n\n'
              'หากคุณไม่ยอมรับข้อกำหนดใดๆ กรุณาหยุดใช้แอปทันที',
            ),
            
            _buildSection(
              context,
              '2. คำอธิบายบริการ',
              'eQNode เป็นแอปพลิเคชันแจ้งเตือนแผ่นดินไหวที่:\n\n'
              '• รับข้อมูลจากอุปกรณ์เซ็นเซอร์แบบ Real-time\n'
              '• ส่งการแจ้งเตือนเมื่อตรวจพบแผ่นดินไหว\n'
              '• จัดเก็บประวัติเหตุการณ์\n'
              '• ให้บริการจัดการอุปกรณ์ IoT\n\n'
              'บริการนี้มีวัตถุประสงค์เพื่อความปลอดภัยและการเตือนภัย',
            ),
            
            _buildSection(
              context,
              '3. การสมัครสมาชิกและบัญชีผู้ใช้',
              'การสมัครใช้บริการ:\n\n'
              '• ต้องให้ข้อมูลที่ถูกต้องและครบถ้วน\n'
              '• ต้องมีอายุ 18 ปีขึ้นไป หรือได้รับอนุญาตจากผู้ปกครอง\n'
              '• รับผิดชอบรักษาความปลอดภัยของรหัสผ่าน\n'
              '• แจ้งเราทันทีหากพบการใช้งานที่ผิดปกติ\n'
              '• หนึ่งอีเมลสามารถสมัครได้เพียงบัญชีเดียว',
            ),
            
            _buildSection(
              context,
              '4. การใช้งานที่อนุญาต',
              'คุณสามารถใช้แอปเพื่อ:\n\n'
              '• รับการแจ้งเตือนแผ่นดินไหว\n'
              '• จัดการอุปกรณ์เซ็นเซอร์ส่วนตัว\n'
              '• ดูประวัติเหตุการณ์\n'
              '• ตั้งค่าการแจ้งเตือน\n'
              '• แชร์ข้อมูลเพื่อความปลอดภัยสาธารณะ',
            ),
            
            _buildSection(
              context,
              '5. การใช้งานที่ห้าม',
              'ห้ามใช้แอปเพื่อ:\n\n'
              '• กิจกรรมที่ผิดกฎหมาย\n'
              '• ส่งข้อมูลเท็จหรือทำให้เกิดความตื่นตระหนก\n'
              '• รบกวนหรือโจมตีระบบ\n'
              '• คัดลอกหรือแจกจ่ายแอปโดยไม่ได้รับอนุญาต\n'
              '• ใช้เพื่อการค้าโดยไม่ได้รับอนุญาต\n'
              '• แฮกหรือเข้าถึงข้อมูลของผู้อื่น',
            ),
            
            _buildSection(
              context,
              '6. ความรับผิดชอบของผู้ใช้',
              'ผู้ใช้มีหน้าที่:\n\n'
              '• ใช้แอปด้วยความระมัดระวังและรับผิดชอบ\n'
              '• ตรวจสอบความถูกต้องของข้อมูลก่อนดำเนินการ\n'
              '• ไม่พึ่งพาแอปเป็นแหล่งข้อมูลเดียว\n'
              '• ติดตามข่าวสารจากหน่วยงานราชการ\n'
              '• รายงานปัญหาหรือข้อผิดพลาดที่พบ',
            ),
            
            _buildSection(
              context,
              '7. ข้อจำกัดความรับผิดชอบ',
              'บริษัทไม่รับผิดชอบต่อ:\n\n'
              '• ความเสียหายจากการใช้หรือไม่สามารถใช้แอป\n'
              '• ความไม่ถูกต้องของข้อมูล\n'
              '• การหยุดชะงักของบริการ\n'
              '• การสูญหายของข้อมูล\n'
              '• ความเสียหายทางอ้อมหรือพิเศษ\n\n'
              'แอปเป็นเครื่องมือช่วยเหลือ ไม่ใช่ระบบเตือนภัยหลัก',
            ),
            
            _buildSection(
              context,
              '8. ทรัพย์สินทางปัญญา',
              'สิทธิในแอปและเนื้อหา:\n\n'
              '• แอป eQNode เป็นทรัพย์สินของบริษัท\n'
              '• ห้ามคัดลอก แก้ไข หรือแจกจ่าย\n'
              '• โลโก้และเครื่องหมายการค้าเป็นของบริษัท\n'
              '• ข้อมูลที่ผู้ใช้ป้อนยังคงเป็นของผู้ใช้\n'
              '• บริษัทมีสิทธิใช้ข้อมูลเพื่อปรับปรุงบริการ',
            ),
            
            _buildSection(
              context,
              '9. การยกเลิกบริการ',
              'บริษัทสงวนสิทธิ์:\n\n'
              '• ยกเลิกบัญชีที่ละเมิดข้อกำหนด\n'
              '• หยุดให้บริการชั่วคราวเพื่อบำรุงรักษา\n'
              '• เปลี่ยนแปลงหรือยกเลิกฟีเจอร์\n'
              '• ปรับปรุงข้อกำหนดการใช้งาน\n\n'
              'ผู้ใช้สามารถลบบัญชีได้ตลอดเวลา',
            ),
            
            _buildSection(
              context,
              '10. การเปลี่ยนแปลงข้อกำหนด',
              'บริษัทอาจปรับปรุงข้อกำหนดนี้เป็นครั้งคราว:\n\n'
              '• การเปลี่ยนแปลงจะแจ้งผ่านแอป\n'
              '• การใช้งานต่อไปถือว่ายอมรับ\n'
              '• หากไม่ยอมรับ กรุณาหยุดใช้แอป\n'
              '• ข้อกำหนดใหม่มีผลทันทีเมื่อประกาศ',
            ),
            
            _buildSection(
              context,
              '11. กฎหมายที่ใช้บังคับ',
              'ข้อกำหนดนี้อยู่ภายใต้:\n\n'
              '• กฎหมายไทย\n'
              '• ศาลไทยมีเขตอำนาจพิจารณาข้อพิพาท\n'
              '• ภาษาไทยเป็นภาษาหลักในการตีความ\n'
              '• หากข้อใดขัดกฎหมาย ข้ออื่นยังคงใช้ได้',
            ),
            
            _buildSection(
              context,
              '12. การติดต่อ',
              'สำหรับคำถามเกี่ยวกับข้อกำหนดนี้:\n\n'
              'อีเมล: legal@eqnode.com\n'
              'โทรศัพท์: 02-xxx-xxxx\n'
              'ที่อยู่: กรุงเทพมหานคร ประเทศไทย\n\n'
              'เวลาทำการ: จันทร์-ศุกร์ 9:00-17:00 น.',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'คำเตือนสำคัญ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'แอป eQNode เป็นเครื่องมือช่วยเหลือเท่านั้น ไม่ใช่ระบบเตือนภัยหลักของรัฐ กรุณาติดตามข้อมูลจากหน่วยงานราชการเป็นหลัก',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                'เวอร์ชัน ${AppConfig.appVersion} | ${AppConfig.environment.name}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
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