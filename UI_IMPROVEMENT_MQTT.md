# 🎨 ปรับปรุง UI หน้า MQTT Real-time

## ✨ การปรับปรุง

### ก่อนปรับปรุง:
- แสดงข้อมูลทั้งหมดในรายการเดียว
- ไม่มีการจัดกลุ่ม
- ยากต่อการมองหาข้อมูลสำคัญ

### หลังปรับปรุง:
- ✅ **จัดกลุ่มตามความรุนแรง** (3 ระดับ)
- ✅ **แสดงจำนวนในแต่ละกลุ่ม**
- ✅ **ใช้สีแยกประเภท**
- ✅ **แสดงประเภทอุปกรณ์** (EQNODE, PMAC, TPO)
- ✅ **ออกแบบ Card ใหม่** ให้สวยงามและอ่านง่าย

---

## 📊 การจัดกลุ่มข้อมูล

### 1. 🚨 แผ่นดินไหวรุนแรงมาก (CRITICAL)
**เงื่อนไข**: Magnitude >= 6.0 Richter

**สี**: 
- Card: แดงอ่อน (Red.shade50)
- Icon: แดงเข้ม (Red.shade700)
- Border: แดงเข้ม 2px
- Badge: "CRITICAL"

**ไอคอน**: ⚠️ warning_amber_rounded

**ตัวอย่าง**:
```
🚨 แผ่นดินไหวรุนแรงมาก [3]
━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────────┐
│ ⚠️  [EQNODE] EQC-SIM-010│
│     17:36:15            │ [CRITICAL]
│                         │
│ 🎯 Magnitude: 6.40 Richter
│ 📍 Pattaya              │
└─────────────────────────┘
```

---

### 2. ⚠️ แผ่นดินไหวรุนแรง (HIGH)
**เงื่อนไข**: 3.0 <= Magnitude < 6.0 Richter

**สี**:
- Card: ส้มอ่อน (Orange.shade50)
- Icon: ส้มเข้ม (Orange.shade700)
- Badge: "HIGH"

**ไอคอน**: ⚠️ warning

**ตัวอย่าง**:
```
⚠️ แผ่นดินไหวรุนแรง [5]
━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────────┐
│ ⚠️  [EQNODE] EQC-SIM-001│
│     17:35:48            │ [HIGH]
│                         │
│ 🎯 Magnitude: 5.30 Richter
│ 📍 Khon Kaen            │
└─────────────────────────┘
```

---

### 3. 🟢 แผ่นดินไหวปกติ (NORMAL)
**เงื่อนไข**: Magnitude < 3.0 Richter

**สี**:
- Card: ขาว (White)
- Icon: เขียวเข้ม (Green.shade700)
- Badge: "NORMAL"

**ไอคอน**: 📊 show_chart

**ตัวอย่าง**:
```
🟢 แผ่นดินไหวปกติ [2]
━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────────┐
│ 📊 [EQNODE] EQC-28562... │
│     00:31:27            │ [NORMAL]
│                         │
│ 🎯 Magnitude: 0.12 Richter
│ 📍 Lat: 13.9030, Lon: 100.5331
└─────────────────────────┘
```

---

## 🎨 รายละเอียด UI Components

### Section Header
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color.withOpacity(0.3)),
  ),
  child: Row(
    children: [
      Text('🚨 แผ่นดินไหวรุนแรงมาก'),
      Spacer(),
      Badge('[3]'),  // จำนวนรายการ
    ],
  ),
)
```

### Card Layout
```
┌─────────────────────────────────────┐
│ [Icon] [Type Badge] Device ID [Badge]│
│        Timestamp                     │
│                                      │
│ 🎯 Magnitude: X.XX Richter          │
│ 📍 Location                          │
└─────────────────────────────────────┘
```

### Device Type Badge
แสดงประเภทอุปกรณ์ด้วยสีฟ้า:
- **EQNODE** - อุปกรณ์ตรวจจับแผ่นดินไหว
- **PMAC** - อุปกรณ์ PMAC
- **TPO** - อุปกรณ์ TPO
- **Unknown** - ไม่ทราบประเภท

---

## 📱 ตัวอย่างหน้าจอ

### เมื่อมีข้อมูลหลายระดับ:

```
┌─────────────────────────────────────┐
│ MQTT Status: CONNECTED              │
│ Total messages: 10                  │
└─────────────────────────────────────┘

Real-time MQTT Data

🚨 แผ่นดินไหวรุนแรงมาก [2]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Card 1: 6.4 Richter]
[Card 2: 6.2 Richter]

⚠️ แผ่นดินไหวรุนแรง [5]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Card 1: 5.3 Richter]
[Card 2: 4.5 Richter]
[Card 3: 3.9 Richter]
[Card 4: 3.2 Richter]
[Card 5: 3.0 Richter]

🟢 แผ่นดินไหวปกติ [3]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Card 1: 2.8 Richter]
[Card 2: 2.5 Richter]
[Card 3: 0.12 Richter]
```

### เมื่อไม่มีข้อมูล:

```
┌─────────────────────────────────────┐
│ MQTT Status: CONNECTED              │
│ Total messages: 0                   │
└─────────────────────────────────────┘

Real-time MQTT Data

        📡
        
   ไม่มีข้อมูล MQTT
   
รอข้อมูลจาก MQTT Broker...
```

---

## 🎯 ข้อดีของการปรับปรุง

### 1. ง่ายต่อการมองเห็น
- จัดกลุ่มชัดเจน
- ใช้สีแยกประเภท
- แสดงจำนวนในแต่ละกลุ่ม

### 2. เน้นข้อมูลสำคัญ
- แผ่นดินไหวรุนแรงแสดงด้านบน
- ใช้สีแดงและ border เด่นชัด
- Badge "CRITICAL" เตือนทันที

### 3. แสดงข้อมูลครบถ้วน
- ประเภทอุปกรณ์ (Device Type)
- Device ID
- Magnitude
- Location
- Timestamp
- Severity Level

### 4. ออกแบบสวยงาม
- Card มีเงา (elevation)
- Border radius มน
- Spacing เหมาะสม
- ไอคอนชัดเจน

---

## 🔧 การทำงาน

### การจัดกลุ่ม:
```dart
// แยกข้อมูลตามความรุนแรง
final criticalLogs = logs.where((log) => log.magnitude >= 6.0).toList();
final highLogs = logs.where((log) => log.magnitude >= 3.0 && log.magnitude < 6.0).toList();
final normalLogs = logs.where((log) => log.magnitude < 3.0).toList();
```

### การแสดงผล:
```dart
Column(
  children: [
    if (criticalLogs.isNotEmpty) ...[
      _buildSectionHeader('🚨 แผ่นดินไหวรุนแรงมาก', criticalLogs.length),
      ...criticalLogs.map((log) => _buildMqttLogCard(log, 'critical')),
    ],
    if (highLogs.isNotEmpty) ...[
      _buildSectionHeader('⚠️ แผ่นดินไหวรุนแรง', highLogs.length),
      ...highLogs.map((log) => _buildMqttLogCard(log, 'high')),
    ],
    if (normalLogs.isNotEmpty) ...[
      _buildSectionHeader('🟢 แผ่นดินไหวปกติ', normalLogs.length),
      ...normalLogs.map((log) => _buildMqttLogCard(log, 'normal')),
    ],
  ],
)
```

---

## 📋 ไฟล์ที่แก้ไข

- ✅ `lib/screens/home_screen.dart`
  - แก้ไข `_buildMqttDevicesList()`
  - เพิ่ม `_buildSectionHeader()`
  - เพิ่ม `_buildMqttLogCard()`

---

## 🧪 การทดสอบ

### 1. Rebuild แอพ
```bash
flutter clean
flutter pub get
flutter run
```

### 2. ส่งข้อมูลทดสอบ
```bash
cd backend
node simulate-earthquake.js
```

### 3. ตรวจสอบ
- ✅ ข้อมูลจัดกลุ่มถูกต้อง?
- ✅ สีแสดงถูกต้อง?
- ✅ จำนวนในแต่ละกลุ่มถูกต้อง?
- ✅ Card แสดงสวยงาม?
- ✅ ข้อมูลครบถ้วน?

---

## 🎨 สรุป

### ก่อน:
- รายการเดียว ไม่มีการจัดกลุ่ม
- ยากต่อการหาข้อมูลสำคัญ

### หลัง:
- ✅ จัดกลุ่ม 3 ระดับ (Critical, High, Normal)
- ✅ ใช้สีแยกประเภท
- ✅ แสดงจำนวนในแต่ละกลุ่ม
- ✅ Card สวยงาม อ่านง่าย
- ✅ แสดงประเภทอุปกรณ์
- ✅ เน้นข้อมูลสำคัญ

---

**สถานะ**: ✅ เสร็จสมบูรณ์ - Rebuild แอพเพื่อดูผลลัพธ์
