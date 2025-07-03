// providers/alert_provider.dart
import 'package:flutter/material.dart';
import 'package:hydrozap_app/core/models/alert_model.dart';
import '../core/api/api_service.dart';

class AlertProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Alert> _alerts = [];
  bool _isLoading = false;

  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;

  // Fetch Alerts by User ID
  Future<void> fetchAlerts(String userId) async {
    print("🔄 Fetching alerts for user ID: $userId");
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.getAlerts(userId);
    print("✅ Fetched ${response.length} alerts");
    
    if (response.isNotEmpty) {
      print("🔍 First alert sample: ${response[0].toJson()}");
    }
    
    _alerts = response;
    _isLoading = false;
    notifyListeners();
  }

  // Get an Alert by ID
  Alert? getAlertById(String alertId) {
    try {
      
      
      final alert = _alerts.firstWhere((alert) => alert.alertId == alertId);
     
      
      return alert;
    } catch (e) {
      print("❌ Error finding alert with ID $alertId: $e");
      return null;
    }
  }

  // Acknowledge an Alert
  Future<bool> acknowledgeAlert(String userId, String alertId) async {
  
    
    // Create update data with status set to read
    final updateData = {
      'status': 'read'
    };
    
    // First ensure we have a valid alert ID
    Alert? existingAlert = getAlertById(alertId);
    if (existingAlert == null) {
     
      return false;
    }
    

    final success = await _apiService.updateAlert(alertId, userId, updateData);
    
    if (success) {
      // Update the local alert in memory
      int index = _alerts.indexWhere((alert) => alert.alertId == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(status: 'read');
        // Make sure to notify listeners to update the UI
        notifyListeners();
        print("✅ Successfully updated local alert state");
      } else {
        print("⚠️ Warning: Alert found in API but not in local list");
        // Refresh alerts from server to ensure list is up to date
        await fetchAlerts(userId);
      }
      return true;
    } else {
      // If the API call failed, refresh alerts from server
      await fetchAlerts(userId);
      return false;
    }
  }

  // Acknowledge multiple alerts at once
  Future<Map<String, bool>> acknowledgeMultipleAlerts(String userId, List<String> alertIds) async {
   
    Map<String, bool> results = {};
    List<Future<bool>> operations = [];
    
    // Create tasks for each alert acknowledgment
    for (final alertId in alertIds) {
      operations.add(
        _apiService.updateAlert(alertId, userId, {'status': 'read'}).then((success) {
          results[alertId] = success;
          return success;
        })
      );
    }
    
    // Wait for all operations to complete
    await Future.wait(operations);
    
    // Update local state for successfully acknowledged alerts
    bool anySuccess = results.values.contains(true);
    if (anySuccess) {
      for (final alertId in alertIds) {
        if (results[alertId] == true) {
          int index = _alerts.indexWhere((alert) => alert.alertId == alertId);
          if (index != -1) {
            _alerts[index] = _alerts[index].copyWith(status: 'read');
          }
        }
      }
      
      // Notify listeners only once after all updates
      notifyListeners();
    }
    
    return results;
  }

  // Delete multiple alerts at once
  Future<Map<String, bool>> deleteMultipleAlerts(String userId, List<String> alertIds) async {   
    Map<String, bool> results = {};
    List<Future<bool>> operations = [];
    
    // Create tasks for each alert deletion
    for (final alertId in alertIds) {
      operations.add(
        _apiService.deleteAlert(alertId, userId).then((success) {
          results[alertId] = success;
          return success;
        })
      );
    }
    
    // Wait for all operations to complete
    await Future.wait(operations);
    
    // Update local state by removing deleted alerts
    bool anySuccess = results.values.contains(true);
    if (anySuccess) {
      _alerts.removeWhere((alert) => 
        alertIds.contains(alert.alertId) && results[alert.alertId] == true
      );
      
      // Notify listeners only once after all updates
      notifyListeners();
    }
    
    return results;
  }

  // Filter Alerts
  List<Alert> filterAlerts({
    String? deviceId,
    String? severity,
    bool? onlyUnacknowledged,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    // Parse severity if it's a comma-separated string
    List<String> severities = [];
    if (severity != null && severity.isNotEmpty) {
      severities = severity.split(',');
    }
    
    return _alerts.where((alert) {
      // Filter by device
      if (deviceId != null && alert.deviceId != deviceId) {
        return false;
      }
      
      // Filter by severity
      if (severities.isNotEmpty) {
        String alertSeverity = _getSeverity(alert.alertType);
        if (!severities.contains(alertSeverity)) {
          return false;
        }
      }
      
      // Filter by acknowledged status
      if (onlyUnacknowledged == true && alert.status == 'read') {
        return false;
      }
      
      // Filter by date range
      if (fromDate != null || toDate != null) {
        try {
          final alertDate = DateTime.parse(alert.timestamp);
          if (fromDate != null && alertDate.isBefore(fromDate)) {
            return false;
          }
          if (toDate != null && alertDate.isAfter(toDate)) {
            return false;
          }
        } catch (e) {
          // If timestamp parsing fails, include the alert
        }
      }
      
      return true;
    }).toList();
  }

  // Trigger a New Alert
  Future<bool> triggerAlert(Map<String, dynamic> alertData) async {
    final success = await _apiService.triggerAlert(alertData);
    if (success) {
      fetchAlerts(alertData['user_id']);
    }
    return success;
  }

  // Delete an Alert
  Future<bool> deleteAlert(String userId, String alertId) async {
    final success = await _apiService.deleteAlert(alertId, userId);
    if (success) {
      // Remove from local list
      _alerts.removeWhere((alert) => alert.alertId == alertId);
      notifyListeners();
    }
    return success;
  }

  // Helper function to determine severity based on alert type
  String _getSeverity(String alertType) {
    if (alertType.contains('high') || alertType.contains('low')) {
      return 'warning';
    } else if (alertType.contains('offline') || alertType.contains('error')) {
      return 'critical';
    }
    return 'info';
  }

  // Group alerts by date
  Map<String, List<Alert>> getGroupedAlerts({
    String? deviceId,
    String? severity,
    bool? onlyUnacknowledged,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    // First apply all filters
    final filteredAlerts = filterAlerts(
      deviceId: deviceId,
      severity: severity,
      onlyUnacknowledged: onlyUnacknowledged,
      fromDate: fromDate,
      toDate: toDate,
    );
    
    // Sort alerts by timestamp (newest first)
    filteredAlerts.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.timestamp);
        final dateB = DateTime.parse(b.timestamp);
        return dateB.compareTo(dateA); // Descending order (newest first)
      } catch (e) {
        return 0; // Keep original order if parsing fails
      }
    });
    
    // Group alerts by date
    final Map<String, List<Alert>> groupedAlerts = {};
    
    for (final alert in filteredAlerts) {
      try {
        final date = DateTime.parse(alert.timestamp);
        final now = DateTime.now();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        
        String groupKey;
        
        // Today
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          groupKey = 'Today';
        }
        // Yesterday
        else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
          groupKey = 'Yesterday';
        }
        // This week (within last 7 days)
        else if (now.difference(date).inDays < 7) {
          groupKey = 'This Week';
        }
        // This month
        else if (date.year == now.year && date.month == now.month) {
          groupKey = 'This Month';
        }
        // Last month
        else if ((date.year == now.year && date.month == now.month - 1) || 
                (now.month == 1 && date.month == 12 && date.year == now.year - 1)) {
          groupKey = 'Last Month';
        }
        // This year
        else if (date.year == now.year) {
          groupKey = 'This Year';
        }
        // Older
        else {
          groupKey = 'Older';
        }
        
        if (!groupedAlerts.containsKey(groupKey)) {
          groupedAlerts[groupKey] = [];
        }
        
        groupedAlerts[groupKey]!.add(alert);
      } catch (e) {
        // If date parsing fails, add to "Other" group
        if (!groupedAlerts.containsKey('Other')) {
          groupedAlerts['Other'] = [];
        }
        groupedAlerts['Other']!.add(alert);
      }
    }
    
    return groupedAlerts;
  }
}
