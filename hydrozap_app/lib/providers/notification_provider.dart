import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/notification_model.dart';
import '../core/api/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool _showDropdown = false;
  final ApiService _apiService = ApiService();
  static const String _storageKey = 'app_notifications';
  static const String _fcmTokenKey = 'fcm_token';
  String? _fcmToken;

  List<AppNotification> get notifications => _notifications;
  bool get showDropdown => _showDropdown;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  String? get fcmToken => _fcmToken;

  NotificationProvider() {
    _loadNotifications();
    _loadFcmToken();
  }

  // Load FCM token from shared preferences
  Future<void> _loadFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString(_fcmTokenKey);
    } catch (e) {
      print('Error loading FCM token: $e');
    }
  }

  // Save FCM token to shared preferences
  Future<void> saveFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      _fcmToken = token;
      notifyListeners();
      
      // Update token in backend if user is logged in
      _updateFcmTokenInBackend(token);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Update FCM token in backend
  Future<void> _updateFcmTokenInBackend(String token) async {
    try {
      // Get current user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');
      
      print('Preparing to update FCM token in backend');
      print('User ID: ${userId ?? 'not found'}');
      
      if (userId != null && userId.isNotEmpty) {
        print('Calling registerFcmToken with userId: $userId');
        final success = await _apiService.registerFcmToken(userId, token);
        if (success) {
          print('FCM token registered successfully for user $userId');
          // Save the token locally to prevent repeated registration attempts
          await prefs.setString('registered_fcm_token', token);
        } else {
          print('Failed to register FCM token for user $userId');
          // We'll retry on next app start if this fails
        }
      } else {
        print('Cannot register FCM token: No user ID found in shared preferences');
      }
    } catch (e) {
      print('Error updating FCM token in backend: $e');
    }
  }

  // Load notifications from shared preferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_storageKey);
      
      if (notificationsJson != null) {
        final List<dynamic> decodedList = jsonDecode(notificationsJson);
        final loadedNotifications = decodedList.map((item) {
          return AppNotification(
            id: item['id'],
            title: item['title'],
            message: item['message'],
            type: NotificationType.values.firstWhere(
              (e) => e.toString() == 'NotificationType.${item['type']}',
              orElse: () => NotificationType.info,
            ),
            timestamp: DateTime.parse(item['timestamp']),
            isRead: item['isRead'] ?? false,
            deviceId: item['deviceId'],
            alertType: item['alertType'],
            data: item['data'] != null ? Map<String, dynamic>.from(item['data']) : null,
          );
        }).toList();
        
        _notifications.addAll(loadedNotifications);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Save notifications to shared preferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedList = _notifications.map((notification) {
        return {
          'id': notification.id,
          'title': notification.title,
          'message': notification.message,
          'type': notification.type.toString().split('.').last,
          'timestamp': notification.timestamp.toIso8601String(),
          'isRead': notification.isRead,
          'deviceId': notification.deviceId,
          'alertType': notification.alertType,
          'data': notification.data,
        };
      }).toList();
      
      await prefs.setString(_storageKey, jsonEncode(serializedList));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  void toggleDropdown() {
    _showDropdown = !_showDropdown;
    notifyListeners();
  }

  void addNotification(AppNotification notification) {
    final newNotification = AppNotification(
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      timestamp: notification.timestamp,
      isRead: false,
      deviceId: notification.deviceId,
      alertType: notification.alertType,
      data: notification.data,
    );
    _notifications.insert(0, newNotification);
    
    // Only save device-related notifications to Firebase
    if (notification.deviceId != null && notification.deviceId!.isNotEmpty) {
      _saveNotificationToFirebase(notification);
    }
    
    _saveNotifications();
    notifyListeners();
  }
  
  // Save notification to Firebase as an alert
  Future<void> _saveNotificationToFirebase(AppNotification notification) async {
    try {
      final String userId = notification.data?['user_id'] ?? 'default_user'; // Get user ID from data or use default
      
      final alertData = {
        'user_id': userId,
        'device_id': notification.deviceId,
        'message': notification.message,
        'alert_type': notification.alertType ?? notification.type.toString().split('.').last,
      };
      
      final success = await _apiService.triggerAlert(alertData);
      if (success) {
        print('Alert saved to Firebase successfully');
      } else {
        print('Failed to save alert to Firebase');
      }
    } catch (e) {
      print('Error saving notification to Firebase: $e');
    }
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = AppNotification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        type: _notifications[index].type,
        timestamp: _notifications[index].timestamp,
        isRead: true,
        deviceId: _notifications[index].deviceId,
        alertType: _notifications[index].alertType,
        data: _notifications[index].data,
      );
      _saveNotifications();
      notifyListeners();
    }
  }

  void deleteNotification(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications.removeAt(index);
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = AppNotification(
          id: _notifications[i].id,
          title: _notifications[i].title,
          message: _notifications[i].message,
          type: _notifications[i].type,
          timestamp: _notifications[i].timestamp,
          isRead: true,
          deviceId: _notifications[i].deviceId,
          alertType: _notifications[i].alertType,
          data: _notifications[i].data,
        );
      }
    }
    _saveNotifications();
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  // Subscribe to specific device topic
  Future<void> subscribeToDevice(String deviceId) async {
    // Add any specific subscription logic here if needed
    // This is a placeholder for device-specific subscription
    print('Subscribed to device: $deviceId');
  }

  // Unsubscribe from specific device topic
  Future<void> unsubscribeFromDevice(String deviceId) async {
    // Add any specific unsubscription logic here if needed
    // This is a placeholder for device-specific unsubscription
    print('Unsubscribed from device: $deviceId');
  }
  
  // Store navigation intent from push notification
  Future<void> setNavigationIntent(Map<String, dynamic> navigationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_navigation_intent', jsonEncode(navigationData));
      print('Navigation intent saved: $navigationData');
    } catch (e) {
      print('Error saving navigation intent: $e');
    }
  }
  
  // Get navigation intent from push notification
  Future<Map<String, dynamic>?> getNavigationIntent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? navigationData = prefs.getString('notification_navigation_intent');
      
      if (navigationData != null) {
        // Clear the navigation intent after retrieving it
        await prefs.remove('notification_navigation_intent');
        
        return jsonDecode(navigationData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting navigation intent: $e');
      return null;
    }
  }

  // Add a new method to sync notification preferences from server to local storage
  Future<void> syncNotificationPreferencesFromServer() async {
    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null || userId.isEmpty) {
        print('Cannot sync notification preferences: No user ID found');
        return;
      }
      
      print('Syncing notification preferences from server for user: $userId');
      
      // Use the API service to get preferences from server
      final apiService = ApiService();
      final serverPrefs = await apiService.getNotificationPreferences(userId);
      
      if (serverPrefs != null && serverPrefs.isNotEmpty) {
        print('Received notification preferences from server: $serverPrefs');
        
        // Save notification channel preferences
        await prefs.setBool('push_notifications_enabled', serverPrefs['push_notifications_enabled'] ?? true);
        await prefs.setBool('email_notifications_enabled', serverPrefs['email_notifications_enabled'] ?? true);
        await prefs.setBool('sms_notifications_enabled', serverPrefs['sms_notifications_enabled'] ?? false);
        
        // Save system notification preferences
        await prefs.setBool('system_alerts_enabled', serverPrefs['system_alerts_enabled'] ?? true);
        await prefs.setBool('maintenance_alerts_enabled', serverPrefs['maintenance_alerts_enabled'] ?? true);
        await prefs.setBool('update_alerts_enabled', serverPrefs['update_alerts_enabled'] ?? true);
        
        // Save hydroponics notification preferences
        await prefs.setBool('nutrient_level_alerts_enabled', serverPrefs['nutrient_level_alerts_enabled'] ?? true);
        await prefs.setBool('ph_level_alerts_enabled', serverPrefs['ph_level_alerts_enabled'] ?? true);
        await prefs.setBool('water_level_alerts_enabled', serverPrefs['water_level_alerts_enabled'] ?? true);
        await prefs.setBool('temperature_alerts_enabled', serverPrefs['temperature_alerts_enabled'] ?? true);
        await prefs.setBool('harvest_reminders_enabled', serverPrefs['harvest_reminders_enabled'] ?? true);
        await prefs.setBool('scheduled_maintenance_enabled', serverPrefs['scheduled_maintenance_enabled'] ?? true);
        
        // Save quiet hours preferences
        await prefs.setBool('quiet_hours_enabled', serverPrefs['quiet_hours_enabled'] ?? false);
        await prefs.setInt('quiet_hours_start_hour', serverPrefs['quiet_hours_start_hour'] ?? 22);
        await prefs.setInt('quiet_hours_start_minute', serverPrefs['quiet_hours_start_minute'] ?? 0);
        await prefs.setInt('quiet_hours_end_hour', serverPrefs['quiet_hours_end_hour'] ?? 7);
        await prefs.setInt('quiet_hours_end_minute', serverPrefs['quiet_hours_end_minute'] ?? 0);
        
        // Log pH level alerts specifically for debugging
        print('pH level alerts enabled: ${serverPrefs['ph_level_alerts_enabled']}');
        print('Local prefs pH setting: ${prefs.getBool('ph_level_alerts_enabled')}');
        
        print('Notification preferences synced from server to local storage');
      } else {
        print('No notification preferences found on server or failed to retrieve');
      }
    } catch (e) {
      print('Error syncing notification preferences from server: $e');
    }
  }
} 