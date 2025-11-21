# Requirements Document - App Functionality Enhancement

## Introduction

ปรับปรุงแอพพลิเคชัน Earthquake Monitoring ให้ทำงานได้จริงทุกหน้า โดยเชื่อมต่อกับข้อมูลจริงจาก Backend และ MQTT แทนการใช้ข้อมูล mockup รวมถึงเพิ่มฟีเจอร์การแสดงข้อมูลแผ่นดินไหวจากทั่วโลก

## Glossary

- **Mobile_App**: แอพพลิเคชัน Flutter สำหรับ iOS และ Android
- **Backend_Server**: Node.js server ที่จัดการข้อมูลและ API
- **MQTT_Broker**: ระบบ message broker สำหรับรับข้อมูลจาก IoT devices แบบ real-time
- **Device**: อุปกรณ์ตตรวจจับแผ่นดินไหว (IoT sensor)
- **User**: ผู้ใช้งานแอพพลิเคชันที่ลงทะเบียนแล้ว
- **Notification_System**: ระบบแจ้งเตือนผ่าน Firebase Cloud Messaging
- **QR_Code**: รหัส QR สำหรับลงทะเบียน device
- **Alert_Threshold**: ค่าขีดจำกัดสำหรับการแจ้งเตือน
- **Event_History**: ประวัติการเกิดแผ่นดินไหวที่บันทึกไว้

## Requirements

### Requirement 1: Home Screen Device Display

**User Story:** As a User, I want to see only my registered devices on the home screen categorized by type, so that I can monitor my own devices easily

#### Acceptance Criteria

1. WHEN the User opens the home screen, THE Mobile_App SHALL display only devices registered to that User
2. THE Mobile_App SHALL categorize devices by their type or location
3. THE Mobile_App SHALL fetch device data from Backend_Server using authenticated API calls
4. WHEN device data is unavailable, THE Mobile_App SHALL display an appropriate error message
5. THE Mobile_App SHALL refresh device data when the User pulls down to refresh

### Requirement 2: MQTT Device Monitoring Tab

**User Story:** As a User, I want to see a separate tab showing all devices connected via MQTT, so that I can verify the system is receiving real-time data

#### Acceptance Criteria

1. THE Mobile_App SHALL provide a tab or section to display devices currently connected to MQTT_Broker
2. WHEN MQTT data is received, THE Mobile_App SHALL update the device list in real-time
3. THE Mobile_App SHALL display device status indicators (online/offline) based on MQTT connection
4. THE Mobile_App SHALL show the last update timestamp for each device
5. WHEN no MQTT connection exists, THE Mobile_App SHALL display a connection error message

### Requirement 3: Functional Settings Screen

**User Story:** As a User, I want to configure app settings that actually affect app behavior, so that I can customize my experience

#### Acceptance Criteria

1. THE Mobile_App SHALL persist all settings changes to local storage
2. WHEN the User changes a setting, THE Mobile_App SHALL apply the change immediately
3. THE Mobile_App SHALL load saved settings when the app starts
4. THE Mobile_App SHALL provide settings for notification preferences, alert thresholds, and display options
5. WHEN settings are saved, THE Mobile_App SHALL provide visual confirmation to the User

### Requirement 4: Real Alert Data Display

**User Story:** As a User, I want to see actual earthquake alerts from my devices instead of mock data, so that I receive genuine notifications

#### Acceptance Criteria

1. THE Mobile_App SHALL fetch alert data from Backend_Server via API
2. THE Mobile_App SHALL display alerts received through MQTT_Broker in real-time
3. THE Mobile_App SHALL NOT display any mock or simulated data in production mode
4. WHEN a new alert arrives, THE Mobile_App SHALL update the alerts list immediately
5. THE Mobile_App SHALL display alert details including magnitude, location, timestamp, and device ID

### Requirement 5: Alert Toggle Functionality

**User Story:** As a User, I want to enable or disable notifications with a toggle button, so that I can control when I receive alerts

#### Acceptance Criteria

1. THE Mobile_App SHALL provide a toggle button for enabling/disabling notifications
2. WHEN the User toggles notifications off, THE Mobile_App SHALL stop displaying push notifications
3. WHEN the User toggles notifications on, THE Mobile_App SHALL resume displaying push notifications
4. THE Mobile_App SHALL persist the notification toggle state across app restarts
5. THE Mobile_App SHALL update the Notification_System subscription based on toggle state

### Requirement 6: Alert Frequency Configuration

**User Story:** As a User, I want to set how many times I should be notified when an earthquake occurs, so that I can avoid notification spam

#### Acceptance Criteria

1. THE Mobile_App SHALL provide a setting to configure maximum notification count per event
2. THE Mobile_App SHALL track notification count for each earthquake event
3. WHEN the notification count reaches the configured limit, THE Mobile_App SHALL stop sending notifications for that event
4. THE Mobile_App SHALL reset the notification count when a new earthquake event occurs
5. THE Mobile_App SHALL allow the User to set notification count between 1 and 10 times

### Requirement 7: QR Code Device Registration

**User Story:** As a User, I want to scan a QR code to register a new device, so that I can quickly add devices to my account

#### Acceptance Criteria

1. THE Mobile_App SHALL open the device camera when the User initiates QR scanning
2. WHEN a valid QR_Code is detected, THE Mobile_App SHALL extract the device ID
3. THE Mobile_App SHALL send a registration request to Backend_Server with the device ID and User credentials
4. WHEN registration succeeds, THE Mobile_App SHALL display a success message and add the device to the User's device list
5. WHEN registration fails, THE Mobile_App SHALL display an error message with the failure reason

### Requirement 8: Global Earthquake Events Screen

**User Story:** As a User, I want to view earthquake events from around the world, so that I can stay informed about global seismic activity

#### Acceptance Criteria

1. THE Mobile_App SHALL provide a new screen displaying global earthquake events
2. THE Mobile_App SHALL fetch global earthquake data from Backend_Server
3. THE Mobile_App SHALL display events with location, magnitude, depth, and timestamp
4. THE Mobile_App SHALL show events on a world map with markers
5. THE Mobile_App SHALL allow the User to filter events by magnitude, date range, or region
6. WHEN the User taps on an event, THE Mobile_App SHALL display detailed information

### Requirement 9: Event History with Real Data

**User Story:** As a User, I want to view historical earthquake data from my devices, so that I can analyze past events

#### Acceptance Criteria

1. THE Mobile_App SHALL fetch Event_History from Backend_Server
2. THE Mobile_App SHALL display events in chronological order with newest first
3. THE Mobile_App SHALL show event details including magnitude, location, timestamp, and affected devices
4. THE Mobile_App SHALL allow the User to filter history by date range or device
5. WHEN the User selects an event, THE Mobile_App SHALL navigate to a detailed view

### Requirement 10: Settings Persistence and Synchronization

**User Story:** As a User, I want my settings to be saved and synchronized, so that my preferences are maintained across devices

#### Acceptance Criteria

1. THE Mobile_App SHALL save all user preferences to local secure storage
2. THE Mobile_App SHALL optionally sync settings to Backend_Server for cross-device access
3. WHEN the app starts, THE Mobile_App SHALL load settings from local storage first
4. IF cloud settings exist and are newer, THE Mobile_App SHALL prompt the User to sync
5. THE Mobile_App SHALL encrypt sensitive settings before storage

### Requirement 11: Custom App Icon and Logo

**User Story:** As a User, I want to see a custom earthquake monitoring logo as the app icon, so that I can easily identify the app

#### Acceptance Criteria

1. THE Mobile_App SHALL use the provided custom logo image as the app icon
2. THE Mobile_App SHALL display the app icon on iOS home screen with proper resolution
3. THE Mobile_App SHALL display the app icon on Android home screen with proper resolution
4. THE Mobile_App SHALL generate all required icon sizes for both platforms
5. THE Mobile_App SHALL display the logo in the app splash screen

### Requirement 12: Lock Screen Alert Notifications

**User Story:** As a User, I want to receive full-screen alert notifications when my phone is locked, so that I am immediately aware of earthquake events

#### Acceptance Criteria

1. WHEN an earthquake alert occurs and the device is locked, THE Mobile_App SHALL display a full-screen notification
2. THE Mobile_App SHALL show alert details on the lock screen including magnitude and location
3. THE Mobile_App SHALL play an alert sound when displaying lock screen notifications
4. THE Mobile_App SHALL allow the User to dismiss or open the app from the lock screen notification
5. THE Mobile_App SHALL request necessary permissions for lock screen notifications during app setup

### Requirement 13: App Badge Notification Counter

**User Story:** As a User, I want to see a number badge on the app icon showing unread alerts, so that I know how many alerts I haven't checked

#### Acceptance Criteria

1. WHEN a new alert arrives and the app is in background, THE Mobile_App SHALL increment the badge counter
2. THE Mobile_App SHALL display the badge number on the app icon
3. WHEN the User opens the alerts screen, THE Mobile_App SHALL reset the badge counter to zero
4. THE Mobile_App SHALL persist the badge count across app restarts
5. THE Mobile_App SHALL update the badge count in real-time as new alerts arrive
