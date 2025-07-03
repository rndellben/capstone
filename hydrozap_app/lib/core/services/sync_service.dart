import 'dart:async';
import 'package:hydrozap_app/core/services/connectivity_service.dart';
import 'package:hydrozap_app/data/repositories/device_repository.dart';
import 'package:hydrozap_app/data/repositories/grow_profile_repository.dart';
import 'package:hydrozap_app/data/repositories/alert_repository.dart';
import 'package:hydrozap_app/data/local/hive_service.dart';
import 'package:hydrozap_app/core/api/api_service.dart';
import 'package:hydrozap_app/core/models/grow_model.dart';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/core/utils/logger.dart';

/// SyncService manages all synchronization for the app
class SyncService {
  final DeviceRepository _deviceRepository;
  final GrowProfileRepository _growProfileRepository;
  final AlertRepository _alertRepository;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService;
  final ApiService _apiService = ApiService();
  
  // Stream controller for sync status
  final _syncStatusController = StreamController<bool>.broadcast();
  
  // Current sync status
  bool _isSyncing = false;
  
  // Timer for periodic sync
  Timer? _syncTimer;
  
  // Sync interval in minutes
  static const int _syncIntervalMinutes = 15;
  
  // Stream of sync status
  Stream<bool> get syncStatusStream => _syncStatusController.stream;
  
  // Current sync status
  bool get isSyncing => _isSyncing;
  
  SyncService({
    required DeviceRepository deviceRepository,
    required GrowProfileRepository growProfileRepository,
    required AlertRepository alertRepository,
    required ConnectivityService connectivityService,
    required HiveService hiveService,
  }) : _deviceRepository = deviceRepository,
       _growProfileRepository = growProfileRepository,
       _alertRepository = alertRepository,
       _connectivityService = connectivityService,
       _hiveService = hiveService {
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        // Sync when back online
        syncAll();
      }
    });
    
    // Start periodic sync
    _startPeriodicSync();
  }
  
  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: _syncIntervalMinutes),
      (_) {
        if (_connectivityService.isConnected) {
          syncAll();
        }
      },
    );
  }
  
  /// Sync all data
  Future<void> syncAll() async {
    if (_isSyncing || !_connectivityService.isConnected) return;
    
    _isSyncing = true;
    _syncStatusController.add(_isSyncing);
    
    try {
      // Sync all repositories
      await Future.wait([
        _deviceRepository.forceSync(),
        _growProfileRepository.forceSync(),
        _alertRepository.forceSync(),
        // Add other repositories as needed
      ]);
      
      // Process pending sync items
      await _processPendingSyncItems();
      
    } catch (e) {
      // Handle sync errors
      logger.e('Sync error: $e');
    } finally {
      _isSyncing = false;
      _syncStatusController.add(_isSyncing);
    }
  }
  
  /// Process all pending sync items
  Future<void> _processPendingSyncItems() async {
    if (!_connectivityService.isConnected) return;
    
    final pendingItems = _hiveService.getAllPendingSyncItems();
    if (pendingItems.isEmpty) return;
    
    for (final item in pendingItems) {
      bool success = false;
      
      try {
        // Process based on item type and operation
        switch (item.itemType) {
          case 'grow':
            if (item.operation == 'create') {
              // Convert data to Grow model first
              final grow = Grow.fromJson(item.data);
              success = await _apiService.addGrow(grow);
            } else if (item.operation == 'delete') {
              // For deleting a grow
              final growId = item.data['grow_id'];
              final result = await _apiService.deleteGrow(growId);
              success = result['success'] ?? false;
            }
            break;
            
          case 'device':
            if (item.operation == 'create') {
              // Create device model from data
              final device = DeviceModel.fromJson(
                item.data['device_id'] ?? '', 
                item.data
              );
              success = await _apiService.addDevice(device);
            }
            break;
            
          case 'grow_profile':
            if (item.operation == 'create') {
              success = await _apiService.addGrowProfile(item.data);
            }
            break;
            
          default:
            logger.w('Unknown item type: ${item.itemType}');
            break;
        }
        
        if (success) {
          // Remove synced item
          await _hiveService.removePendingSyncItem(item.id);
        } else {
          // Mark as failed but keep for retry
          final updatedItem = item.markSyncFailed();
          await _hiveService.savePendingSyncItem(updatedItem);
        }
      } catch (e) {
        logger.e('Error processing sync item ${item.id}: $e');
        // Mark as failed but keep for retry
        final updatedItem = item.markSyncFailed();
        await _hiveService.savePendingSyncItem(updatedItem);
      }
    }
  }
  
  /// Get sync status as a string
  String getSyncStatusText() {
    if (_isSyncing) {
      return 'Syncing...';
    } else if (!_connectivityService.isConnected) {
      return 'Offline';
    } else {
      final pendingCount = _hiveService.getAllPendingSyncItems().length;
      if (pendingCount > 0) {
        return 'Waiting to sync ($pendingCount)';
      } else {
        return 'Synced';
      }
    }
  }
  
  /// Get pending sync count
  int getPendingSyncCount() {
    return _hiveService.getAllPendingSyncItems().length;
  }
  
  /// Force sync all data
  Future<void> forceSyncAll() async {
    await syncAll();
  }
  
  /// Dispose of resources
  void dispose() {
    _syncStatusController.close();
    _syncTimer?.cancel();
  }
} 