import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../components/custom_card.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/services/push_notification_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/utils/logger.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  String? _userId;
  final ApiService _apiService = ApiService();
  
  // Notification toggles
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  
  // System notification toggles
  bool _systemAlertsEnabled = true;
  bool _maintenanceAlertsEnabled = true;
  bool _updateAlertsEnabled = true;
  
  // Hydroponics notification toggles
  bool _nutrientLevelAlertsEnabled = true;
  bool _phLevelAlertsEnabled = true;
  bool _waterLevelAlertsEnabled = true;
  bool _temperatureAlertsEnabled = true;
  bool _harvestRemindersEnabled = true;
  bool _scheduledMaintenanceEnabled = true;

  // Quiet hours
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _quietHoursEnabled = false;

  @override
  void initState() {
    super.initState();
    _getUserIdAndLoadSettings();
  }

  Future<void> _getUserIdAndLoadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getString('user_id');
      });
      await _loadSettings();
    } catch (e) {
      logger.e('Error getting user ID: $e');
      // Continue with local settings if user ID not available
      await _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    // Load settings from SharedPreferences and Firebase
    try {
      final prefs = await SharedPreferences.getInstance();
      bool prefsLoaded = false;
      
      // Try to load from Firebase first (server preferences take priority)
      if (_userId != null && _userId!.isNotEmpty) {
        try {
          final serverPrefs = await _apiService.getNotificationPreferences(_userId!);
          if (serverPrefs != null && serverPrefs.isNotEmpty) {
            setState(() {
              // Load notification channel preferences
              _pushNotificationsEnabled = serverPrefs['push_notifications_enabled'] ?? true;
              _emailNotificationsEnabled = serverPrefs['email_notifications_enabled'] ?? true;
              _smsNotificationsEnabled = serverPrefs['sms_notifications_enabled'] ?? false;
              
              // Load system notification preferences
              _systemAlertsEnabled = serverPrefs['system_alerts_enabled'] ?? true;
              _maintenanceAlertsEnabled = serverPrefs['maintenance_alerts_enabled'] ?? true;
              _updateAlertsEnabled = serverPrefs['update_alerts_enabled'] ?? true;
              
              // Load hydroponics notification preferences
              _nutrientLevelAlertsEnabled = serverPrefs['nutrient_level_alerts_enabled'] ?? true;
              _phLevelAlertsEnabled = serverPrefs['ph_level_alerts_enabled'] ?? true;
              _waterLevelAlertsEnabled = serverPrefs['water_level_alerts_enabled'] ?? true;
              _temperatureAlertsEnabled = serverPrefs['temperature_alerts_enabled'] ?? true;
              _harvestRemindersEnabled = serverPrefs['harvest_reminders_enabled'] ?? true;
              _scheduledMaintenanceEnabled = serverPrefs['scheduled_maintenance_enabled'] ?? true;
              
              // Load quiet hours preferences
              _quietHoursEnabled = serverPrefs['quiet_hours_enabled'] ?? false;
              
              final quietHoursStartHour = serverPrefs['quiet_hours_start_hour'] ?? 22;
              final quietHoursStartMinute = serverPrefs['quiet_hours_start_minute'] ?? 0;
              _quietHoursStart = TimeOfDay(hour: quietHoursStartHour, minute: quietHoursStartMinute);
              
              final quietHoursEndHour = serverPrefs['quiet_hours_end_hour'] ?? 7;
              final quietHoursEndMinute = serverPrefs['quiet_hours_end_minute'] ?? 0;
              _quietHoursEnd = TimeOfDay(hour: quietHoursEndHour, minute: quietHoursEndMinute);
              
              _isLoading = false;
            });
            
            // Save server preferences to local storage for offline access
            _syncServerPrefsToLocal(serverPrefs);
            
            prefsLoaded = true;
            logger.i('Notification preferences loaded from server');
          }
        } catch (e) {
          logger.e('Error loading notification preferences from server: $e');
          // Continue with local preferences if server preferences not available
        }
      }
      
      // Fall back to SharedPreferences if server preferences not available
      if (!prefsLoaded) {
      setState(() {
        // Load notification channel preferences
        _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
        _emailNotificationsEnabled = prefs.getBool('email_notifications_enabled') ?? true;
        _smsNotificationsEnabled = prefs.getBool('sms_notifications_enabled') ?? false;
        
        // Load system notification preferences
        _systemAlertsEnabled = prefs.getBool('system_alerts_enabled') ?? true;
        _maintenanceAlertsEnabled = prefs.getBool('maintenance_alerts_enabled') ?? true;
        _updateAlertsEnabled = prefs.getBool('update_alerts_enabled') ?? true;
        
        // Load hydroponics notification preferences
        _nutrientLevelAlertsEnabled = prefs.getBool('nutrient_level_alerts_enabled') ?? true;
        _phLevelAlertsEnabled = prefs.getBool('ph_level_alerts_enabled') ?? true;
        _waterLevelAlertsEnabled = prefs.getBool('water_level_alerts_enabled') ?? true;
        _temperatureAlertsEnabled = prefs.getBool('temperature_alerts_enabled') ?? true;
        _harvestRemindersEnabled = prefs.getBool('harvest_reminders_enabled') ?? true;
        _scheduledMaintenanceEnabled = prefs.getBool('scheduled_maintenance_enabled') ?? true;
        
        // Load quiet hours preferences
        _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
        
        final quietHoursStartHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
        final quietHoursStartMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
        _quietHoursStart = TimeOfDay(hour: quietHoursStartHour, minute: quietHoursStartMinute);
        
        final quietHoursEndHour = prefs.getInt('quiet_hours_end_hour') ?? 7;
        final quietHoursEndMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;
        _quietHoursEnd = TimeOfDay(hour: quietHoursEndHour, minute: quietHoursEndMinute);
        
        _isLoading = false;
      });
        logger.i('Notification preferences loaded from local storage');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notification settings: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sync server preferences to local storage
  Future<void> _syncServerPrefsToLocal(Map<String, dynamic> serverPrefs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
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
      
      logger.i('Server preferences synced to local storage');
    } catch (e) {
      logger.e('Error syncing server preferences to local storage: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Log pH level alert setting for debugging
      logger.d('Saving pH level alert setting: $_phLevelAlertsEnabled');
      
      // Save notification channel preferences
      await prefs.setBool('push_notifications_enabled', _pushNotificationsEnabled);
      await prefs.setBool('email_notifications_enabled', _emailNotificationsEnabled);
      await prefs.setBool('sms_notifications_enabled', _smsNotificationsEnabled);
      
      // Save system notification preferences
      await prefs.setBool('system_alerts_enabled', _systemAlertsEnabled);
      await prefs.setBool('maintenance_alerts_enabled', _maintenanceAlertsEnabled);
      await prefs.setBool('update_alerts_enabled', _updateAlertsEnabled);
      
      // Save hydroponics notification preferences
      await prefs.setBool('nutrient_level_alerts_enabled', _nutrientLevelAlertsEnabled);
      await prefs.setBool('ph_level_alerts_enabled', _phLevelAlertsEnabled);
      await prefs.setBool('water_level_alerts_enabled', _waterLevelAlertsEnabled);
      await prefs.setBool('temperature_alerts_enabled', _temperatureAlertsEnabled);
      await prefs.setBool('harvest_reminders_enabled', _harvestRemindersEnabled);
      await prefs.setBool('scheduled_maintenance_enabled', _scheduledMaintenanceEnabled);
      
      // Save quiet hours preferences
      await prefs.setBool('quiet_hours_enabled', _quietHoursEnabled);
      await prefs.setInt('quiet_hours_start_hour', _quietHoursStart.hour);
      await prefs.setInt('quiet_hours_start_minute', _quietHoursStart.minute);
      await prefs.setInt('quiet_hours_end_hour', _quietHoursEnd.hour);
      await prefs.setInt('quiet_hours_end_minute', _quietHoursEnd.minute);
      
      // Double-check pH level alert setting was saved
      bool? savedPHSetting = prefs.getBool('ph_level_alerts_enabled');
      logger.d('Verified pH level alert setting in SharedPreferences: $savedPHSetting');
      
      // Save settings to Firebase if logged in
      if (_userId != null && _userId!.isNotEmpty) {
        await _saveSettingsToFirebase();
      }
      
      // Sync push notification settings with backend
      await _syncPushNotificationSettings();

      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.moss,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // New function to save notification settings to Firebase
  Future<void> _saveSettingsToFirebase() async {
    try {
      // Create a map of all notification preferences
      final Map<String, dynamic> preferences = {
        // Notification channels
        'push_notifications_enabled': _pushNotificationsEnabled,
        'email_notifications_enabled': _emailNotificationsEnabled,
        'sms_notifications_enabled': _smsNotificationsEnabled,
        
        // System notifications
        'system_alerts_enabled': _systemAlertsEnabled,
        'maintenance_alerts_enabled': _maintenanceAlertsEnabled,
        'update_alerts_enabled': _updateAlertsEnabled,
        
        // Hydroponics notifications
        'nutrient_level_alerts_enabled': _nutrientLevelAlertsEnabled,
        'ph_level_alerts_enabled': _phLevelAlertsEnabled,
        'water_level_alerts_enabled': _waterLevelAlertsEnabled,
        'temperature_alerts_enabled': _temperatureAlertsEnabled,
        'harvest_reminders_enabled': _harvestRemindersEnabled,
        'scheduled_maintenance_enabled': _scheduledMaintenanceEnabled,
        
        // Quiet hours
        'quiet_hours_enabled': _quietHoursEnabled,
        'quiet_hours_start_hour': _quietHoursStart.hour,
        'quiet_hours_start_minute': _quietHoursStart.minute,
        'quiet_hours_end_hour': _quietHoursEnd.hour,
        'quiet_hours_end_minute': _quietHoursEnd.minute,
        
        // Add timestamp
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      // Log the pH alert setting specifically for debugging
      logger.d('Saving pH alert setting to Firebase: ${_phLevelAlertsEnabled}');
      logger.d('All notification settings: $preferences');
      
      // Use the API service to update preferences
      final success = await _apiService.updateNotificationPreferences(_userId!, preferences);
      
      if (success) {
        logger.i('Notification preferences saved to Firebase successfully');
      } else {
        logger.e('Error saving notification preferences to Firebase via API service');
        // Fall back to local storage if server update fails
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ph_level_alerts_enabled', _phLevelAlertsEnabled);
        logger.d('Saved pH level alert setting to local storage as fallback: ${_phLevelAlertsEnabled}');
      }
    } catch (e) {
      logger.e('Error saving notification preferences to Firebase: $e');
      // Don't show error to user as this is a background operation
      
      // Fall back to local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ph_level_alerts_enabled', _phLevelAlertsEnabled);
        logger.d('Saved pH level alert setting to local storage as fallback: ${_phLevelAlertsEnabled}');
      } catch (e2) {
        logger.e('Failed to save to local storage as well: $e2');
      }
    }
  }

  // Sync push notification settings with backend
  Future<void> _syncPushNotificationSettings() async {
    // Only proceed if user is logged in
    if (_userId == null || _userId!.isEmpty) {
      logger.w('Cannot sync notification settings: No user ID available');
      return;
    }
    
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final String? fcmToken = notificationProvider.fcmToken;
      
      if (fcmToken == null || fcmToken.isEmpty) {
        logger.w('No FCM token available for syncing');
        return;
      }
      
      if (_pushNotificationsEnabled) {
        // Register FCM token with backend
        final success = await _apiService.registerFcmToken(_userId!, fcmToken);
        if (success) {
          logger.i('FCM token registered successfully with backend');
        } else {
          logger.w('Failed to register FCM token with backend');
        }
      } else {
        // Unregister FCM token from backend
        final success = await _apiService.unregisterFcmToken(_userId!, fcmToken);
        if (success) {
          logger.i('FCM token unregistered successfully from backend');
        } else {
          logger.w('Failed to unregister FCM token from backend');
        }
      }
    } catch (e) {
      logger.e('Error syncing push notification settings: $e');
    }
  }
  
  // Test push notification (helpful for verifying FCM setup)
  Future<void> _testPushNotification() async {
    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to test notifications'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final baseUrl = "http://192.168.100.204:8000"; // Replace with actual base URL
      final response = await http.post(
        Uri.parse('$baseUrl/test-fcm-notification/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": _userId,
          "title": "Test Notification",
          "body": "This is a test notification from HydroZap",
        }),
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent successfully'),
            backgroundColor: AppColors.moss,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _selectQuietHoursTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _quietHoursStart : _quietHoursEnd,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.moss,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _quietHoursStart = pickedTime;
        } else {
          _quietHoursEnd = pickedTime;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.forest,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.moss))
          : Container(
              color: Colors.grey[100],
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Notification Channels'),
                        _buildNotificationChannelsSection(),
                        const SizedBox(height: 24),
                        
                        _buildSectionHeader('Hydroponics Notifications'),
                        _buildHydroponicsNotificationsSection(),
                        const SizedBox(height: 24),
                        
                        _buildSectionHeader('Quiet Hours'),
                        _buildQuietHoursSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationChannelsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'Push Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Receive notifications on this device',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _pushNotificationsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _pushNotificationsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.moss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemNotificationsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'System Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Important system notifications',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _systemAlertsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _systemAlertsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Maintenance Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Planned system maintenance',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _maintenanceAlertsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _maintenanceAlertsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.build,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Update Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'New app features and updates',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _updateAlertsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _updateAlertsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.system_update,
                  color: AppColors.moss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydroponicsNotificationsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'Nutrient Level Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Notifications when nutrient levels need attention',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _nutrientLevelAlertsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _nutrientLevelAlertsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.opacity,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'pH Level Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Notifications when pH levels are out of range',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _phLevelAlertsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _phLevelAlertsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.science,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Water Level Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Notifications when water levels are low',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _waterLevelAlertsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _waterLevelAlertsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Temperature Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Notifications when temperature is out of range',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _temperatureAlertsEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _temperatureAlertsEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.thermostat,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Harvest Reminders',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Reminders when crops are ready to harvest',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _harvestRemindersEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _harvestRemindersEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Scheduled Maintenance',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Reminders for system maintenance tasks',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _scheduledMaintenanceEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _scheduledMaintenanceEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppColors.moss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text(
                'Enable Quiet Hours',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Pause non-critical notifications during specified hours',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _quietHoursEnabled,
              activeColor: AppColors.moss,
              onChanged: (value) {
                setState(() {
                  _quietHoursEnabled = value;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.moss.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.do_not_disturb_on,
                  color: AppColors.moss,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quiet Hours Start',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeOfDay(_quietHoursStart),
                        style: TextStyle(
                          fontSize: 13,
                          color: _quietHoursEnabled
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _quietHoursEnabled
                        ? () => _selectQuietHoursTime(context, true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.moss,
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Set Time'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quiet Hours End',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeOfDay(_quietHoursEnd),
                        style: TextStyle(
                          fontSize: 13,
                          color: _quietHoursEnabled
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _quietHoursEnabled
                        ? () => _selectQuietHoursTime(context, false)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.moss,
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Set Time'),
                  ),
                ],
              ),
            ),
            if (_quietHoursEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[100]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[800],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Critical notifications for system failures and other emergencies will still be delivered during quiet hours',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 