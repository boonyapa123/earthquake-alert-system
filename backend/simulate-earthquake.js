// simulate-earthquake.js - จำลองข้อมูลแผ่นดินไหวส่งเข้า MQTT

const mqtt = require('mqtt');

// MQTT Configuration
const MQTT_HOST = 'mqtt://mqtt.uiot.cloud:1883';
const MQTT_USERNAME = 'ethernet';
const MQTT_PASSWORD = 'ei8jZz87wx';
const MQTT_TOPIC = 'eqnode.tarita/hub/eqdata'; // ✅ ใช้ topic ที่ตรงกับ broker จริง

console.log('🔌 Connecting to MQTT broker...');
console.log(`Host: ${MQTT_HOST}`);
console.log(`Topic: ${MQTT_TOPIC}`);

const client = mqtt.connect(MQTT_HOST, {
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD,
  clientId: `simulator_${Math.random().toString(16).slice(2, 10)}`,
});

client.on('connect', () => {
  console.log('✅ Connected to MQTT broker');
  console.log('📡 Sending earthquake simulation data...\n');

  // จำลองข้อมูลแผ่นดินไหว
  let count = 0;
  const interval = setInterval(() => {
    count++;
    
    // สุ่มขนาดแผ่นดินไหว 2.0 - 6.5 Richter
    const magnitude = (Math.random() * 4.5 + 2.0).toFixed(1);
    
    // สุ่มตำแหน่ง
    const locations = [
      { lat: 13.7563, lon: 100.5018, name: 'Bangkok' },
      { lat: 18.7883, lon: 98.9853, name: 'Chiang Mai' },
      { lat: 7.8804, lon: 98.3923, name: 'Phuket' },
      { lat: 12.9236, lon: 100.8825, name: 'Pattaya' },
      { lat: 16.4419, lon: 102.8360, name: 'Khon Kaen' },
    ];
    
    const location = locations[Math.floor(Math.random() * locations.length)];
    
    // สร้างข้อมูล
    const data = {
      deviceId: `EQC-SIM-${String(count).padStart(3, '0')}`,
      timestamp: new Date().toISOString(),
      magnitude: parseFloat(magnitude),
      latitude: location.lat + (Math.random() - 0.5) * 0.1,
      longitude: location.lon + (Math.random() - 0.5) * 0.1,
      depth: Math.floor(Math.random() * 50 + 5), // 5-55 km
      location: location.name,
      intensity: magnitude >= 5.0 ? 'high' : magnitude >= 3.0 ? 'medium' : 'low',
    };

    // ส่งข้อมูล
    client.publish(MQTT_TOPIC, JSON.stringify(data), { qos: 1 }, (err) => {
      if (err) {
        console.error('❌ Error publishing:', err);
      } else {
        console.log(`📊 [${count}] Sent earthquake data:`);
        console.log(`   Magnitude: ${data.magnitude} Richter`);
        console.log(`   Location: ${data.location}`);
        console.log(`   Intensity: ${data.intensity}`);
        console.log(`   Time: ${data.timestamp}\n`);
      }
    });

    // ส่ง 10 ครั้งแล้วหยุด
    if (count >= 10) {
      clearInterval(interval);
      setTimeout(() => {
        console.log('✅ Simulation completed. Sent 10 earthquake events.');
        client.end();
        process.exit(0);
      }, 1000);
    }
  }, 3000); // ส่งทุก 3 วินาที
});

client.on('error', (err) => {
  console.error('❌ MQTT Connection Error:', err.message);
  process.exit(1);
});

client.on('close', () => {
  console.log('🔌 Disconnected from MQTT broker');
});

// Handle Ctrl+C
process.on('SIGINT', () => {
  console.log('\n⚠️  Stopping simulation...');
  client.end();
  process.exit(0);
});
