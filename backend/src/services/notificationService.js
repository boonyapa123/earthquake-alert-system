// Notification Service
// ส่ง push notifications ไปยัง mobile apps

let admin;
try {
  admin = require('firebase-admin');
} catch (error) {
  console.log('ℹ️  firebase-admin not installed - using mock notifications');
  admin = null;
}

class NotificationService {
  constructor() {
    this.initialized = false;
    this.initializeFirebase();
  }

  initializeFirebase() {
    try {
      if (!admin) {
        console.log('ℹ️  Firebase Admin SDK not available - using mock notifications');
        this.initialized = false;
        return;
      }

      // ลองโหลด service account key
      const fs = require('fs');
      const path = require('path');
      const serviceAccountPath = path.join(__dirname, '../../serviceAccountKey.json');

      if (fs.existsSync(serviceAccountPath)) {
        const serviceAccount = require(serviceAccountPath);
        
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: process.env.FIREBASE_PROJECT_ID || 'earthquake-api-server',
        });

        this.initialized = true;
        console.log('✅ Firebase Admin SDK initialized successfully');
        console.log(`   Project: ${serviceAccount.project_id}`);
      } else {
        console.log('⚠️  Firebase service account key not found');
        console.log('   Expected location: backend/serviceAccountKey.json');
        console.log('   Using mock notifications instead');
        this.initialized = false;
      }
    } catch (error) {
      console.error('❌ Firebase initialization error:', error.message);
      console.log('   Using mock notifications instead');
      this.initialized = false;
    }
  }

  /**
   * ส่ง notification ไปยัง device token เดียว
   */
  async sendToDevice(token, notification, data = {}) {
    if (!this.initialized) {
      console.log('📧 [MOCK] Notification to device:', {
        token: token.substring(0, 20) + '...',
        title: notification.title,
        body: notification.body,
      });
      return { success: true, mock: true };
    }

    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data,
        token: token,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'earthquake_alerts',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Notification sent:', response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * ส่ง notification ไปยังหลาย devices
   */
  async sendToMultipleDevices(tokens, notification, data = {}) {
    if (!this.initialized) {
      console.log('📧 [MOCK] Notification to multiple devices:', {
        count: tokens.length,
        title: notification.title,
        body: notification.body,
      });
      return { success: true, mock: true, count: tokens.length };
    }

    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data,
        tokens: tokens,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'earthquake_alerts',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`✅ Notifications sent: ${response.successCount}/${tokens.length}`);
      
      if (response.failureCount > 0) {
        console.log('⚠️  Some notifications failed:', response.failureCount);
      }

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error('❌ Error sending notifications:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * ส่ง notification ไปยัง topic
   */
  async sendToTopic(topic, notification, data = {}) {
    if (!this.initialized) {
      console.log('📧 [MOCK] Notification to topic:', {
        topic,
        title: notification.title,
        body: notification.body,
      });
      return { success: true, mock: true };
    }

    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data,
        topic: topic,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'earthquake_alerts',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Topic notification sent:', response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('❌ Error sending topic notification:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * ส่ง earthquake alert ไปยังผู้ใช้ทั้งหมด
   */
  async sendEarthquakeAlert(earthquakeData, notification) {
    console.log('🚨 Sending earthquake alert...');
    
    // ส่งไปยัง topic 'earthquake_alerts' ที่ผู้ใช้ทุกคน subscribe
    const result = await this.sendToTopic('earthquake_alerts', notification, notification.data);
    
    // TODO: Query users from database and send to specific devices
    // const users = await User.find({ notificationsEnabled: true });
    // const tokens = users.map(user => user.fcmToken).filter(token => token);
    // await this.sendToMultipleDevices(tokens, notification, notification.data);
    
    return result;
  }
}

// Singleton instance
const notificationService = new NotificationService();

module.exports = notificationService;
