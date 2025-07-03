import 'dart:async';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/core/models/pending_sync_item.dart';
import 'package:hydrozap_app/core/services/connectivity_service.dart';
import 'package:hydrozap_app/data/local/hive_service.dart';
import 'package:hydrozap_app/data/remote/firebase_service.dart';
import 'package:hydrozap_app/data/local/shared_prefs.dart';

/// Repository for device-related operations with offline-first support
class DeviceRepository {
  final HiveService _hiveService = HiveService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Stream controller for devices
  final _devicesStreamController = StreamController<List<DeviceModel>>.broadcast();
  
  // Stream of devices
  Stream<List<DeviceModel>> get devicesStream => _devicesStreamController.stream;
  
  // Current list of devices
  List<DeviceModel> _cachedDevices = [];
  
  DeviceRepository() {
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        // Sync devices when back online
        _syncDevices();
      }
    });
  }
  
  /// Initialize the repository
  Future<void> initialize() async {
    // Load cached devices from local storage
    _loadCachedDevices();
    
    // Check if online, then sync with remote
    if (_connectivityService.isConnected) {
      _syncDevices();
    }
  }
  
  /// Load cached devices from local storage
  void _loadCachedDevices() {
    _cachedDevices = _hiveService.getAllDevices();
    _notifyListeners();
  }
  
  /// Notify listeners of changes
  void _notifyListeners() {
    _devicesStreamController.add(_cachedDevices);
  }
  
  /// Get all devices
  Future<List<DeviceModel>> getDevices() async {
    // If online, try to sync first
    if (_connectivityService.isConnected) {
      await _syncDevices();
    }
    
    // Return cached devices (local storage)
    return _cachedDevices;
  }
  
  /// Get a device by ID
  Future<DeviceModel?> getDevice(String id) async {
    // Check local cache first
    DeviceModel? device = _hiveService.getDevice(id);
    
    // If online and device not found or synced is false, try to fetch from remote
    if (_connectivityService.isConnected && (device == null || !device.synced)) {
      try {
        final devices = await _firebaseService.fetchDevices(await SharedPrefs.getUserId() ?? '');
        final remoteDevice = devices.firstWhere((d) => d.id == id, orElse: () => device!);
        
        // Update local cache
        await _hiveService.saveDevice(remoteDevice);
        
        // Update cached devices
        int index = _cachedDevices.indexWhere((d) => d.id == id);
        if (index != -1) {
          _cachedDevices[index] = remoteDevice;
        } else {
          _cachedDevices.add(remoteDevice);
        }
        
        _notifyListeners();
        
        return remoteDevice;
      } catch (e) {
        // If remote fetch fails, return local device
        return device;
      }
    }
    
    return device;
  }
  
  /// Process device data from JSON to ensure proper structure
  Map<String, dynamic> _processDeviceData(Map<String, dynamic> data) {
    // Process sensors data to ensure proper structure
    if (data.containsKey('sensors')) {
      final sensorsData = data['sensors'] as Map<String, dynamic>;
      Map<String, Map<String, dynamic>> processedSensors = {};
      
      sensorsData.forEach((key, value) {
        if (value is Map) {
          processedSensors[key] = Map<String, dynamic>.from(value);
        }
      });
      
      // Replace the sensors data with the processed version
      data['sensors'] = processedSensors;
    }
    
    return data;
  }
  
  /// Create a new device
  Future<DeviceModel> createDevice(DeviceModel device) async {
    // If online, create on remote and update local
    if (_connectivityService.isConnected) {
      try {
        final createdDevice = await _firebaseService.createDevice(device);
        
        // Update local cache
        await _hiveService.saveDevice(createdDevice);
        
        // Update cached devices
        _cachedDevices.add(createdDevice);
        _notifyListeners();
        
        return createdDevice;
      } catch (e) {
        // If remote creation fails, save locally with synced = false
        return _saveDeviceOffline(device);
      }
    } else {
      // If offline, save locally with synced = false
      return _saveDeviceOffline(device);
    }
  }
  
  /// Save a device offline with pending sync
  Future<DeviceModel> _saveDeviceOffline(DeviceModel device) async {
    // Set synced to false
    final offlineDevice = device.copyWith(synced: false);
    
    // Save to local storage
    await _hiveService.saveDevice(offlineDevice);
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: device.id,
      itemType: 'device',
      operation: 'create',
      data: offlineDevice.toJson(),
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached devices
    _cachedDevices.add(offlineDevice);
    _notifyListeners();
    
    return offlineDevice;
  }
  
  /// Update an existing device
  Future<void> updateDevice(DeviceModel device) async {
    // If online, update on remote and local
    if (_connectivityService.isConnected) {
      try {
        await _firebaseService.updateDevice(device);
        
        // Update local cache with synced = true
        final updatedDevice = device.copyWith(synced: true);
        await _hiveService.saveDevice(updatedDevice);
        
        // Update cached devices
        int index = _cachedDevices.indexWhere((d) => d.id == device.id);
        if (index != -1) {
          _cachedDevices[index] = updatedDevice;
        }
        
        _notifyListeners();
      } catch (e) {
        // If remote update fails, update locally with synced = false
        await _updateDeviceOffline(device);
      }
    } else {
      // If offline, update locally with synced = false
      await _updateDeviceOffline(device);
    }
  }
  
  /// Update a device offline with pending sync
  Future<void> _updateDeviceOffline(DeviceModel device) async {
    // Set synced to false
    final offlineDevice = device.copyWith(synced: false);
    
    // Save to local storage
    await _hiveService.saveDevice(offlineDevice);
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: device.id,
      itemType: 'device',
      operation: 'update',
      data: offlineDevice.toJson(),
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached devices
    int index = _cachedDevices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _cachedDevices[index] = offlineDevice;
    }
    
    _notifyListeners();
  }
  
  /// Delete a device
  Future<void> deleteDevice(String id) async {
    // If online, delete from remote and local
    if (_connectivityService.isConnected) {
      try {
        await _firebaseService.deleteDevice(id);
        
        // Delete from local storage
        await _hiveService.deleteDevice(id);
        
        // Update cached devices
        _cachedDevices.removeWhere((d) => d.id == id);
        _notifyListeners();
      } catch (e) {
        // If remote deletion fails, mark for deletion locally
        await _deleteDeviceOffline(id);
      }
    } else {
      // If offline, mark for deletion locally
      await _deleteDeviceOffline(id);
    }
  }
  
  /// Mark a device for deletion offline with pending sync
  Future<void> _deleteDeviceOffline(String id) async {
    // Get the device
    final device = _hiveService.getDevice(id);
    if (device == null) return;
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: id,
      itemType: 'device',
      operation: 'delete',
      data: {'id': id},
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Set synced to false
    final offlineDevice = device.copyWith(synced: false);
    await _hiveService.saveDevice(offlineDevice);
    
    // Update cached devices
    int index = _cachedDevices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _cachedDevices[index] = offlineDevice;
    }
    
    _notifyListeners();
  }
  
  /// Sync devices with remote
  Future<void> _syncDevices() async {
    try {
      // Get user ID
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;
      
      // Fetch devices from remote
      final remoteDevices = await _firebaseService.fetchDevices(userId);
      
      // Process pending sync items
      await _processPendingSyncItems();
      
      // Update local storage with remote devices
      for (var device in remoteDevices) {
        await _hiveService.saveDevice(device);
      }
      
      // Update cached devices
      _cachedDevices = remoteDevices;
      _notifyListeners();
    } catch (e) {
      // If sync fails, use local devices
      _loadCachedDevices();
    }
  }
  
  /// Process pending sync items
  Future<void> _processPendingSyncItems() async {
    try {
      // Get all pending sync items for devices
      final pendingItems = _hiveService.getPendingSyncItemsByType('device');
      
      for (var item in pendingItems) {
        try {
          // Process the data to ensure proper structure
          final processedData = _processDeviceData(item.data);
          
          switch (item.operation) {
            case 'create':
              // Create device on remote
              final device = DeviceModel.fromJson(
                processedData['device_id'] ?? item.id,
                processedData,
              );
              await _firebaseService.createDevice(device);
              break;
            case 'update':
              // Update device on remote
              final device = DeviceModel.fromJson(
                processedData['device_id'] ?? item.id,
                processedData,
              );
              await _firebaseService.updateDevice(device);
              break;
            case 'delete':
              // Delete device on remote
              await _firebaseService.deleteDevice(item.id);
              // Remove from local storage
              await _hiveService.deleteDevice(item.id);
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
      await _syncDevices();
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _devicesStreamController.close();
  }
}
