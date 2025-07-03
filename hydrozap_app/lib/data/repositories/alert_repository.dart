import 'dart:async';
import 'package:hydrozap_app/core/models/alert_model.dart';
import 'package:hydrozap_app/core/models/pending_sync_item.dart';
import 'package:hydrozap_app/core/services/connectivity_service.dart';
import 'package:hydrozap_app/data/local/hive_service.dart';
import 'package:hydrozap_app/data/remote/firebase_service.dart';

/// Repository for alert-related operations with offline-first support
class AlertRepository {
  final HiveService _hiveService = HiveService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Stream controller for alerts
  final _alertsStreamController = StreamController<List<Alert>>.broadcast();
  
  // Stream of alerts
  Stream<List<Alert>> get alertsStream => _alertsStreamController.stream;
  
  // Current list of alerts
  List<Alert> _cachedAlerts = [];
  
  AlertRepository() {
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        // Sync alerts when back online
        _syncAllAlerts();
      }
    });
  }
  
  /// Initialize the repository
  Future<void> initialize() async {
    // Load cached alerts from local storage
    _loadCachedAlerts();
    
    // Check if online, then sync with remote
    if (_connectivityService.isConnected) {
      _syncAllAlerts();
    }
  }
  
  /// Load cached alerts from local storage
  void _loadCachedAlerts() {
    _cachedAlerts = _hiveService.getAllAlerts();
    _notifyListeners();
  }
  
  /// Notify listeners of changes
  void _notifyListeners() {
    _alertsStreamController.add(_cachedAlerts);
  }
  
  /// Get all alerts
  Future<List<Alert>> getAllAlerts() async {
    // Return cached alerts (local storage)
    return _cachedAlerts;
  }
  
  /// Get alerts for a specific device
  Future<List<Alert>> getAlertsForDevice(String deviceId) async {
    // If online, try to sync first
    if (_connectivityService.isConnected) {
      await _syncAlertsForDevice(deviceId);
    }
    
    // Return filtered alerts from cache
    return _cachedAlerts.where((alert) => alert.deviceId == deviceId).toList();
  }
  
  /// Get an alert by ID
  Future<Alert?> getAlert(String id) async {
    // Check local cache first
    Alert? alert = _hiveService.getAlert(id);
    
    // If online and alert not found or synced is false, try to fetch from remote
    if (_connectivityService.isConnected && (alert == null || !alert.synced)) {
      try {
        // Find the device ID
        final deviceId = alert?.deviceId ?? '';
        
        // Fetch all alerts for the device
        final alerts = await _firebaseService.fetchAlerts(deviceId);
        final remoteAlert = alerts.firstWhere((a) => a.alertId == id, orElse: () => alert!);
        
        // Update local cache
        await _hiveService.saveAlert(remoteAlert);
        
        // Update cached alerts
        int index = _cachedAlerts.indexWhere((a) => a.alertId == id);
        if (index != -1) {
          _cachedAlerts[index] = remoteAlert;
        } else {
          _cachedAlerts.add(remoteAlert);
        }
        
        _notifyListeners();
        
        return remoteAlert;
      } catch (e) {
        // If remote fetch fails, return local alert
        return alert;
      }
    }
    
    return alert;
  }
  
  /// Create a new alert
  Future<Alert> createAlert(Alert alert) async {
    // If online, create on remote and update local
    if (_connectivityService.isConnected) {
      try {
        final createdAlert = await _firebaseService.createAlert(alert);
        
        // Update local cache
        await _hiveService.saveAlert(createdAlert);
        
        // Update cached alerts
        _cachedAlerts.add(createdAlert);
        _notifyListeners();
        
        return createdAlert;
      } catch (e) {
        // If remote creation fails, save locally with synced = false
        return _saveAlertOffline(alert);
      }
    } else {
      // If offline, save locally with synced = false
      return _saveAlertOffline(alert);
    }
  }
  
  /// Save an alert offline with pending sync
  Future<Alert> _saveAlertOffline(Alert alert) async {
    // Set synced to false
    final offlineAlert = alert.copyWith(synced: false);
    
    // Save to local storage
    await _hiveService.saveAlert(offlineAlert);
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: alert.alertId,
      itemType: 'alert',
      operation: 'create',
      data: offlineAlert.toJson(),
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached alerts
    _cachedAlerts.add(offlineAlert);
    _notifyListeners();
    
    return offlineAlert;
  }
  
  /// Update an existing alert
  Future<void> updateAlert(Alert alert) async {
    // If online, update on remote and local
    if (_connectivityService.isConnected) {
      try {
        await _firebaseService.updateAlert(alert);
        
        // Update local cache with synced = true
        final updatedAlert = alert.copyWith(synced: true);
        await _hiveService.saveAlert(updatedAlert);
        
        // Update cached alerts
        int index = _cachedAlerts.indexWhere((a) => a.alertId == alert.alertId);
        if (index != -1) {
          _cachedAlerts[index] = updatedAlert;
        }
        
        _notifyListeners();
      } catch (e) {
        // If remote update fails, update locally with synced = false
        await _updateAlertOffline(alert);
      }
    } else {
      // If offline, update locally with synced = false
      await _updateAlertOffline(alert);
    }
  }
  
  /// Update an alert offline with pending sync
  Future<void> _updateAlertOffline(Alert alert) async {
    // Set synced to false
    final offlineAlert = alert.copyWith(synced: false);
    
    // Save to local storage
    await _hiveService.saveAlert(offlineAlert);
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: alert.alertId,
      itemType: 'alert',
      operation: 'update',
      data: offlineAlert.toJson(),
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached alerts
    int index = _cachedAlerts.indexWhere((a) => a.alertId == alert.alertId);
    if (index != -1) {
      _cachedAlerts[index] = offlineAlert;
    }
    
    _notifyListeners();
  }
  
  /// Delete an alert
  Future<void> deleteAlert(String id) async {
    // If online, delete from remote and local
    if (_connectivityService.isConnected) {
      try {
        await _firebaseService.deleteAlert(id);
        
        // Delete from local storage
        await _hiveService.deleteAlert(id);
        
        // Update cached alerts
        _cachedAlerts.removeWhere((a) => a.alertId == id);
        _notifyListeners();
      } catch (e) {
        // If remote deletion fails, mark for deletion locally
        await _deleteAlertOffline(id);
      }
    } else {
      // If offline, mark for deletion locally
      await _deleteAlertOffline(id);
    }
  }
  
  /// Mark an alert for deletion offline with pending sync
  Future<void> _deleteAlertOffline(String id) async {
    // Get the alert
    final alert = _hiveService.getAlert(id);
    if (alert == null) return;
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: id,
      itemType: 'alert',
      operation: 'delete',
      data: {'alert_id': id},
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached alerts
    int index = _cachedAlerts.indexWhere((a) => a.alertId == id);
    if (index != -1) {
      _cachedAlerts[index] = alert.copyWith(synced: false);
    }
    
    _notifyListeners();
  }
  
  /// Sync alerts for a specific device with remote
  Future<void> _syncAlertsForDevice(String deviceId) async {
    try {
      // Fetch alerts for the device from remote
      final remoteAlerts = await _firebaseService.fetchAlerts(deviceId);
      
      // Process pending sync items
      await _processPendingSyncItems();
      
      // Update local storage with remote alerts
      for (var alert in remoteAlerts) {
        await _hiveService.saveAlert(alert);
      }
      
      // Update cached alerts (keep alerts for other devices)
      _cachedAlerts.removeWhere((a) => a.deviceId == deviceId);
      _cachedAlerts.addAll(remoteAlerts);
      _notifyListeners();
    } catch (e) {
      // If sync fails, use local alerts
      _loadCachedAlerts();
    }
  }
  
  /// Sync all alerts from all devices
  Future<void> _syncAllAlerts() async {
    try {
      // Process pending sync items first
      await _processPendingSyncItems();
      
      // Get all devices
      final devices = _hiveService.getAllDevices();
      
      // Updated alert list
      List<Alert> allAlerts = [];
      
      // Fetch alerts for each device
      for (var device in devices) {
        try {
          final alerts = await _firebaseService.fetchAlerts(device.id);
          
          // Update local storage
          for (var alert in alerts) {
            await _hiveService.saveAlert(alert);
          }
          
          allAlerts.addAll(alerts);
        } catch (e) {
          // If fetch fails for a device, keep local alerts for that device
          final localAlerts = _cachedAlerts.where((a) => a.deviceId == device.id).toList();
          allAlerts.addAll(localAlerts);
        }
      }
      
      // Update cached alerts
      _cachedAlerts = allAlerts;
      _notifyListeners();
    } catch (e) {
      // If sync fails completely, use local alerts
      _loadCachedAlerts();
    }
  }
  
  /// Process pending sync items
  Future<void> _processPendingSyncItems() async {
    try {
      // Get all pending sync items for alerts
      final pendingItems = _hiveService.getPendingSyncItemsByType('alert');
      
      for (var item in pendingItems) {
        try {
          switch (item.operation) {
            case 'create':
              // Create alert on remote
              final alert = Alert.fromJson(item.data);
              await _firebaseService.createAlert(alert);
              break;
            case 'update':
              // Update alert on remote
              final alert = Alert.fromJson(item.data);
              await _firebaseService.updateAlert(alert);
              break;
            case 'delete':
              // Delete alert on remote
              await _firebaseService.deleteAlert(item.id);
              // Remove from local storage
              await _hiveService.deleteAlert(item.id);
              break;
          }
          
          // Remove processed item from pending sync
          await _hiveService.deletePendingSyncItem(item.id);
        } catch (e) {
          // Mark sync as failed for this item
          await _hiveService.savePendingSyncItem(item.markSyncFailed());
        }
      }
    } catch (e) {
      // Handle sync errors
    }
  }
  
  /// Force sync with remote
  Future<void> forceSync() async {
    if (_connectivityService.isConnected) {
      await _syncAllAlerts();
    }
  }
  
  /// Mark an alert as read
  Future<void> markAsRead(String id) async {
    // Get the alert
    final alert = await getAlert(id);
    if (alert == null) return;
    
    // Update the alert
    final updatedAlert = alert.copyWith(status: 'read');
    await updateAlert(updatedAlert);
  }
  
  /// Dispose of resources
  void dispose() {
    _alertsStreamController.close();
  }
}
