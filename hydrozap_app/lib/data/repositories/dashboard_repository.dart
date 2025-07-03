import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hydrozap_app/core/services/connectivity_service.dart';
import 'package:hydrozap_app/data/local/hive_service.dart';
import 'package:hydrozap_app/data/remote/firebase_service.dart';
import 'package:hydrozap_app/core/api/api_service.dart';

/// Repository for dashboard-related operations with offline-first support
class DashboardRepository {
  final HiveService _hiveService;
  final FirebaseService _firebaseService;
  final ConnectivityService _connectivityService;
  final ApiService _apiService = ApiService();
  
  // Box name for dashboard counts
  static const String _dashboardCountsBoxName = 'dashboard_counts';
  
  // Keys for different counts
  static const String _devicesCountKey = 'devices_count';
  static const String _growsCountKey = 'grows_count';
  static const String _alertsCountKey = 'alerts_count';
  
  DashboardRepository({
    required HiveService hiveService,
    required FirebaseService firebaseService,
    required ConnectivityService connectivityService,
  }) : _hiveService = hiveService,
       _firebaseService = firebaseService, 
       _connectivityService = connectivityService;
  
  /// Initialize the repository
  Future<void> initialize() async {
    // Ensure the dashboard counts box is open
    if (!Hive.isBoxOpen(_dashboardCountsBoxName)) {
      await Hive.openBox(_dashboardCountsBoxName);
    }
  }
  
  /// Get all dashboard counts at once with offline support
  Future<Map<String, int>> getAllCounts(String userId) async {
    if (_connectivityService.isConnected) {
      try {
        // Try to fetch from remote API
        final counts = await _apiService.getDashboardCounts(userId);
        
        // Cache the counts
        await _saveCount(_devicesCountKey, counts['deviceCount'] ?? 0);
        await _saveCount(_growsCountKey, counts['growCount'] ?? 0);
        await _saveCount(_alertsCountKey, counts['alertCount'] ?? 0);
        
        return {
          'devices': counts['deviceCount'] ?? 0,
          'grows': counts['growCount'] ?? 0,
          'alerts': counts['alertCount'] ?? 0,
        };
      } catch (e) {
        // If remote fetch fails, return cached counts
        return getCachedCounts();
      }
    } else {
      // If offline, return cached counts
      return getCachedCounts();
    }
  }
  
  /// Get device count with offline support
  Future<int> getDevicesCount(String userId) async {
    if (_connectivityService.isConnected) {
      try {
        // Get all counts from API
        final counts = await getAllCounts(userId);
        return counts['devices'] ?? 0;
      } catch (e) {
        // If that fails, try the original approach
        try {
          // Try to fetch from remote
          final devices = await _firebaseService.fetchDevices(userId);
          final count = devices.length;
          
          // Cache the count
          await _saveCount(_devicesCountKey, count);
          
          return count;
        } catch (e) {
          // If remote fetch fails, return cached count
          return _getCount(_devicesCountKey);
        }
      }
    } else {
      // If offline, return cached count
      return _getCount(_devicesCountKey);
    }
  }
  
  /// Get grows count with offline support
  Future<int> getGrowsCount(String userId) async {
    if (_connectivityService.isConnected) {
      try {
        // Get all counts from API
        final counts = await getAllCounts(userId);
        return counts['grows'] ?? 0;
      } catch (e) {
        // If that fails, try the original approach
        try {
          // Try to fetch from remote
          final grows = await _firebaseService.fetchGrows(userId);
          final count = grows.length;
          
          // Cache the count
          await _saveCount(_growsCountKey, count);
          
          return count;
        } catch (e) {
          // If remote fetch fails, return cached count
          return _getCount(_growsCountKey);
        }
      }
    } else {
      // If offline, return cached count
      return _getCount(_growsCountKey);
    }
  }
  
  /// Get alerts count with offline support
  Future<int> getAlertsCount() async {
    if (_connectivityService.isConnected) {
      try {
        // Use the most recent cached userId
        final devices = _hiveService.getAllDevices();
        if (devices.isNotEmpty) {
          String userId = devices.first.userId;
          
          // Get all counts from API
          final counts = await getAllCounts(userId);
          return counts['alerts'] ?? 0;
        }
        
        // If no userId found, use the original approach
        int totalAlerts = 0;
        for (var device in devices) {
          final alerts = await _firebaseService.fetchAlerts(device.id);
          totalAlerts += alerts.length;
        }
        
        // Cache the count
        await _saveCount(_alertsCountKey, totalAlerts);
        
        return totalAlerts;
      } catch (e) {
        // If remote fetch fails, return cached count
        return _getCount(_alertsCountKey);
      }
    } else {
      // If offline, return cached count
      return _getCount(_alertsCountKey);
    }
  }
  
  /// Get count from local cache
  int _getCount(String key) {
    final box = Hive.box(_dashboardCountsBoxName);
    return box.get(key, defaultValue: 0);
  }
  
  /// Save count to local cache
  Future<void> _saveCount(String key, int count) async {
    final box = Hive.box(_dashboardCountsBoxName);
    await box.put(key, count);
  }
  
  /// Get cached dashboard counts for offline use
  Map<String, int> getCachedCounts() {
    return {
      'devices': _getCount(_devicesCountKey),
      'grows': _getCount(_growsCountKey),
      'alerts': _getCount(_alertsCountKey),
    };
  }
} 