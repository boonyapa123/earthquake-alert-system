// test-mqtt-connection.js - Test MQTT connection and listen for messages

const mqtt = require('mqtt');

// MQTT Configuration
const MQTT_HOST = 'mqtt://mqtt.uiot.cloud:1883';
const MQTT_USERNAME = 'ethernet';
const MQTT_PASSWORD = 'ei8jZz87wx';

console.log('🔌 Connecting to MQTT broker...');
console.log(`Host: ${MQTT_HOST}`);

const client = mqtt.connect(MQTT_HOST, {
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD,
  clientId: `test_listener_${Math.random().toString(16).slice(2, 10)}`,
});

client.on('connect', () => {
  console.log('✅ Connected to MQTT broker');
  console.log('📡 Subscribing to topics...\n');

  // Subscribe to all relevant topics
  const topics = [
    'eqnode.tarita/hub/#',
    'pmac/#',
    'TPO/#',
    'earthquake/#',
  ];

  topics.forEach(topic => {
    client.subscribe(topic, { qos: 1 }, (err) => {
      if (err) {
        console.error(`❌ Failed to subscribe to ${topic}:`, err);
      } else {
        console.log(`✅ Subscribed to: ${topic}`);
      }
    });
  });

  console.log('\n🎧 Listening for messages... (Press Ctrl+C to stop)\n');
});

client.on('message', (topic, message) => {
  try {
    const data = JSON.parse(message.toString());
    console.log(`📨 Message received on topic: ${topic}`);
    console.log('   Data:', JSON.stringify(data, null, 2));
    console.log('');
  } catch (error) {
    console.log(`📨 Message received on topic: ${topic}`);
    console.log('   Raw:', message.toString());
    console.log('');
  }
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
  console.log('\n⚠️  Stopping listener...');
  client.end();
  process.exit(0);
});
