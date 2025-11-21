// Earthquake Data Calculator
// คำนวณขนาดแผ่นดินไหวจากข้อมูล sensor

/**
 * คำนวณ Magnitude จาก PGA (Peak Ground Acceleration)
 * สูตร: M = log10(PGA) + 3.0
 * 
 * @param {number} pga - Peak Ground Acceleration (g)
 * @returns {number} - Magnitude (Richter scale)
 */
function calculateMagnitudeFromPGA(pga) {
  if (!pga || pga <= 0) return 0;
  
  // แปลง PGA เป็น Magnitude
  // PGA มาในหน่วย g (gravity)
  // สูตรประมาณการ: M ≈ log10(PGA * 100) + 3.0
  const magnitude = Math.log10(pga * 100) + 3.0;
  
  // จำกัดค่าระหว่าง 0-10
  return Math.max(0, Math.min(10, magnitude));
}

/**
 * คำนวณ Magnitude จาก RMS (Root Mean Square)
 * 
 * @param {number} rms - Root Mean Square acceleration
 * @returns {number} - Magnitude (Richter scale)
 */
function calculateMagnitudeFromRMS(rms) {
  if (!rms || rms <= 0) return 0;
  
  const magnitude = Math.log10(rms * 100) + 2.5;
  return Math.max(0, Math.min(10, magnitude));
}

/**
 * คำนวณ Magnitude จาก Acceleration (ax, ay, az)
 * 
 * @param {number} ax - Acceleration X
 * @param {number} ay - Acceleration Y
 * @param {number} az - Acceleration Z
 * @returns {number} - Magnitude (Richter scale)
 */
function calculateMagnitudeFromAcceleration(ax, ay, az) {
  // คำนวณ resultant acceleration
  const resultant = Math.sqrt(ax * ax + ay * ay + az * az);
  
  // ลบ gravity (1g) ออก
  const netAcceleration = Math.abs(resultant - 1.0);
  
  if (netAcceleration < 0.001) return 0;
  
  const magnitude = Math.log10(netAcceleration * 100) + 2.0;
  return Math.max(0, Math.min(10, magnitude));
}

/**
 * กำหนดระดับความรุนแรง
 * 
 * @param {number} magnitude - Magnitude (Richter scale)
 * @returns {string} - Severity level
 */
function getSeverityLevel(magnitude) {
  if (magnitude < 2.0) return 'micro';
  if (magnitude < 3.0) return 'minor';
  if (magnitude < 4.0) return 'light';
  if (magnitude < 5.0) return 'moderate';
  if (magnitude < 6.0) return 'strong';
  if (magnitude < 7.0) return 'major';
  return 'great';
}

/**
 * กำหนดสีตามความรุนแรง
 * 
 * @param {number} magnitude - Magnitude (Richter scale)
 * @returns {string} - Color code
 */
function getSeverityColor(magnitude) {
  if (magnitude < 2.0) return '#4CAF50'; // Green
  if (magnitude < 3.0) return '#8BC34A'; // Light Green
  if (magnitude < 4.0) return '#FFC107'; // Amber
  if (magnitude < 5.0) return '#FF9800'; // Orange
  if (magnitude < 6.0) return '#FF5722'; // Deep Orange
  if (magnitude < 7.0) return '#F44336'; // Red
  return '#B71C1C'; // Dark Red
}

/**
 * ตรวจสอบว่าควรส่ง Alert หรือไม่
 * 
 * @param {number} magnitude - Magnitude (Richter scale)
 * @returns {boolean} - Should send alert
 */
function shouldSendAlert(magnitude) {
  return magnitude >= 3.0; // ส่ง alert เมื่อ >= 3.0
}

/**
 * แปลงข้อมูลจาก MQTT เป็นรูปแบบมาตรฐาน
 * 
 * @param {object} mqttData - Raw MQTT data
 * @returns {object} - Processed earthquake data
 */
function processEarthquakeData(mqttData) {
  const {
    did,
    ts,
    lat,
    lon,
    alt,
    ax,
    ay,
    az,
    t1,
    rms,
    pga,
    fq,
    wid,
    wave
  } = mqttData;

  // คำนวณ magnitude จากหลายวิธี แล้วเลือกค่าที่สูงสุด
  const magnitudeFromPGA = calculateMagnitudeFromPGA(pga);
  const magnitudeFromRMS = calculateMagnitudeFromRMS(rms);
  const magnitudeFromAccel = calculateMagnitudeFromAcceleration(ax, ay, az);
  
  // ใช้ค่าที่สูงสุด
  const magnitude = Math.max(magnitudeFromPGA, magnitudeFromRMS, magnitudeFromAccel);
  
  // ปัดเศษทศนิยม 2 ตำแหน่ง
  const roundedMagnitude = Math.round(magnitude * 100) / 100;

  return {
    deviceId: did,
    timestamp: ts,
    location: {
      latitude: lat,
      longitude: lon,
      altitude: alt,
    },
    magnitude: roundedMagnitude,
    severity: getSeverityLevel(roundedMagnitude),
    color: getSeverityColor(roundedMagnitude),
    shouldAlert: shouldSendAlert(roundedMagnitude),
    sensorData: {
      acceleration: {
        x: ax,
        y: ay,
        z: az,
      },
      temperature: t1,
      rms: rms,
      pga: pga,
      frequency: fq,
      waveId: wid,
      waveType: wave,
    },
    calculationMethod: {
      fromPGA: magnitudeFromPGA.toFixed(2),
      fromRMS: magnitudeFromRMS.toFixed(2),
      fromAcceleration: magnitudeFromAccel.toFixed(2),
      selected: 'max',
    },
  };
}

/**
 * สร้างข้อความแจ้งเตือน
 * 
 * @param {object} earthquakeData - Processed earthquake data
 * @returns {object} - Notification message
 */
function createNotificationMessage(earthquakeData) {
  const { magnitude, severity, deviceId, location } = earthquakeData;
  
  let title = '';
  let body = '';
  let priority = 'normal';

  if (magnitude >= 6.0) {
    title = '🚨 แผ่นดินไหวรุนแรงมาก!';
    body = `ขนาด ${magnitude} ริกเตอร์ จากเซ็นเซอร์ ${deviceId}`;
    priority = 'high';
  } else if (magnitude >= 5.0) {
    title = '⚠️ แผ่นดินไหวรุนแรง';
    body = `ขนาด ${magnitude} ริกเตอร์ จากเซ็นเซอร์ ${deviceId}`;
    priority = 'high';
  } else if (magnitude >= 4.0) {
    title = '⚠️ แผ่นดินไหวปานกลาง';
    body = `ขนาด ${magnitude} ริกเตอร์ จากเซ็นเซอร์ ${deviceId}`;
    priority = 'normal';
  } else if (magnitude >= 3.0) {
    title = 'ℹ️ ตรวจพบแผ่นดินไหว';
    body = `ขนาด ${magnitude} ริกเตอร์ จากเซ็นเซอร์ ${deviceId}`;
    priority = 'normal';
  }

  return {
    title,
    body,
    priority,
    data: {
      type: 'earthquake_alert',
      magnitude: magnitude.toString(),
      severity,
      deviceId,
      latitude: location.latitude.toString(),
      longitude: location.longitude.toString(),
      timestamp: earthquakeData.timestamp,
    },
  };
}

module.exports = {
  calculateMagnitudeFromPGA,
  calculateMagnitudeFromRMS,
  calculateMagnitudeFromAcceleration,
  getSeverityLevel,
  getSeverityColor,
  shouldSendAlert,
  processEarthquakeData,
  createNotificationMessage,
};
