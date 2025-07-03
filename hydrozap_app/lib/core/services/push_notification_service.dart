import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hydrozap_app/core/models/notification_model.dart';
import 'package:hydrozap_app/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrozap_app/core/utils/logger.dart';

class PushNotificationService {
  late final FirebaseMessaging _messaging;
  final NotificationProvider _notificationProvider;
  
  bool _initialized = false;

  PushNotificationService(this._notificationProvider);

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Make sure Firebase is initialized before using Firebase Messaging
      await _ensureFirebaseInitialized();
      
      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;
      
      // Set up notification channels for Android
      if (Platform.isAndroid) {
        await _setupNotificationChannels();
      }
      
      // Request permission
      await _requestPermission();
      
      // Initialize FCM and get token
      await _initializeFirebaseMessaging();
      
      // Sync notification preferences from server
      await _notificationProvider.syncNotificationPreferencesFromServer();
      
      _initialized = true;
      debugPrint('Push notification service initialized successfully');
    } catch (e) {
      // Create a more detailed error message
      logger.e('Error initializing push notification service: $e');
      debugPrint('Error initializing push notification service: $e');
      
      // Still mark as initialized to prevent repeated error attempts
      _initialized = true;
      
      // Provide a fallback for testing without proper Firebase configuration
      if (e.toString().contains('FIS_AUTH_ERROR')) {
        logger.w('Firebase authentication error detected. Please ensure you have:');
        logger.w('1. Created a Firebase project');
        logger.w('2. Downloaded the google-services.json file to android/app/');
        logger.w('3. Configured build.gradle files correctly');
        logger.w('Using mock FCM functionality for development purposes.');
      }
    }
  }

  // Set up notification channels for Android
  Future<void> _setupNotificationChannels() async {
    // Set foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Note: The notification channel is created in the native Android code
    // in our Application.kt file. We don't need to create it here.
    debugPrint('Android notification channel setup complete');
  }

  // Ensure Firebase is initialized
  Future<void> _ensureFirebaseInitialized() async {
    try {
      // Try to get the default app
      Firebase.app();
      debugPrint('Firebase already initialized, continuing with messaging setup');
    } catch (e) {
      // Only initialize if the error is about Firebase not being initialized
      if (e.toString().contains('No Firebase App') || e.toString().contains('not been initialized')) {
        debugPrint('Firebase not initialized, initializing now');
        try {
          await Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: "AIzaSyBxr6fiKPQMKtRPKmynPZP9JO54tid9jP0",
              appId: "1:246984811775:web:9cd5bed9ff95b85f39c754",
              messagingSenderId: "246984811775",
              projectId: "hydroponics-1bab7",
              authDomain: "hydroponics-1bab7.firebaseapp.com",
              databaseURL: "https://hydroponics-1bab7-default-rtdb.firebaseio.com",
              storageBucket: "hydroponics-1bab7.appspot.com",
            ),
          );
        } catch (initError) {
          // If we get duplicate app error, just use the existing app
          if (initError.toString().contains('duplicate-app')) {
            debugPrint('Using existing Firebase app');
          } else {
            // Rethrow any other initialization errors
            rethrow;
          }
        }
      } else {
        // Rethrow if it's some other Firebase error
        rethrow;
      }
    }
  }

  Future<void> _requestPermission() async {
    try {
      // Check if running on a mobile platform in a safe way
      bool isMobile = false;
      try {
        isMobile = Platform.isIOS || Platform.isAndroid;
      } catch (e) {
        // Platform not available, likely running on web
        debugPrint('Platform detection failed, likely running on web: $e');
      }

      if (isMobile) {
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: false,
          carPlay: false,
          criticalAlert: true,  // Request critical alert permissions
          provisional: false,
        );
        
        debugPrint('User granted permission: ${settings.authorizationStatus}');
      } else {
        // For web or other platforms
        debugPrint('Permission not requested: not on a mobile platform');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Check if we're on a platform where FCM is supported
      bool isSupportedPlatform = false;
      try {
        // This will throw on web or unsupported platforms
        isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        debugPrint('Platform detection failed, FCM may not be supported: $e');
      }
      
      if (!isSupportedPlatform) {
        debugPrint('Firebase Messaging not fully supported on this platform. Some features may be limited.');
        return;
      }
      
      // Get FCM token with better error handling
      String? token;
      try {
        token = await _messaging.getToken();
        logger.d('FCM Token: $token');
        debugPrint('FCM Token: $token');
        
        // Save token to provider
        if (token != null) {
          await _notificationProvider.saveFcmToken(token);
        }
      } catch (e) {
        logger.e('Error getting FCM token: $e');
        debugPrint('Error getting FCM token: $e');
        // Use a mock token for development if Firebase isn't properly configured
        if (e.toString().contains('FIS_AUTH_ERROR')) {
          const mockToken = 'mock-fcm-token-for-development';
          logger.w('Using mock FCM token for development: $mockToken');
          await _notificationProvider.saveFcmToken(mockToken);
        } else {
          // Rethrow if it's not the auth error we're handling
          rethrow;
        }
      }
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        logger.d('FCM Token refreshed: $newToken');
        debugPrint('FCM Token refreshed: $newToken');
        // Save refreshed token to provider
        _notificationProvider.saveFcmToken(newToken);
      });
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification tap when app is in background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Check if app was opened from a notification when app was terminated
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');
    
    try {
      // Check notification preferences before showing notification
      final shouldShow = await _shouldShowNotification(message);
      
      if (!shouldShow) {
        debugPrint('Notification not shown due to user preferences');
        return;
      }
      
      // Add notification to provider
      _addNotificationToProvider(message);
      
      // If on Android, we need to handle foreground notifications specially to show as heads-up
      if (Platform.isAndroid) {
        final notification = message.notification;
        final android = message.notification?.android;
        
        if (notification != null && android != null) {
          // Log that we're handling the Android notification
          debugPrint('Handling Android notification with priority setup');
        }
      }
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  // Check notification preferences
  Future<bool> _shouldShowNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final prefs = await SharedPreferences.getInstance();
      
      // Log message data for debugging
      debugPrint('Checking notification preferences for message: ${message.messageId}');
      debugPrint('Message data: $data');
      
      // Always show high priority notifications
      if (data['priority'] == 'high' || data['alert_type'] == 'critical' || data['type'] == 'critical') {
        debugPrint('High priority or critical alert, showing notification');
        return true;
      }
      
      // Check master toggle for push notifications
      final pushEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      if (!pushEnabled) {
        debugPrint('Push notifications disabled globally, blocking notification');
        return false;
      }
      
      // Get alert type from data
      final rawAlertType = data['type'] ?? data['alert_type'];
      if (rawAlertType == null) {
        debugPrint('No specific alert type found, defaulting to show notification');
        return true; // No specific type, default to show
      }
      
      // Map alert types to preference keys
      final alertTypeMapping = {
        'ph': 'ph_level_alerts',
        'ph_high': 'ph_level_alerts',
        'ph_low': 'ph_level_alerts',
        'ec': 'nutrient_level_alerts',
        'ec_high': 'nutrient_level_alerts',
        'ec_low': 'nutrient_level_alerts',
        'temperature': 'temperature_alerts',
        'temp_high': 'temperature_alerts',
        'temp_low': 'temperature_alerts',
        'humidity': 'humidity_alerts',
        'water_level': 'water_level_alerts',
        'water_low': 'water_level_alerts',
        'harvest': 'harvest_reminders',
        'maintenance': 'scheduled_maintenance',
        'system': 'system_alerts',
        'update': 'update_alerts',
      };
      
      // Get the mapped alert type for preference checking
      final alertType = alertTypeMapping[rawAlertType] ?? rawAlertType;
      final alertTypeKey = '${alertType}_enabled';
      
      debugPrint('Checking preference key: $alertTypeKey for alert type: $rawAlertType');
      
      // Get the current setting for this alert type
      final alertTypeEnabled = prefs.getBool(alertTypeKey);
      debugPrint('Alert type preference value: $alertTypeEnabled');
      
      // Check specific alert type preferences
      if (alertTypeEnabled == false) {
        debugPrint('Alert type $rawAlertType is disabled, blocking notification');
        return false;
      }
      
      // Check quiet hours
      final quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
      if (quietHoursEnabled) {
        final now = DateTime.now();
        final currentHour = now.hour;
        final currentMinute = now.minute;
        
        final startHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
        final startMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
        final endHour = prefs.getInt('quiet_hours_end_hour') ?? 7;
        final endMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;
        
        final currentTime = currentHour * 60 + currentMinute;
        final startTime = startHour * 60 + startMinute;
        final endTime = endHour * 60 + endMinute;
        
        // Check if current time is within quiet hours
        if (startTime < endTime) {
          // Simple case: start and end on same day
          if (currentTime >= startTime && currentTime <= endTime) {
            debugPrint('Within quiet hours, blocking notification');
            return false;
          }
        } else {
          // Complex case: quiet hours span midnight
          if (currentTime >= startTime || currentTime <= endTime) {
            debugPrint('Within quiet hours, blocking notification');
            return false;
          }
        }
      }
      
      // All checks passed, show notification
      debugPrint('All notification preference checks passed, showing notification');
      return true;
    } catch (e) {
      debugPrint('Error checking notification preferences: $e');
      return true; // Default to showing in case of error
    }
  }

  // Handle message opened when app is in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Handling message opened from background: ${message.messageId}');
    
    // Add notification to provider if not already added
    _addNotificationToProvider(message);
    
    // Handle notification tap
    _handleNotificationTap(message.data);
  }

  // Add notification to provider
  void _addNotificationToProvider(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    if (notification != null) {
      // Determine notification type based on data
      NotificationType type = NotificationType.info;
      if (data.containsKey('type')) {
        final typeStr = data['type'];
        if (typeStr == 'alert') type = NotificationType.alert;
        if (typeStr == 'warning') type = NotificationType.warning;
        if (typeStr == 'success') type = NotificationType.success;
      }
      
      final appNotification = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? 'HydroZap Notification',
        message: notification.body ?? '',
        type: type,
        timestamp: DateTime.now(),
        deviceId: data['device_id'],
        alertType: data['alert_type'],
        data: data,
      );
      
      _notificationProvider.addNotification(appNotification);
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle based on notification type and data
    debugPrint('Notification tapped with data: $data');
    
    // Check if the notification is an alert type
    if (data.containsKey('type') && data['type'] == 'alert') {
      // Extract alert and device information
      final String? deviceId = data['device_id'];
      final String? alertId = data['alert_id'];
      final String? alertType = data['alert_type'];
      
      if (deviceId != null && alertId != null) {
        debugPrint('Navigating to alert details: Device ID: $deviceId, Alert ID: $alertId');
        
        // For alerts, we'll use named routes to navigate
        // This approach doesn't require BuildContext
        // Get the NavigatorState via GlobalKey if available
        
        // We could use a route like:
        // /alerts/detail?alertId=$alertId&deviceId=$deviceId
        
        // Or we could use a dedicated route with arguments:
        // Navigator.of(navigatorKey.currentContext!).pushNamed(
        //   AppRoutes.alertDetail,
        //   arguments: {
        //     'alert_id': alertId,
        //     'device_id': deviceId,
        //     'user_id': data['user_id'],
        //   },
        // );
        
        // Instead, we'll use the notification data to store this info
        // and let the main app handle navigation on next app start or resume
        _notificationProvider.setNavigationIntent({
          'route': '/alerts',
          'arguments': {
            'alert_id': alertId,
            'device_id': deviceId,
            'alert_type': alertType,
          }
        });
      } else {
        debugPrint('Missing required alert data for navigation: deviceId or alertId');
      }
    } else {
      debugPrint('Notification is not an alert type or missing type information');
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
  
  // Subscribe to device topic
  Future<void> subscribeToDevice(String deviceId) async {
    if (deviceId.isEmpty) return;
    
    try {
      // Check if we're on a platform where FCM is supported
      bool isSupportedPlatform = false;
      try {
        isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        debugPrint('Platform detection failed, FCM topic subscription may not work: $e');
      }
      
      if (!isSupportedPlatform) {
        debugPrint('Skipping FCM topic subscription on unsupported platform for device: $deviceId');
        return;
      }
      
      // Format device ID to be a valid topic name
      // FCM topics must match the pattern: [a-zA-Z0-9-_.~%]+
      final String formattedDeviceId = deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
      
      // Subscribe to device-specific topic
      await subscribeToTopic('device_$formattedDeviceId');
      
      // Update notification provider
      await _notificationProvider.subscribeToDevice(deviceId);
      
      debugPrint('Subscribed to device: $deviceId');
    } catch (e) {
      debugPrint('Error subscribing to device topic: $e');
    }
  }
  
  // Unsubscribe from device topic
  Future<void> unsubscribeFromDevice(String deviceId) async {
    if (deviceId.isEmpty) return;
    
    try {
      // Check if we're on a platform where FCM is supported
      bool isSupportedPlatform = false;
      try {
        isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        debugPrint('Platform detection failed, FCM topic unsubscription may not work: $e');
      }
      
      if (!isSupportedPlatform) {
        debugPrint('Skipping FCM topic unsubscription on unsupported platform for device: $deviceId');
        return;
      }
      
      // Format device ID to be a valid topic name
      final String formattedDeviceId = deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
      
      // Unsubscribe from device-specific topic
      await unsubscribeFromTopic('device_$formattedDeviceId');
      
      // Update notification provider
      await _notificationProvider.unsubscribeFromDevice(deviceId);
      
      debugPrint('Unsubscribed from device: $deviceId');
    } catch (e) {
      debugPrint('Error unsubscribing from device topic: $e');
    }
  }
  
  // Subscribe to user topics
  Future<void> subscribeToUserTopics(String userId) async {
    if (userId.isEmpty) return;
    
    try {
      // Check if we're on a platform where FCM is supported
      bool isSupportedPlatform = false;
      try {
        isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        debugPrint('Platform detection failed, FCM topic subscription may not work: $e');
      }
      
      if (!isSupportedPlatform) {
        debugPrint('Skipping FCM topic subscription on unsupported platform for user: $userId');
        return;
      }
      
      // Format user ID to be a valid topic name
      final String formattedUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
      
      // Subscribe to user-specific topic
      await subscribeToTopic('user_$formattedUserId');
      
      // Subscribe to general topic
      await subscribeToTopic('all_users');
      
      debugPrint('Subscribed to user topics for: $userId');
    } catch (e) {
      debugPrint('Error subscribing to user topics: $e');
    }
  }
  
  // Unsubscribe from user topics
  Future<void> unsubscribeFromUserTopics(String userId) async {
    if (userId.isEmpty) return;
    
    try {
      // Check if we're on a platform where FCM is supported
      bool isSupportedPlatform = false;
      try {
        isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        debugPrint('Platform detection failed, FCM topic unsubscription may not work: $e');
      }
      
      if (!isSupportedPlatform) {
        debugPrint('Skipping FCM topic unsubscription on unsupported platform for user: $userId');
        return;
      }
      
      // Format user ID to be a valid topic name
      final String formattedUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
      
      // Unsubscribe from user-specific topic
      await unsubscribeFromTopic('user_$formattedUserId');
      
      // Unsubscribe from general topic
      await unsubscribeFromTopic('all_users');
      
      debugPrint('Unsubscribed from user topics for: $userId');
    } catch (e) {
      debugPrint('Error unsubscribing from user topics: $e');
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // This must not call any code that requires the Firebase app to be initialized
    // The Firebase app will not be initialized in the background
    debugPrint('Handling background message: ${message.messageId}');
    
    // The background handler should be minimal to avoid issues
    // You can store the message in local storage for processing when the app opens
  } catch (e) {
    debugPrint('Error in background message handler: $e');
  }
} 