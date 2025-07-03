// providers/device_provider.dart
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/api/websocket_service.dart';
import '../core/models/device_model.dart';
import '../core/models/pending_sync_item.dart';
import '../core/services/connectivity_service.dart';
import '../data/local/hive_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../core/services/push_notification_service.dart';
import '../data/local/shared_prefs.dart';
import '../core/utils/logger.dart';

class DeviceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();
  final HiveService _hiveService = HiveService();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<DeviceModel> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;
  DeviceModel? selectedDevice;
  StreamSubscription? _deviceSubscription;
  StreamSubscription? _connectivitySubscription;
  Timer? _reconnectTimer;
  bool _isReconnecting = false;
  PushNotificationService? _pushNotificationService;

  List<DeviceModel> get devices => _devices;
  bool get isLoading => _isLoading;
  bool get isWebSocketConnected => _webSocketService.isConnected;
  String? get errorMessage => _errorMessage;
  Stream<List<DeviceModel>> get devicesStream => _webSocketService.devicesStream;

  DeviceProvider() {
    _initConnectivityListener();
    _initWebSocketListener();
  }

  void _initConnectivityListener() {
    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        logger.d("DeviceProvider: Network connected, attempting to reconnect WebSocket");
        // Try to reconnect WebSocket when connectivity is restored
        _reconnectWebSocketIfNeeded();
      } else {
        logger.d("DeviceProvider: Network disconnected");
      }
      notifyListeners();
    });
  }

  void _initWebSocketListener() {
    // Initialize WebSocket stream listener
    _deviceSubscription = _webSocketService.devicesStream.listen((updatedDevices) {
      _devices = updatedDevices;
      
      // Update the selected device if it exists in the updated devices
      if (selectedDevice != null) {
        int index = _devices.indexWhere((d) => d.id == selectedDevice!.id);
        if (index != -1) {
          selectedDevice = _devices[index];
        }
      }
      
      // Cache devices for offline use
      _cacheDevices();
      
      notifyListeners();
    }, onError: (error) {
      logger.e("DeviceProvider: WebSocket error: $error");
      _errorMessage = "WebSocket error: $error";
      _reconnectWebSocketIfNeeded();
      notifyListeners();
    });
  }

  Future<void> _cacheDevices() async {
    // Cache devices for offline use
    for (final device in _devices) {
      await _hiveService.saveDevice(device);
    }
  }

  void _reconnectWebSocketIfNeeded() {
    if (_isReconnecting) return;
    
    _isReconnecting = true;
    
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();
    
    // Set up a reconnection timer with exponential backoff
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_webSocketService.isConnected && _connectivityService.isConnected) {
        final currentUserId = _getUserIdFromDevices();
        if (currentUserId != null) {
          connectWebSocket(currentUserId);
        }
      }
      _isReconnecting = false;
    });
  }

  String? _getUserIdFromDevices() {
    // Try to get user ID from devices
    if (_devices.isNotEmpty) {
      return _devices.first.userId;
    }
    return null;
  }

  void selectDevice(DeviceModel device) {
    selectedDevice = device;
    notifyListeners();
  }

  // Connect to WebSocket for a specific user
  void connectWebSocket(String userId) {
    _webSocketService.connect(userId);
    notifyListeners();
  }

  // Disconnect from WebSocket
  void disconnectWebSocket() {
    _webSocketService.disconnect();
    notifyListeners();
  }

  // Manually request a refresh
  void refreshDevices() {
    if (_webSocketService.isConnected) {
      _webSocketService.requestDevicesRefresh();
    } else {
      final userId = _getUserIdFromDevices();
      if (userId != null) {
        fetchDevices(userId);
      }
    }
  }

  // Fetch devices for a user
  Future<void> fetchDevices(String userId) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Fetch devices from the API
      final deviceData = await _apiService.getDevices(userId);
      
      if (deviceData.isNotEmpty) {
        // Clear current list and add new devices
        _devices.clear();
        
        // Convert response to DeviceModel objects and add to list
        _devices = deviceData;
          
        // Subscribe to device topics for push notifications
        if (_pushNotificationService != null) {
          for (final device in _devices) {
            await _pushNotificationService!.subscribeToDevice(device.id);
          }
        }
        
        // Save to Hive for offline access
        for (final device in _devices) {
          await _hiveService.saveDevice(device);
        }
        
        // Connect to WebSocket
        connectWebSocket(userId);
      }
    } catch (e) {
      logger.e('Error fetching devices: $e');
      // Load devices from local storage if API fails
      try {
        final userId = await SharedPrefs.getUserId();
        if (userId != null) {
          // Get devices from local Hive storage
          _devices = _hiveService.getLocalDevices(userId) ?? [];
        }
      } catch (localError) {
        logger.e('Error loading from local storage: $localError');
        _devices = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a device by ID
  Future<DeviceModel?> getDeviceById(String deviceId) async {

    // Check if device is in the current list
    DeviceModel? device = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => null as DeviceModel,
    );

    // If found in the current list, return it
    if (device != null) {
      return device;
    }
  
    // If not found and we're connected, try to fetch from API
    if (_connectivityService.isConnected) {
      // First check local Hive storage
      device = _hiveService.getDevice(deviceId);
      
      if (device != null) {
       
        return device;
      }
      
      // If not in local storage, query the API directly
      try {
      
        final devices = await _apiService.getDevices('');
        device = devices.firstWhere(
          (d) => d.id == deviceId,
          orElse: () => null as DeviceModel,
        );
        
        if (device != null) {
        
          // Cache the device for future use
          await _hiveService.saveDevice(device);
          return device;
        }
      } catch (e) {
        logger.e("DeviceProvider: Error fetching device by ID: $e");
      }
    }
    
    // Try from local storage as a last resort
    device = _hiveService.getDevice(deviceId);
    if (device != null) {
      logger.d("DeviceProvider: Device found in local storage (last resort)");
    } else {
      logger.d("DeviceProvider: Device not found");
    }
    return device;
  }

  // Add a new device
  Future<bool> addDevice(Map<String, dynamic> deviceData) async {
    try {
      if (_connectivityService.isConnected) {
        // Online - send directly to API
        // Create a DeviceModel from the Map data
        final device = DeviceModel.fromJson(
          deviceData['device_id'] ?? '', 
          deviceData
        );
        final success = await _apiService.addDevice(device);
        if (success) {
          fetchDevices(deviceData['user_id']);
        }
        return success;
      } else {
        // Offline - store locally and mark for sync
        final newDevice = DeviceModel.fromJson(
          deviceData['device_id'], 
          deviceData
        );
        
        // Create pending sync item
        final pendingItem = PendingSyncItem(
          id: deviceData['device_id'],
          itemType: 'device',
          operation: 'create',
          data: deviceData,
        );
        
        // Save the device locally
        await _hiveService.addLocalDevice(newDevice);
        
        // Add to pending sync items
        await _hiveService.addPendingSyncItem(pendingItem);
        
        // Update the local list
        _devices.add(newDevice);
        notifyListeners();
        
        return true;
      }
    } catch (e) {
      logger.e("Error adding device: $e");
      return false;
    }
  }

  Future<bool> updateDevice(String deviceId, Map<String, dynamic> updateData) async {
    try {
      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index == -1) return false;

      final oldDevice = _devices[index];
      
      // Handle conversion of sensors data if it exists in the update
      Map<String, Map<String, dynamic>>? updatedSensors;
      if (updateData.containsKey('sensors')) {
        updatedSensors = {};
        final sensorsData = updateData['sensors'] as Map<String, dynamic>;

        // Convert to List, reverse order, then map back to the Map
        final sortedKeys = sensorsData.keys.toList()..sort(); // Sort keys if needed
        for (final key in sortedKeys.reversed) {
          final value = sensorsData[key];
          if (value is Map) {
            updatedSensors[key] = Map<String, dynamic>.from(value);
          }
        }
      }
      
      // Always use PATCH for device updates
      final success = await _apiService.updateDevice(deviceId, updateData);
      if (success) {
        // Update the local device model with new values
        _devices[index] = oldDevice.copyWith(
          deviceName: updateData['device_name'] ?? oldDevice.deviceName,
          emergencyStop: updateData['emergency_stop'] ?? oldDevice.emergencyStop,
          waterVolumeInLiters: updateData['water_volume_liters'] ?? oldDevice.waterVolumeInLiters,
          sensors: updatedSensors ?? oldDevice.sensors,
          autoDoseEnabled: updateData['auto_dose_enabled'] ?? oldDevice.autoDoseEnabled,
        );
        if (selectedDevice?.id == deviceId) {
          selectedDevice = _devices[index];
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      logger.e('Error updating device: $e');
      return false;
    }
  }

  Future<bool> deleteDevice(String deviceId, String userId) async {
    try {
      final result = await _apiService.deleteDevice(deviceId);
      
      if (result['success']) {
        // WebSocket will automatically update the devices list
        return true;
      } else {
        // Handle error based on status code
        if (result['statusCode'] == 409) {
          // Device is assigned to an active grow
          _errorMessage = "Cannot delete a device that is assigned to an active grow. Please harvest or deactivate the grow first.";
          notifyListeners();
        } else {
          _errorMessage = result['message'] ?? "Failed to delete device";
          notifyListeners();
        }
        return false;
      }
    } catch (e) {
      logger.e('Error deleting device: $e');
      _errorMessage = "Failed to delete device: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  // Flush an actuator for a specific device
  Future<bool> flushActuator(String deviceId, String actuatorId, {int duration = 5}) async {
    try {
      if (!_connectivityService.isConnected) {
        _errorMessage = "Cannot flush actuator while offline";
        notifyListeners();
        return false;
      }

      // Send flush command through WebSocket
      final success = await _webSocketService.sendActuatorCommand(
        deviceId,
        actuatorId,
        'flush',
        duration: duration,
      );

      if (!success) {
        _errorMessage = "Failed to send flush command";
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      logger.e('Error flushing actuator: $e');
      _errorMessage = "Failed to flush actuator: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _reconnectTimer?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }

  // Initialize push notification service
  void initializePushNotifications(BuildContext context) {
    if (_pushNotificationService == null) {
      _pushNotificationService = Provider.of<PushNotificationService>(context, listen: false);
      
      // Subscribe to existing device topics
      _subscribeToExistingDevices();
    }
  }
  
  // Subscribe to existing device topics
  Future<void> _subscribeToExistingDevices() async {
    if (_pushNotificationService == null) return;
    
    for (final device in _devices) {
      await _pushNotificationService!.subscribeToDevice(device.id);
    }
  }

  // Get current thresholds for a device
  Future<Map<String, dynamic>?> getCurrentThresholds(String deviceId) async {
    try {
      if (!_connectivityService.isConnected) {
        logger.d("DeviceProvider: Cannot get current thresholds while offline");
        return null;
      }

      final response = await _apiService.getCurrentThresholds(deviceId);
      
      if (response != null) {
        // Update the device with the new thresholds
        await updateDeviceThresholds(deviceId, response);
      }
      
      return response;
    } catch (e) {
      logger.e("DeviceProvider: Error getting current thresholds: $e");
      return null;
    }
  }

  // Update device thresholds
  Future<void> updateDeviceThresholds(String deviceId, Map<String, dynamic> thresholds) async {
    try {
      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index == -1) return;

      // Update the device with new thresholds
      _devices[index] = _devices[index].copyWith(
        thresholds: thresholds,
      );

      // If this is the selected device, update it too
      if (selectedDevice?.id == deviceId) {
        selectedDevice = _devices[index];
      }

      // Save to local storage
      await _hiveService.saveDevice(_devices[index]);
      
      notifyListeners();
    } catch (e) {
      logger.e("DeviceProvider: Error updating device thresholds: $e");
    }
  }
}
