import 'package:flutter/foundation.dart';
import '../data/repositories/dashboard_repository.dart';
import '../core/api/websocket_service.dart';
import 'dart:async';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _dashboardRepository;
  final WebSocketService _webSocketService = WebSocketService();
  
  // Dashboard counts
  int _deviceCount = 0;
  int _growCount = 0;
  int _alertCount = 0;
  bool _isLoading = false;

  // WebSocket subscription
  StreamSubscription? _dashboardSub;
  bool _isRealtime = false;
  
  // Getters
  int get deviceCount => _deviceCount;
  int get growCount => _growCount;
  int get alertCount => _alertCount;
  bool get isLoading => _isLoading;
  bool get isRealtime => _isRealtime;
  
  DashboardProvider({
    required DashboardRepository dashboardRepository,
  }) : _dashboardRepository = dashboardRepository {
    // Load cached counts on initialization
    _loadCachedCounts();
  }
  
  // Load cached counts from repository
  void _loadCachedCounts() {
    final cachedCounts = _dashboardRepository.getCachedCounts();
    _deviceCount = cachedCounts['devices'] ?? 0;
    _growCount = cachedCounts['grows'] ?? 0;
    _alertCount = cachedCounts['alerts'] ?? 0;
    notifyListeners();
  }

  // Start real-time dashboard updates
  void startRealtime(String userId) {
    if (_isRealtime) return;
    _isRealtime = true;
    _webSocketService.connectDashboard(userId);
    _dashboardSub = _webSocketService.dashboardStream.listen((counts) {
      _deviceCount = counts.deviceCount;
      _growCount = counts.growCount;
      _alertCount = counts.alertCount;
      notifyListeners();
    });
  }

  // Stop real-time dashboard updates
  void stopRealtime() {
    _dashboardSub?.cancel();
    _webSocketService.disconnectDashboard();
    _isRealtime = false;
  }
  
  // Fetch counts from API with offline support
  Future<void> fetchCounts(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch all counts in one network request
      final counts = await _dashboardRepository.getAllCounts(userId);
      
      // Update counts
      _deviceCount = counts['devices'] ?? 0;
      _growCount = counts['grows'] ?? 0;
      _alertCount = counts['alerts'] ?? 0;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching dashboard counts: $e');
      // In case of error, load cached counts
      _loadCachedCounts();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
} 