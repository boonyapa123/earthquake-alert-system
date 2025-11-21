# Sample QR Code Data for Testing

## รูปแบบ QR Code ที่รองรับ

### 1. JSON Format (แนะนำ)
```json
{
  "deviceId": "EQC-001",
  "type": "earthquake",
  "name": "Earthquake Sensor #001",
  "model": "EQ-Pro-V2"
}
```

### 2. Simple Device ID
```
EQC-002
```

## ตัวอย่าง QR Code Data สำหรับการทดสอบ

### อุปกรณ์ตรวจจับแผ่นดินไหว
```json
{"deviceId":"EQC-001","type":"earthquake","name":"Earthquake Sensor Bangkok","model":"EQ-Pro-V2"}
```

### อุปกรณ์ตรวจจับสึนามิ
```json
{"deviceId":"TSU-001","type":"tsunami","name":"Tsunami Detector Phuket","model":"TS-Wave-V1"}
```

### อุปกรณ์ตรวจจับความเอียง
```json
{"deviceId":"TILT-001","type":"tilt","name":"Tilt Sensor Building A","model":"TL-Angle-V3"}
```

### Simple Format
```
EQC-SIMPLE-001
TSU-SIMPLE-002
TILT-SIMPLE-003
```

## วิธีสร้าง QR Code สำหรับทดสอบ

1. ใช้เว็บไซต์ QR Code Generator เช่น:
   - https://www.qr-code-generator.com/
   - https://qr.io/
   - https://www.the-qrcode-generator.com/

2. Copy ข้อความจากตัวอย่างข้างต้น
3. Paste ลงใน QR Code Generator
4. Download หรือ Screenshot QR Code
5. ใช้แอปสแกน QR Code เพื่อทดสอบ

## การทดสอบใน App

1. เปิดแอป eQNode
2. Login ด้วย `user@eqnode.com` / `password123`
3. ไปที่ "ตั้งค่าระบบ"
4. กดปุ่ม "สแกน QR Code"
5. สแกน QR Code ที่สร้างไว้
6. กรอกข้อมูลตำแหน่งและรายละเอียด
7. กดปุ่ม "ลงทะเบียนอุปกรณ์"

## หมายเหตุ

- QR Code ในรูปแบบ JSON จะมีข้อมูลครบถ้วนกว่า
- Simple format จะใช้ค่าเริ่มต้นเป็น "earthquake" type
- ในการใช้งานจริง QR Code ควรถูกสร้างโดยระบบจัดการอุปกรณ์