// Test script to send different sensor types to MQTT
const mqtt = require('mqtt');

// MQTT Configuration
const MQTT_BROKER = process.env.MQTT_BROKER_URL || 'mqtt://mqtt.uiot.cloud:1883';
const MQTT_USERNAME = process.env.MQTT_USERNAME || 'ethernet';
const MQTT_PASSWORD = process.env.MQTT_PASSWORD || 'ei8jZz87wx';

console.log('🔌 Connecting to MQTT Broker:', MQTT_BROKER);

const client = mqtt.connect(MQTT_BROKER, {
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD,
  clientId: `test_sensor_types_${Date.now()}`,
});

client.on('connect', () => {
  console.log('✅ Connected to MQTT Broker');
  console.log('📤 Sending test data for different sensor types...\n');
  
  sendTestData();
});

client.on('error', (error) => {
  console.error('❌ MQTT Error:', error);
  process.exit(1);
});

function sendTestData() {
  let count = 0;
  
  // Send data every 2 seconds
  const interval = setInterval(() => {
    count++;
    
    // 1. Earthquake Sensor (แผ่นดินไหว)
    const earthquakeData = {
      did: `EQC-TEST-${count.toString().padStart(3, '0')}`,
      magnitude: (Math.random() * 4 + 2).toFixed(2), // 2.0 - 6.0 Richter
      location: 'Bangkok, Thailand',
      lat: 13.7563 + (Math.random() * 0.1),
      lon: 100.5018 + (Math.random() * 0.1),
      ts: new Date().toISOString().replace('T', ' ').substring(0, 23),
      type: 'earthquake'
    };
    
    client.publish('eqnode.tarita/hub/eqdata/EQC-TEST', JSON.stringify(earthquakeData));
    console.log(`🌍 Earthquake: ${earthquakeData.magnitude} Richter - ${earthquakeData.did}`);
    
    // 2. Tsunami Sensor (คลื่นซึนามิ) - ส่งทุก 3 ครั้ง
    if (count % 3 === 0) {
      const tsunamiData = {
        did: `TSU-TEST-${count.toString().padStart(3, '0')}`,
        wave_height: (Math.random() * 2 + 0.3).toFixed(2), // 0.3 - 2.3 เมตร
        location: 'Phuket Coast, Thailand',
        lat: 7.8804 + (Math.random() * 0.1),
        lon: 98.3923 + (Math.random() * 0.1),
        ts: new Date().toISOString().replace('T', ' ').substring(0, 23),
        type: 'tsunami'
      };
      
      client.publish('eqnode.tarita/hub/tsunami/TSU-TEST', JSON.stringify(tsunamiData));
      console.log(`🌊 Tsunami: ${tsunamiData.wave_height} meters - ${tsunamiData.did}`);
    }
    
    // 3. Tilt Sensor (ความเอียงตึก) - ส่งทุก 4 ครั้ง
    if (count % 4 === 0) {
      const tiltData = {
        did: `TILT-TEST-${count.toString().padStart(3, '0')}`,
        angle: (Math.random() * 1.5 + 0.2).toFixed(2), // 0.2 - 1.7 องศา
        location: 'Building A, Bangkok',
        lat: 13.7563,
        lon: 100.5018,
        ts: new Date().toISOString().replace('T', ' ').substring(0, 23),
        type: 'tilt'
      };
      
      client.publish('eqnode.tarita/hub/tilt/TILT-TEST', JSON.stringify(tiltData));
      console.log(`📐 Tilt: ${tiltData.angle} degrees - ${tiltData.did}`);
    }
    
    console.log('---');
    
    // Stop after 20 messages
    if (count >= 20) {
      console.log('\n✅ Test completed! Sent 20 messages.');
      console.log('📊 Summary:');
      console.log(`   - Earthquake: 20 messages`);
      console.log(`   - Tsunami: ~7 messages`);
      console.log(`   - Tilt: ~5 messages`);
      clearInterval(interval);
      setTimeout(() => {
        client.end();
        process.exit(0);
      }, 1000);
    }
  }, 2000);
}
