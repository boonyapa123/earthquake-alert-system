// mqtt-data-inspector.js - ตรวจสอบโครงสร้างข้อมูล MQTT

const mqtt = require('mqtt');

// MQTT Configuration
const MQTT_HOST = 'mqtt://mqtt.uiot.cloud:1883';
const MQTT_USERNAME = 'ethernet';
const MQTT_PASSWORD = 'ei8jZz87wx';

console.log('🔍 MQTT Data Inspector');
console.log('======================\n');
console.log(`Connecting to: ${MQTT_HOST}`);
console.log('Username:', MQTT_USERNAME);
console.log('\n');

const client = mqtt.connect(MQTT_HOST, {
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD,
  clientId: `inspector_${Math.random().toString(16).slice(2, 10)}`,
});

// เก็บสถิติ
const topicStats = {};
const deviceTypes = new Set();
const sampleData = {};

client.on('connect', () => {
  console.log('✅ Connected to MQTT broker\n');
  console.log('📡 Subscribing to all topics...\n');

  // Subscribe to all topics
  const topics = [
    'eqnode.tarita/hub/#',
    'pmac/#',
    'TPO/#',
    'earthquake/#',
    'eqnode.cnx/hub/#',
    'pems/#',
  ];

  topics.forEach(topic => {
    client.subscribe(topic, { qos: 1 }, (err) => {
      if (!err) {
        console.log(`✅ Subscribed to: ${topic}`);
      }
    });
  });

  console.log('\n🎧 Listening for messages...\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
});

client.on('message', (topic, message) => {
  try {
    // นับสถิติ topic
    if (!topicStats[topic]) {
      topicStats[topic] = 0;
    }
    topicStats[topic]++;

    // แยกประเภท device จาก topic
    const topicParts = topic.split('/');
    const deviceType = topicParts[0];
    deviceTypes.add(deviceType);

    // Parse ข้อมูล
    let data;
    try {
      data = JSON.parse(message.toString());
    } catch (e) {
      data = message.toString();
    }

    // เก็บตัวอย่างข้อมูลแรกของแต่ละ topic
    if (!sampleData[topic]) {
      sampleData[topic] = data;
      
      console.log(`📨 NEW TOPIC: ${topic}`);
      console.log(`   Device Type: ${deviceType}`);
      console.log(`   Data Type: ${typeof data}`);
      
      if (typeof data === 'object') {
        console.log(`   Fields: ${Object.keys(data).join(', ')}`);
        console.log(`   Sample Data:`);
        console.log(JSON.stringify(data, null, 2).split('\n').map(line => `      ${line}`).join('\n'));
      } else {
        console.log(`   Raw Data: ${data}`);
      }
      console.log('');
    }

    // แสดงสถิติทุก 10 วินาที
    if (Object.values(topicStats).reduce((a, b) => a + b, 0) % 50 === 0) {
      printStats();
    }

  } catch (error) {
    console.error('❌ Error processing message:', error.message);
  }
});

client.on('error', (err) => {
  console.error('❌ MQTT Connection Error:', err.message);
  process.exit(1);
});

// แสดงสถิติ
function printStats() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📊 STATISTICS');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  console.log(`Total Messages: ${Object.values(topicStats).reduce((a, b) => a + b, 0)}`);
  console.log(`Unique Topics: ${Object.keys(topicStats).length}`);
  console.log(`Device Types: ${Array.from(deviceTypes).join(', ')}\n`);
  
  console.log('Top 10 Topics by Message Count:');
  Object.entries(topicStats)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .forEach(([topic, count], index) => {
      console.log(`  ${index + 1}. ${topic}: ${count} messages`);
    });
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

// แสดงสรุปเมื่อกด Ctrl+C
process.on('SIGINT', () => {
  console.log('\n\n⚠️  Stopping inspector...\n');
  
  printStats();
  
  console.log('\n📋 DEVICE TYPE SUMMARY');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  Array.from(deviceTypes).forEach(deviceType => {
    const relatedTopics = Object.keys(sampleData).filter(t => t.startsWith(deviceType));
    console.log(`\n${deviceType.toUpperCase()}:`);
    console.log(`  Topics: ${relatedTopics.length}`);
    
    if (relatedTopics.length > 0) {
      const sampleTopic = relatedTopics[0];
      const sample = sampleData[sampleTopic];
      
      if (typeof sample === 'object') {
        console.log(`  Fields: ${Object.keys(sample).join(', ')}`);
        console.log(`  Sample:`);
        console.log(JSON.stringify(sample, null, 2).split('\n').map(line => `    ${line}`).join('\n'));
      }
    }
  });
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  console.log('✅ Inspection complete!\n');
  
  client.end();
  process.exit(0);
});

console.log('💡 Tip: Press Ctrl+C to see summary and exit\n');
