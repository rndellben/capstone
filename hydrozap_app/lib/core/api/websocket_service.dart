import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/device_model.dart';
import 'api_config.dart';

class DashboardCounts {
  final int deviceCount;
  final int growCount;
  final int alertCount;
  final DateTime timestamp;

  DashboardCounts({
    required this.deviceCount,
    required this.growCount,
    required this.alertCount,
    required this.timestamp,
  });

  factory DashboardCounts.fromJson(Map<String, dynamic> json) {
    return DashboardCounts(
      deviceCount: json['device_count'] ?? 0,
      growCount: json['grow_count'] ?? 0,
      alertCount: json['alert_count'] ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<List<DeviceModel>> _devicesController = StreamController<List<DeviceModel>>.broadcast();
  bool _isConnected = false;
  String? _userId;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _initialBackoffSeconds = 2;
  WebSocketChannel? _dashboardChannel;
  final StreamController<DashboardCounts> _dashboardController = StreamController<DashboardCounts>.broadcast();
  bool _isDashboardConnected = false;
  String? _dashboardUserId;
  Timer? _dashboardReconnectTimer;
  int _dashboardReconnectAttempts = 0;
  static const int _dashboardMaxReconnectAttempts = 5;
  static const int _dashboardInitialBackoffSeconds = 2;

  // Getter for the stream of device updates
  Stream<List<DeviceModel>> get devicesStream => _devicesController.stream;
  
  // Getter for connection status
  bool get isConnected => _isConnected;

  // Getter for the stream of dashboard updates
  Stream<DashboardCounts> get dashboardStream => _dashboardController.stream;
  bool get isDashboardConnected => _isDashboardConnected;

  // Connect to WebSocket for a specific user
  void connect(String userId) {
    if (_isConnected) {
      disconnect(); // Disconnect existing connection first
    }
    
    _userId = userId;
    final wsUrl = Uri.parse('${ApiConfig.wsBaseUrl}/ws/devices/$userId/');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      
      // Listen for messages from the WebSocket
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
          // Reset reconnect attempts on successful message
          _reconnectAttempts = 0;
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
      
      // Set up a ping timer to keep the connection alive
      _setupPingTimer();
      
      // Mark as connected
      _isConnected = true;
      
      // Immediately request device data
      requestDevicesRefresh();
      
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }
  
  // Set up ping timer to keep connection alive
  void _setupPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendPing();
    });
  }
  
  // Send a ping message to keep the connection alive
  void _sendPing() {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String()
        }));
      } catch (e) {
        _isConnected = false;
        _scheduleReconnect();
      }
    }
  }
  
  // Handle messages received from the WebSocket
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final messageType = data['type'];
      
      switch (messageType) {
        case 'devices_update':
          _handleDevicesUpdate(data);
          break;
        case 'pong':
          // Handle pong response
          break;
        case 'error':
          // Handle error message
          break;
        default:
          // Handle unknown message type
          break;
      }
    } catch (e) {
      // Handle message parsing error
    }
  }
  
  // Handle device update messages
  void _handleDevicesUpdate(Map<String, dynamic> data) {
    if (data.containsKey('devices')) {
      final devicesData = data['devices'] as Map<String, dynamic>;
      final List<DeviceModel> devices = [];
      
      devicesData.forEach((deviceId, deviceData) {
        if (deviceData is Map<String, dynamic>) {
          try {
            final device = DeviceModel.fromJson(deviceId, deviceData);
            devices.add(device);
          } catch (e) {
            // Handle device parsing error
          }
        }
      });
      
      // Add devices to the stream
      _devicesController.add(devices);
    }
  }
  
  // Manually request device data refresh
  void requestDevicesRefresh() {
    if (_isConnected && _channel != null && _userId != null) {
      try {
        _channel!.sink.add(jsonEncode({
          'type': 'fetch_devices',
          'user_id': _userId
        }));
      } catch (e) {
        _isConnected = false;
        _scheduleReconnect();
      }
    }
  }
  
  // Send actuator command through WebSocket
  Future<bool> sendActuatorCommand(String deviceId, String actuatorId, String command, {int duration = 5}) async {
    if (!_isConnected || _channel == null) {
      return false;
    }

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'actuator_command',
        'device_id': deviceId,
        'actuator_id': actuatorId,
        'command': command,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String()
      }));
      return true;
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
      return false;
    }
  }
  
  // Schedule reconnection attempts with exponential backoff
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }
    
    _reconnectAttempts++;
    
    // Calculate backoff time with exponential increase (2s, 4s, 8s, 16s, 32s)
    final backoffSeconds = _initialBackoffSeconds * (1 << (_reconnectAttempts - 1));
    
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (!_isConnected && _userId != null) {
        connect(_userId!);
      }
    });
  }
  
  // Disconnect from the WebSocket
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (e) {
        // Handle error silently
      }
      _channel = null;
    }
    
    _isConnected = false;
  }
  
  // Connect to dashboard WebSocket for a specific user
  void connectDashboard(String userId) {
    if (_isDashboardConnected) {
      disconnectDashboard();
    }
    _dashboardUserId = userId;
    final wsUrl = Uri.parse('${ApiConfig.wsBaseUrl}/ws/dashboard/$userId/');
    try {
      _dashboardChannel = WebSocketChannel.connect(wsUrl);
      _dashboardChannel!.stream.listen(
        (message) {
          _handleDashboardMessage(message);
          _dashboardReconnectAttempts = 0;
        },
        onError: (error) {
          _isDashboardConnected = false;
          _scheduleDashboardReconnect();
        },
        onDone: () {
          _isDashboardConnected = false;
          _scheduleDashboardReconnect();
        },
      );
      _isDashboardConnected = true;
      requestDashboardRefresh();
    } catch (e) {
      _isDashboardConnected = false;
      _scheduleDashboardReconnect();
    }
  }

  void _handleDashboardMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final messageType = data['type'];
      switch (messageType) {
        case 'dashboard_update':
          _handleDashboardUpdate(data);
          break;
        case 'error':
          // Handle error message
          break;
        default:
          // Handle unknown message type
          break;
      }
    } catch (e) {
      // Handle message parsing error
    }
  }

  void _handleDashboardUpdate(Map<String, dynamic> data) {
    final counts = DashboardCounts.fromJson(data);
    _dashboardController.add(counts);
  }

  // Manually request dashboard data refresh
  void requestDashboardRefresh() {
    if (_isDashboardConnected && _dashboardChannel != null && _dashboardUserId != null) {
      try {
        _dashboardChannel!.sink.add(jsonEncode({
          'type': 'fetch_dashboard',
          'user_id': _dashboardUserId
        }));
      } catch (e) {
        _isDashboardConnected = false;
        _scheduleDashboardReconnect();
      }
    }
  }

  void _scheduleDashboardReconnect() {
    _dashboardReconnectTimer?.cancel();
    if (_dashboardReconnectAttempts >= _dashboardMaxReconnectAttempts) {
      return;
    }
    _dashboardReconnectAttempts++;
    final backoffSeconds = _dashboardInitialBackoffSeconds * (1 << (_dashboardReconnectAttempts - 1));
    _dashboardReconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (!_isDashboardConnected && _dashboardUserId != null) {
        connectDashboard(_dashboardUserId!);
      }
    });
  }

  void disconnectDashboard() {
    _dashboardReconnectTimer?.cancel();
    if (_dashboardChannel != null) {
      try {
        _dashboardChannel!.sink.close();
      } catch (e) {
        // Handle error silently
      }
      _dashboardChannel = null;
    }
    _isDashboardConnected = false;
  }
  
  // Dispose the service
  void dispose() {
    disconnect();
    disconnectDashboard();
    _devicesController.close();
    _dashboardController.close();
  }
} 