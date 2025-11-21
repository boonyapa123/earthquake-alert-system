# Implementation Plan

- [x] 1. Setup and Configuration
  - Update app configuration for real data integration
  - Configure environment-specific settings (dev, staging, production)
  - Set up secure storage for sensitive data
  - _Requirements: 1.1, 1.3, 10.1, 10.5_

- [x] 1.1 Update AppConfig with production settings
  - Modify `lib/config/app_config.dart` to support multiple environments
  - Add flags for enabling/disabling mock data
  - Configure API endpoints and MQTT broker settings
  - _Requirements: 1.1, 1.3_

- [x] 1.2 Initialize secure storage service
  - Create `lib/services/storage_service.dart` for managing secure data
  - Implement methods for storing/retrieving user settings
  - Add encryption for sensitive settings
  - _Requirements: 10.1, 10.5_

- [x] 2. Home Screen - Real Device Display
  - Implement API integration to fetch user's registered devices
  - Filter devices by owner ID
  - Add device categorization by type
  - Implement pull-to-refresh functionality
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2.1 Create device API service methods
  - Add `getUserDevices()` method in `lib/services/api_service.dart`
  - Implement device filtering by user ID
  - Add error handling for API failures
  - _Requirements: 1.1, 1.3_

- [x] 2.2 Update HomeScreen to use real device data
  - Modify `lib/screens/home_screen.dart` to fetch from API
  - Remove mock device data
  - Implement device categorization logic
  - Add loading states and error handling
  - _Requirements: 1.1, 1.2, 1.4_

- [x] 2.3 Add pull-to-refresh functionality
  - Implement RefreshIndicator widget
  - Add refresh logic to reload device data
  - Show refresh status to user
  - _Requirements: 1.5_

- [x] 3. MQTT Device Monitoring Tab
  - Add new tab to home screen for MQTT devices
  - Display real-time MQTT connection status
  - Show device online/offline indicators
  - Display last update timestamps
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 3.1 Create MQTT devices tab UI
  - Add TabBar to HomeScreen
  - Create "My Devices" and "MQTT Devices" tabs
  - Design MQTT device list item layout
  - _Requirements: 2.1_

- [x] 3.2 Implement real-time MQTT data display
  - Update UI when MQTT messages received
  - Show device status indicators (online/offline)
  - Display last update timestamp for each device
  - Add connection error messages
  - _Requirements: 2.2, 2.3, 2.4, 2.5_

- [x] 4. Settings Screen - Functional Implementation
  - Implement settings persistence to local storage
  - Add immediate application of setting changes
  - Load saved settings on app start
  - Add visual confirmation for setting changes
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4.1 Create settings storage service
  - Implement `saveSettings()` method in storage service
  - Add `loadSettings()` method
  - Create settings model class
  - _Requirements: 3.1, 3.3_

- [x] 4.2 Update SettingsScreen with functional controls
  - Modify `lib/screens/settings_screen.dart` to persist changes
  - Implement immediate setting application
  - Add confirmation messages
  - Load settings on screen init
  - _Requirements: 3.2, 3.4, 3.5_

- [x] 4.3 Implement alert threshold setting
  - Add slider for magnitude threshold
  - Save threshold to storage
  - Apply threshold to alert filtering
  - _Requirements: 3.4, 6.1_

- [x] 5. Alerts Screen - Real Data Integration
  - Fetch alerts from Backend API
  - Display real-time alerts from MQTT
  - Remove all mock data
  - Show alert details with device information
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 5.1 Create alerts API service methods
  - Add `getAlerts()` method in api_service.dart
  - Implement filtering by user's devices
  - Add pagination support
  - _Requirements: 4.1_

- [x] 5.2 Update AlertsScreen to use real data
  - Modify `lib/screens/alerts_screen.dart` to fetch from API
  - Integrate MQTT real-time alerts
  - Remove mock alert data
  - Display complete alert information
  - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [x] 6. Alert Toggle Functionality
  - Implement notification enable/disable toggle
  - Persist toggle state across app restarts
  - Update FCM subscription based on toggle
  - Apply toggle to notification display
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6.1 Add notification toggle to settings
  - Create toggle switch in SettingsScreen
  - Save toggle state to storage
  - Load toggle state on app start
  - _Requirements: 5.1, 5.4_

- [x] 6.2 Implement toggle behavior
  - Stop showing notifications when disabled
  - Resume notifications when enabled
  - Update FCM subscription status
  - _Requirements: 5.2, 5.3, 5.5_

- [x] 7. Alert Frequency Configuration
  - Add setting for max notification count per event
  - Track notification count for each event
  - Stop notifications when limit reached
  - Reset count for new events
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7.1 Create notification counter system
  - Add notification count tracking to event model
  - Implement counter increment logic
  - Add counter reset on new event
  - _Requirements: 6.2, 6.4_

- [x] 7.2 Add max notification setting
  - Create setting UI for notification count (1-10)
  - Save setting to storage
  - Apply limit to notification sending
  - _Requirements: 6.1, 6.3, 6.5_

- [x] 8. QR Code Device Registration
  - Implement QR code scanner
  - Parse device ID from QR code
  - Send registration request to backend
  - Handle registration success/failure
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 8.1 Update QR scanner screen
  - Modify `lib/screens/qr_scanner_screen.dart` to parse device data
  - Extract deviceId from QR code JSON
  - Validate QR code format
  - _Requirements: 7.1, 7.2_

- [x] 8.2 Implement device registration API call
  - Add `registerDevice()` method in api_service.dart
  - Send deviceId and user token to backend
  - Handle API response
  - _Requirements: 7.3_

- [x] 8.3 Add registration result handling
  - Show success message on successful registration
  - Display error message on failure
  - Add device to user's device list on success
  - Navigate back to home screen
  - _Requirements: 7.4, 7.5_

- [x] 9. Global Earthquake Events Screen
  - Create new screen for global events
  - Fetch global earthquake data from API
  - Display events with location and magnitude
  - Show events on world map
  - Add filtering options
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 9.1 Create global events screen UI
  - Create `lib/screens/global_events_screen.dart`
  - Design event list layout
  - Add map view component
  - Create filter UI
  - _Requirements: 8.1, 8.4_

- [x] 9.2 Implement global events API integration
  - Add `getGlobalEvents()` method in api_service.dart
  - Fetch events from backend
  - Parse and display event data
  - _Requirements: 8.2, 8.3_

- [x] 9.3 Add event filtering functionality
  - Implement magnitude filter
  - Add date range filter
  - Create region filter
  - Apply filters to event list
  - _Requirements: 8.5_

- [x] 9.4 Implement event detail view
  - Create event detail screen
  - Navigate to detail on event tap
  - Display complete event information
  - _Requirements: 8.6_

- [x] 10. Custom App Icon and Logo
  - Generate app icons from provided logo
  - Update iOS app icon
  - Update Android app icon
  - Update splash screen logo
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 10.1 Prepare logo assets
  - Save provided logo image to assets folder
  - Create different sizes for various platforms
  - Optimize images for mobile
  - _Requirements: 11.1_

- [x] 10.2 Generate and configure app icons
  - Use flutter_launcher_icons package
  - Configure pubspec.yaml with icon settings
  - Generate icons for iOS and Android
  - Verify icons on both platforms
  - _Requirements: 11.2, 11.3, 11.4_

- [x] 10.3 Update splash screen
  - Update splash screen with new logo
  - Configure splash screen for iOS and Android
  - Test splash screen display
  - _Requirements: 11.5_

- [x] 11. Lock Screen Alert Notifications
  - Implement full-screen notifications for locked device
  - Show alert details on lock screen
  - Add alert sound
  - Enable dismiss and open actions
  - Request necessary permissions
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 11.1 Configure high-priority notification channel
  - Create critical alert channel in notification service
  - Set importance to max
  - Enable full-screen intent
  - Configure sound and vibration
  - _Requirements: 12.1, 12.3_

- [x] 11.2 Implement lock screen notification display
  - Modify `showEarthquakeAlert()` in notification_service.dart
  - Add full-screen intent for critical alerts
  - Display alert details on lock screen
  - Add action buttons (dismiss, open)
  - _Requirements: 12.2, 12.4_

- [x] 11.3 Request lock screen permissions
  - Add permission requests to app initialization
  - Request notification permission
  - Request full-screen intent permission (Android)
  - Handle permission denial gracefully
  - _Requirements: 12.5_

- [x] 12. App Badge Notification Counter
  - Implement badge counter on app icon
  - Increment badge on new alert
  - Reset badge when alerts viewed
  - Persist badge count across restarts
  - Update badge in real-time
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 12.1 Add badge counter package
  - Add flutter_app_badger package to pubspec.yaml
  - Initialize badge counter service
  - Create badge management methods
  - _Requirements: 13.1_

- [x] 12.2 Implement badge increment logic
  - Increment badge when alert received in background
  - Update badge counter on app icon
  - Store badge count in local storage
  - _Requirements: 13.2, 13.4_

- [x] 12.3 Implement badge reset logic
  - Reset badge to zero when AlertsScreen opened
  - Update stored badge count
  - Verify badge cleared on app icon
  - _Requirements: 13.3_

- [x] 12.4 Add real-time badge updates
  - Update badge immediately on new alert
  - Sync badge count with unread alerts
  - Handle badge updates in background
  - _Requirements: 13.5_

- [x] 13. Settings Synchronization
  - Implement optional cloud sync for settings
  - Sync settings to backend
  - Load cloud settings on app start
  - Prompt user for sync conflicts
  - _Requirements: 10.2, 10.3, 10.4_

- [x] 13.1 Create settings sync API methods
  - Add `syncSettings()` method in api_service.dart
  - Implement `getCloudSettings()` method
  - Add conflict resolution logic
  - _Requirements: 10.2_

- [x] 13.2 Implement settings sync on app start
  - Load local settings first
  - Fetch cloud settings if available
  - Compare timestamps
  - Prompt user if cloud settings are newer
  - _Requirements: 10.3, 10.4_

- [x] 14. Navigation and Routing Updates
  - Add global events screen to navigation
  - Update main navigation drawer/bottom bar
  - Implement deep linking for notifications
  - Add navigation from alerts to device details
  - _Requirements: 8.1, 4.5_

- [x] 14.1 Update main navigation
  - Add global events screen to bottom navigation or drawer
  - Update route definitions
  - Add navigation icons
  - _Requirements: 8.1_

- [x] 14.2 Implement notification deep linking
  - Configure deep link handling
  - Navigate to specific alert on notification tap
  - Pass event data through navigation
  - _Requirements: 4.5_

- [x] 15. Error Handling and User Feedback
  - Implement consistent error handling across app
  - Add user-friendly error messages
  - Create error dialog component
  - Add retry mechanisms for failed operations
  - _Requirements: 1.4, 2.5, 4.4_

- [x] 15.1 Create error handling utilities
  - Create `lib/utils/error_handler.dart`
  - Implement error message mapping
  - Add error dialog widget
  - _Requirements: 1.4, 4.4_

- [x] 15.2 Add retry mechanisms
  - Implement retry logic for API calls
  - Add retry button to error dialogs
  - Handle MQTT reconnection
  - _Requirements: 2.5_

- [x] 16. Performance Optimization
  - Implement efficient state management
  - Add caching for API responses
  - Optimize MQTT message handling
  - Reduce unnecessary widget rebuilds
  - _Requirements: All_

- [x] 16.1 Optimize state management
  - Review Provider usage
  - Implement selective rebuilding
  - Add const constructors where possible
  - _Requirements: All_

- [x] 16.2 Implement API response caching
  - Add caching layer to api_service.dart
  - Cache device list and event data
  - Implement cache invalidation
  - _Requirements: 1.3, 4.1_

- [x] 17. Testing and Validation
  - Test all screens with real data
  - Verify settings persistence
  - Test notification functionality
  - Validate QR code scanning
  - Test MQTT connection and data flow
  - _Requirements: All_

- [x] 17.1 Manual testing checklist
  - Test login and device registration
  - Verify home screen displays user's devices only
  - Test MQTT tab shows real-time data
  - Verify settings are saved and applied
  - Test alert toggle functionality
  - Scan QR code and register device
  - Verify global events screen
  - Test lock screen notifications
  - Verify badge counter updates
  - _Requirements: All_

- [ ]* 17.2 Write automated tests
  - Create unit tests for services
  - Add widget tests for screens
  - Write integration tests for critical flows
  - _Requirements: All_
