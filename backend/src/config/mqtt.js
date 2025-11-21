// MQTT Client Configuration
const mqtt = require('mqtt');
const EventEmitter = require('events');
const { processEarthquakeData, createNotificationMessage } = require('../utils/earthquakeCalculator');

class MQTTManager extends EventEmitter {
  constructor() {
    super();
    this.client = null;
    this.isConnected = false;
  }

  connect() {
    const options = {
      clientId: process.env.MQTT_CLIENT_ID || `eqnode_backend_${Date.now()}`,
      username: process.env.MQTT_USERNAME,
      password: process.env.MQTT_PASSWORD,
      clean: true,
      reconnectPeriod: 5000,
      connectTimeout: 30000,
    };

    const brokerUrl = process.env.MQTT_BROKER_URL || 'mqtt://mqtt.uiot.cloud:1883';
    
    console.log(`🔌 Connecting to MQTT Broker: ${brokerUrl}`);
    this.client = mqtt.connect(brokerUrl, options);

    this.client.on('connect', () => {
      console.log('✅ MQTT Connected');
      this.isConnected = true;
      this.subscribeToTopics();
      this.emit('connected');
    });

    this.client.on('error', (error) => {
      console.error('❌ MQTT Error:', error);
      this.emit('error', error);
    });

    this.client.on('message', (topic, message) => {
      try {
        const data = JSON.parse(message.toString());
        this.emit('message', { topic, data });
        this.handleMessage(topic, data);
      } catch (error) {
        console.error('Error parsing MQTT message:', error);
      }
    });

    this.client.on('close', () => {
      console.log('⚠️  MQTT Disconnected');
      this.isConnected = false;
      this.emit('disconnected');
    });
  }

  subscribeToTopics() {
    const topics = [
      'eqnode.tarita/hub/#',    // Subscribe to all topics under eqnode.tarita/hub
      'pmac/#',                  // Subscribe to PMAC devices
      'TPO/#',                   // Subscribe to TPO devices
      'earthquake/data',         // Legacy topic
      'earthquake/alert',        // Legacy topic
      'earthquake/status',       // Legacy topic
      'device/+/status',         // Wildcard for all devices
    ];

    topics.forEach(topic => {
      this.client.subscribe(topic, { qos: 1 }, (err) => {
        if (err) {
          console.error(`Failed to subscribe to ${topic}:`, err);
        } else {
          console.log(`📡 Subscribed to: ${topic}`);
        }
      });
    });
  }

  handleMessage(topic, data) {
    // ตรวจสอบว่าเป็นข้อมูลแผ่นดินไหวหรือไม่
    if (topic.includes('/eqdata/') || topic.includes('earthquake')) {
      // ประมวลผลข้อมูลแผ่นดินไหว
      const processedData = processEarthquakeData(data);
      
      console.log(`🌍 Earthquake Data [${topic}]:`, {
        deviceId: processedData.deviceId,
        magnitude: processedData.magnitude,
        severity: processedData.severity,
        shouldAlert: processedData.shouldAlert,
      });
      
      // Emit earthquake event
      this.emit('earthquake', processedData);
      
      // ถ้าควรส่ง alert
      if (processedData.shouldAlert) {
        const notification = createNotificationMessage(processedData);
        console.log(`🔔 Alert:`, notification);
        this.emit('alert', { earthquakeData: processedData, notification });
      }
    } else if (topic.startsWith('device/') || topic.includes('/status')) {
      // Device status update
      console.log(`📱 Device Status [${topic}]:`, data);
      this.emit('deviceStatus', data);
    } else {
      // Other messages
      console.log(`📨 MQTT Message [${topic}]:`, data);
    }
  }

  publish(topic, message, options = {}) {
    if (!this.isConnected) {
      console.error('Cannot publish: MQTT not connected');
      return false;
    }

    const payload = typeof message === 'string' ? message : JSON.stringify(message);
    
    this.client.publish(topic, payload, { qos: 1, ...options }, (err) => {
      if (err) {
        console.error(`Failed to publish to ${topic}:`, err);
      } else {
        console.log(`📤 Published to ${topic}`);
      }
    });

    return true;
  }

  disconnect() {
    if (this.client) {
      this.client.end();
      this.isConnected = false;
    }
  }
}

// Singleton instance
const mqttManager = new MQTTManager();

module.exports = mqttManager;
