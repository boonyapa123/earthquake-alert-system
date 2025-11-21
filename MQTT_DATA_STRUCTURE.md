# 📊 โครงสร้างข้อมูล MQTT - แยกตามประเภทอุปกรณ์

## 🔍 สรุปจากการตรวจสอบ MQTT Broker

จากการตรวจสอบ MQTT broker พบว่ามีข้อมูล **3 ประเภทหลัก**:

---

## 1. 🌍 EQNODE (อุปกรณ์ตรวจจับแผ่นดินไหว)

### Topic Pattern:
```
eqnode.tarita/hub/1/{device_id}/eqdata/null
eqnode.tarita/hub/1/{device_id}/ping/{timestamp}
```

### A. ข้อมูลแผ่นดินไหว (eqdata)

**Topic**: `eqnode.tarita/hub/1/EQC-28562faa0b60/eqdata/null`

**ข้อมูลที่ส่งมา**:
```json
{
  "did": "EQC-28562faa0b60",        // Device ID
  "ts": "2025-11-21 00:31:27.716",  // Timestamp
  "lat": 13.903011,                  // Latitude (พิกัด)
  "lon": 100.533103,                 // Longitude (พิกัด)
  "alt": 30,                         // Altitude (ความสูง)
  "ax": 0.001056,                    // Acceleration X
  "ay": 0.014689,                    // Acceleration Y
  "az": -0.115818,                   // Acceleration Z
  "t1": 30.67,                       // Temperature
  "rms": 0.1168,                     // RMS (Root Mean Square)
  "pga": 0.1213,                     // PGA (Peak Ground Acceleration)
  "fq": 2.1,                         // Frequency
  "wid": 255,                        // Wave ID
  "wave": "Unknown"                  // Wave Type
}
```

**การคำนวณ Magnitude**:
- ใช้ค่า `pga` (Peak Ground Acceleration) เพื่อคำนวณขนาดแผ่นดินไหว
- สูตร: `magnitude = log10(pga * 1000) + offset`

### B. ข้อมูลสถานะอุปกรณ์ (ping)

**Topic**: `eqnode.tarita/hub/1/EQC-28562fa9d7a8/ping/20251121003147.023`

**ข้อมูลที่ส่งมา**:
```json
{
  "did": "EQC-28562fa9d7a8",
  "ts": "2025-11-21 00:31:47.023",
  "uptime": 58960,
  "lat": 13.903144,
  "lon": 100.532901,
  "alt": 8.8,
  "app": "EQNODE",
  "ver": "1.0.0",
  "fw": "2.0.5",
  "board": "eqnode2",
  "flags": 0,
  "hostname": "zephyr",
  "bootcnt": 12,
  "resetcnt": 5,
  "iface": "ppp0",
  "mac": "3735343231313038",
  "ip": "10.59.43.4",
  "rssi": -51,
  "imei": "862079075421108",
  "imsi": "901405122512015",
  "cmodel": "EG21",
  "cfw": "EG21GGBR07A11M1G"
}
```

---

## 2. 📡 PMAC (อุปกรณ์ PMAC)

### Topic Pattern:
```
pmac/{device_id}/status
```

**Topic**: `pmac/PMAC-0001/status`

**ข้อมูลที่ส่งมา**:
```json
{
  "device_id": "PMAC-0001",
  "status": "online",
  "timestamp": "2025-09-28 12:15:12",
  "uptime": 63528,
  "free_heap": 264712,
  "battery_v": 3.650000095,
  "wifi_rssi": -58,
  "sd_card": false
}
```

**ฟิลด์สำคัญ**:
- `device_id`: รหัสอุปกรณ์
- `status`: สถานะ (online/offline)
- `battery_v`: แรงดันแบตเตอรี่
- `wifi_rssi`: ความแรงสัญญาณ WiFi

---

## 3. ⚡ TPO (อุปกรณ์วัดไฟฟ้า)

### Topic Pattern:
```
TPO/{device_id}/data
```

**Topic**: `TPO/0001/data`

**ข้อมูลที่ส่งมา**:
```json
{
  "ts": "2025-11-21 00:31:30",
  "Va": 229,    // Voltage Phase A
  "Vb": 227,    // Voltage Phase B
  "Vc": 230,    // Voltage Phase C
  "Vdc": 722,   // DC Voltage
  "F": 50,      // Frequency
  "ILa": 2,     // Current Load Phase A
  "ILb": 2,     // Current Load Phase B
  "ILc": 2,     // Current Load Phase C
  "ILn": 4,     // Current Load Neutral
  "ICa": 1,     // Current Capacitor Phase A
  "ICb": 1,     // Current Capacitor Phase B
  "ICc": 1,     // Current Capacitor Phase C
  "ICn": 2,     // Current Capacitor Neutral
  "ISa": 1,     // Current Source Phase A
  "ISb": 1,     // Current Source Phase B
  "ISc": 1,     // Current Source Phase C
  "STT": 0.1,   // Status
  "AL1": 0,     // Alarm 1
  "AL2": 0,     // Alarm 2
  "PFa": 0.78,  // Power Factor Phase A
  "PFb": 0.56,  // Power Factor Phase B
  "PFc": 0.38,  // Power Factor Phase C
  "DPFa": 0.83, // Displacement Power Factor A
  "DPFb": 0.58, // Displacement Power Factor B
  "DPFc": 0.4,  // Displacement Power Factor C
  "THDa": 36,   // Total Harmonic Distortion A
  "THDb": 28,   // Total Harmonic Distortion B
  "THDc": 33,   // Total Harmonic Distortion C
  "Sa": 0.3,    // Apparent Power A
  "Sb": 0.3,    // Apparent Power B
  "Sc": 0.3,    // Apparent Power C
  "Pa": 0.3,    // Active Power A
  "Pb": 0.2,    // Active Power B
  "Pc": 0.1,    // Active Power C
  "Qa": 0.2,    // Reactive Power A
  "Qb": 0.2,    // Reactive Power B
  "Qc": 0.3     // Reactive Power C
}
```

---

## 📋 สรุปการแยกประเภทอุปกรณ์

### ตามประเภทการใช้งาน:

| ประเภท | Topic Pattern | จุดประสงค์ | ข้อมูลสำคัญ |
|--------|--------------|-----------|------------|
| **EQNODE** | `eqnode.tarita/hub/1/{did}/eqdata/*` | ตรวจจับแผ่นดินไหว | `pga`, `rms`, `lat`, `lon` |
| **EQNODE Ping** | `eqnode.tarita/hub/1/{did}/ping/*` | สถานะอุปกรณ์ | `uptime`, `rssi`, `ip` |
| **PMAC** | `pmac/{device_id}/status` | สถานะอุปกรณ์ PMAC | `status`, `battery_v`, `wifi_rssi` |
| **TPO** | `TPO/{device_id}/data` | วัดค่าไฟฟ้า | `Va`, `Vb`, `Vc`, `Pa`, `Pb`, `Pc` |

---

## 🔧 การแก้ไขแอพเพื่อรองรับข้อมูลจริง

### ปัญหาปัจจุบัน:
แอพคาดหวังข้อมูลในรูปแบบ:
```json
{
  "deviceId": "...",
  "magnitude": 4.5,
  "location": "Bangkok",
  "timestamp": "..."
}
```

แต่ข้อมูลจริงที่ได้รับคือ:
```json
{
  "did": "EQC-28562faa0b60",
  "pga": 0.1213,
  "lat": 13.903011,
  "lon": 100.533103,
  "ts": "2025-11-21 00:31:27.716"
}
```

### วิธีแก้ไข:

1. **แปลง field names**:
   - `did` → `deviceId`
   - `pga` → คำนวณเป็น `magnitude`
   - `lat`, `lon` → แปลงเป็น `location` (ใช้ reverse geocoding)
   - `ts` → `timestamp`

2. **คำนวณ magnitude จาก PGA**:
   ```dart
   double calculateMagnitude(double pga) {
     // PGA in g (gravity)
     // Magnitude = log10(PGA * 1000) + offset
     return log10(pga * 1000) + 3.0;
   }
   ```

3. **แยกประเภทข้อมูล**:
   - ถ้า topic มี `/eqdata/` → ข้อมูลแผ่นดินไหว
   - ถ้า topic มี `/ping/` → ข้อมูลสถานะ
   - ถ้า topic มี `/status` → ข้อมูลสถานะอุปกรณ์

---

## 🎯 ข้อเสนอแนะ

### สำหรับแอพ:

1. **แสดงข้อมูลแยกตามประเภท**:
   - แท็บ "แผ่นดินไหว" → แสดงเฉพาะ EQNODE eqdata
   - แท็บ "อุปกรณ์" → แสดงสถานะ PMAC, TPO, EQNODE ping
   - แท็บ "ไฟฟ้า" → แสดงข้อมูล TPO

2. **กรองข้อมูลที่สำคัญ**:
   - แสดงเฉพาะ PGA > threshold
   - แสดงเฉพาะอุปกรณ์ที่ online
   - แสดงเฉพาะข้อมูลใหม่ (ภายใน 24 ชม.)

3. **แสดงตำแหน่งบนแผนที่**:
   - ใช้ `lat`, `lon` จาก EQNODE
   - แสดง marker บนแผนที่
   - สีของ marker ตามความรุนแรง

---

## 📝 ตัวอย่างการใช้งาน

### ดึงข้อมูลแผ่นดินไหว:
```dart
if (topic.contains('/eqdata/')) {
  final did = data['did'];
  final pga = data['pga'];
  final magnitude = calculateMagnitude(pga);
  final lat = data['lat'];
  final lon = data['lon'];
  final timestamp = data['ts'];
  
  // แสดงในแอพ
  showEarthquakeData(did, magnitude, lat, lon, timestamp);
}
```

### ดึงสถานะอุปกรณ์:
```dart
if (topic.contains('/ping/') || topic.contains('/status')) {
  final deviceId = data['did'] ?? data['device_id'];
  final status = data['status'] ?? 'online';
  final rssi = data['rssi'] ?? data['wifi_rssi'];
  
  // อัพเดทสถานะ
  updateDeviceStatus(deviceId, status, rssi);
}
```

---

**สรุป**: ข้อมูล MQTT มี 3 ประเภทหลัก (EQNODE, PMAC, TPO) แต่ละประเภทมีโครงสร้างข้อมูลต่างกัน ต้องแก้ไขแอพให้รองรับการ parse ข้อมูลแต่ละประเภทถูกต้อง
