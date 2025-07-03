import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller for connectivity status
  final _connectivityController = StreamController<bool>.broadcast();
  
  // Current connectivity status
  bool _isConnected = false;
  
  // Subscribe to connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  // Current connectivity status
  bool get isConnected => _isConnected;
  
  // Initialize connectivity monitoring
  void initialize() async {
    // Check initial connectivity status
    final connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);
    
    // Subscribe to connectivity changes
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    bool wasConnected = _isConnected;
    
    // Determine if connected based on connectivity result
    switch (result) {
      case ConnectivityResult.none:
        _isConnected = false;
        break;
      default:
        _isConnected = true;
        break;
    }
    
    // Only notify if the status has changed
    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
    }
  }
  
  // Dispose of resources
  void dispose() {
    _connectivityController.close();
  }
} 