import 'dart:async';
import 'package:hydrozap_app/core/models/grow_profile_model.dart';
import 'package:hydrozap_app/core/models/profile_change_log_model.dart';
import 'package:hydrozap_app/core/models/pending_sync_item.dart';
import 'package:hydrozap_app/core/services/connectivity_service.dart';
import 'package:hydrozap_app/data/local/hive_service.dart';
import 'package:hydrozap_app/core/api/api_service.dart';
import 'package:hydrozap_app/data/local/shared_prefs.dart';
import 'package:uuid/uuid.dart';

/// Repository for profile change log operations with offline-first support
class ProfileChangeLogRepository {
  final HiveService _hiveService = HiveService();
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Stream controller for change logs
  final _changeLogsStreamController = StreamController<List<ProfileChangeLog>>.broadcast();
  
  // Stream of change logs
  Stream<List<ProfileChangeLog>> get changeLogsStream => _changeLogsStreamController.stream;
  
  // Current list of change logs
  List<ProfileChangeLog> _cachedChangeLogs = [];
  
  ProfileChangeLogRepository() {
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        // Sync change logs when back online
        _syncChangeLogs();
      }
    });
  }
  
  /// Initialize the repository
  Future<void> initialize() async {
    // Load cached change logs from local storage
    _loadCachedChangeLogs();
    
    // Check if online, then sync with remote
    if (_connectivityService.isConnected) {
      _syncChangeLogs();
    }
  }
  
  /// Load cached change logs from local storage
  void _loadCachedChangeLogs() {
    _cachedChangeLogs = _hiveService.getAllProfileChangeLogs();
    _notifyListeners();
  }
  
  /// Notify listeners of changes
  void _notifyListeners() {
    _changeLogsStreamController.add(_cachedChangeLogs);
  }
  
  /// Get all change logs
  Future<List<ProfileChangeLog>> getChangeLogs({bool syncWithRemote = false}) async {
    // If online and syncWithRemote is true, try to sync first
    if (_connectivityService.isConnected && syncWithRemote) {
      await _syncChangeLogs();
    } else {
      // Just fetch from remote without syncing local changes
      await _fetchRemoteLogs();
    }
    
    // Return cached change logs (local storage)
    return _cachedChangeLogs;
  }
  
  /// Get change logs for a specific profile
  Future<List<ProfileChangeLog>> getChangeLogsForProfile(String profileId, {bool syncWithRemote = false}) async {
    // If online and syncWithRemote is true, try to sync first
    if (_connectivityService.isConnected && syncWithRemote) {
      await _syncChangeLogs();
    } else {
      // Just fetch from remote without syncing local changes
      await _fetchRemoteLogs();
    }
    
    // Filter cached change logs for the specified profile
    return _cachedChangeLogs.where((log) => log.profileId == profileId).toList();
  }
  
  /// Fetch remote logs without syncing local changes
  Future<void> _fetchRemoteLogs() async {
    try {
      // Get user ID
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;
      
      // Get remote change logs
      final remoteLogs = await _apiService.getProfileChangeLogs('', userId);
      
      // Update local storage with remote logs
      for (final log in remoteLogs) {
        await _hiveService.saveProfileChangeLog(log);
      }
      
      // Update cached change logs
      _cachedChangeLogs = _hiveService.getAllProfileChangeLogs();
      cleanupDuplicateLogs();
      _notifyListeners();
    } catch (e) {
      print('Error fetching remote logs: $e');
    }
  }
  
  /// Create a new change log entry
  Future<ProfileChangeLog> createChangeLog({
    required String profileId,
    required String userId,
    required String userName,
    required Map<String, dynamic> changedFields,
    required Map<String, dynamic> previousValues,
    required Map<String, dynamic> newValues,
    required String changeType,
  }) async {
    // Generate a unique ID for the change log
    final String id = const Uuid().v4();
    
    // Create the change log
    final changeLog = ProfileChangeLog(
      id: id,
      profileId: profileId,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
      changedFields: changedFields,
      previousValues: previousValues,
      newValues: newValues,
      changeType: changeType,
    );
    
    // If online, create on remote and update local
    if (_connectivityService.isConnected) {
      try {
        final success = await _apiService.createProfileChangeLog(changeLog.toMap());
        
        if (success) {
          // Update local cache with synced = true
          final syncedChangeLog = changeLog.copyWith(synced: true);
          await _hiveService.saveProfileChangeLog(syncedChangeLog);
          
          // Update cached change logs
          _cachedChangeLogs.add(syncedChangeLog);
          _notifyListeners();
          
          return syncedChangeLog;
        } else {
          // If remote creation fails, save locally with synced = false
          return _saveChangeLogOffline(changeLog);
        }
      } catch (e) {
        // If remote creation fails, save locally with synced = false
        return _saveChangeLogOffline(changeLog);
      }
    } else {
      // If offline, save locally with synced = false
      return _saveChangeLogOffline(changeLog);
    }
  }
  
  /// Save a change log offline with pending sync
  Future<ProfileChangeLog> _saveChangeLogOffline(ProfileChangeLog changeLog) async {
    // Set synced to false
    final offlineChangeLog = changeLog.copyWith(synced: false);
    
    // Save to local storage
    await _hiveService.saveProfileChangeLog(offlineChangeLog);
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: changeLog.id,
      itemType: 'profile_change_log',
      operation: 'create',
      data: offlineChangeLog.toMap(),
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached change logs
    _cachedChangeLogs.add(offlineChangeLog);
    _notifyListeners();
    
    return offlineChangeLog;
  }
  
  /// Sync change logs with remote
  Future<void> _syncChangeLogs() async {
    try {
      // Get user ID
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;
      
      // Get remote change logs
      final remoteLogs = await _apiService.getProfileChangeLogs('', userId);
      
      // Get local change logs that need to be synced
      final localLogs = _hiveService.getAllProfileChangeLogs()
          .where((log) => !log.synced)
          .toList();
      
      // Sync local logs to remote
      for (final log in localLogs) {
        try {
          final success = await _apiService.createProfileChangeLog(log.toMap());
          
          if (success) {
            // Update local storage with synced = true
            final syncedLog = log.copyWith(synced: true);
            await _hiveService.saveProfileChangeLog(syncedLog);
            
            // Remove from pending sync items
            await _hiveService.deletePendingSyncItem(log.id);
          }
        } catch (e) {
          // Log error but continue with next item
          print('Error syncing change log: $e');
        }
      }
      
      // Update local storage with remote logs
      for (final log in remoteLogs) {
        await _hiveService.saveProfileChangeLog(log);
      }
      
      // Update cached change logs
      _cachedChangeLogs = _hiveService.getAllProfileChangeLogs();
      cleanupDuplicateLogs();
      _notifyListeners();
    } catch (e) {
      print('Error syncing change logs: $e');
    }
  }

  /// Remove duplicate logs based on timestamp, profileId, and changeType
  void cleanupDuplicateLogs() {
    final Map<String, ProfileChangeLog> uniqueLogs = {};
    for (final log in _cachedChangeLogs) {
      final key = '${log.profileId}_${log.timestamp.toIso8601String()}_${log.changeType}';
      // Prefer the synced version if duplicate exists
      if (!uniqueLogs.containsKey(key) || (log.synced && !uniqueLogs[key]!.synced)) {
        uniqueLogs[key] = log;
      }
    }
    _cachedChangeLogs = uniqueLogs.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Track changes to a grow profile
  Future<void> trackProfileChanges({
    required GrowProfile oldProfile,
    required GrowProfile newProfile,
    required String userId,
    required String userName,
    required String changeType,
  }) async {
    // Compare profiles and identify changes
    final changedFields = <String, dynamic>{};
    final previousValues = <String, dynamic>{};
    final newValues = <String, dynamic>{};
    
    // Check basic fields
    if (oldProfile.name != newProfile.name) {
      changedFields['name'] = true;
      previousValues['name'] = oldProfile.name;
      newValues['name'] = newProfile.name;
    }
    
    if (oldProfile.growDurationDays != newProfile.growDurationDays) {
      changedFields['grow_duration_days'] = true;
      previousValues['grow_duration_days'] = oldProfile.growDurationDays;
      newValues['grow_duration_days'] = newProfile.growDurationDays;
    }
    
    if (oldProfile.isActive != newProfile.isActive) {
      changedFields['is_active'] = true;
      previousValues['is_active'] = oldProfile.isActive;
      newValues['is_active'] = newProfile.isActive;
    }
    
    if (oldProfile.plantProfileId != newProfile.plantProfileId) {
      changedFields['plant_profile_id'] = true;
      previousValues['plant_profile_id'] = oldProfile.plantProfileId;
      newValues['plant_profile_id'] = newProfile.plantProfileId;
    }
    
    if (oldProfile.mode != newProfile.mode) {
      changedFields['mode'] = true;
      previousValues['mode'] = oldProfile.mode;
      newValues['mode'] = newProfile.mode;
    }
    
    // Check optimal conditions
    _compareOptimalConditions(
      oldProfile.optimalConditions, 
      newProfile.optimalConditions,
      changedFields,
      previousValues,
      newValues,
    );
    
    // Only create a change log if there are changes
    if (changedFields.isNotEmpty) {
      await createChangeLog(
        profileId: newProfile.id,
        userId: userId,
        userName: userName,
        changedFields: changedFields,
        previousValues: previousValues,
        newValues: newValues,
        changeType: changeType,
      );
    }
  }
  
  /// Compare optimal conditions and identify changes
  void _compareOptimalConditions(
    StageConditions oldConditions,
    StageConditions newConditions,
    Map<String, dynamic> changedFields,
    Map<String, dynamic> previousValues,
    Map<String, dynamic> newValues,
  ) {
    // Compare transplanting conditions
    _compareStageCondition(
      'transplanting',
      oldConditions.transplanting,
      newConditions.transplanting,
      changedFields,
      previousValues,
      newValues,
    );
    
    // Compare vegetative conditions
    _compareStageCondition(
      'vegetative',
      oldConditions.vegetative,
      newConditions.vegetative,
      changedFields,
      previousValues,
      newValues,
    );
    
    // Compare maturation conditions
    _compareStageCondition(
      'maturation',
      oldConditions.maturation,
      newConditions.maturation,
      changedFields,
      previousValues,
      newValues,
    );
  }
  
  /// Compare conditions for a specific growth stage
  void _compareStageCondition(
    String stageName,
    OptimalConditions oldConditions,
    OptimalConditions newConditions,
    Map<String, dynamic> changedFields,
    Map<String, dynamic> previousValues,
    Map<String, dynamic> newValues,
  ) {
    // Compare temperature range
    if (oldConditions.temperature.min != newConditions.temperature.min ||
        oldConditions.temperature.max != newConditions.temperature.max) {
      final fieldName = 'optimal_conditions_${stageName}_temperature_range';
      changedFields[fieldName] = true;
      previousValues[fieldName] = {
        'min': oldConditions.temperature.min,
        'max': oldConditions.temperature.max,
      };
      newValues[fieldName] = {
        'min': newConditions.temperature.min,
        'max': newConditions.temperature.max,
      };
    }
    
    // Compare humidity range
    if (oldConditions.humidity.min != newConditions.humidity.min ||
        oldConditions.humidity.max != newConditions.humidity.max) {
      final fieldName = 'optimal_conditions_${stageName}_humidity_range';
      changedFields[fieldName] = true;
      previousValues[fieldName] = {
        'min': oldConditions.humidity.min,
        'max': oldConditions.humidity.max,
      };
      newValues[fieldName] = {
        'min': newConditions.humidity.min,
        'max': newConditions.humidity.max,
      };
    }
    
    // Compare pH range
    if (oldConditions.phRange.min != newConditions.phRange.min ||
        oldConditions.phRange.max != newConditions.phRange.max) {
      final fieldName = 'optimal_conditions_${stageName}_ph_range';
      changedFields[fieldName] = true;
      previousValues[fieldName] = {
        'min': oldConditions.phRange.min,
        'max': oldConditions.phRange.max,
      };
      newValues[fieldName] = {
        'min': newConditions.phRange.min,
        'max': newConditions.phRange.max,
      };
    }
    
    // Compare EC range
    if (oldConditions.ecRange.min != newConditions.ecRange.min ||
        oldConditions.ecRange.max != newConditions.ecRange.max) {
      final fieldName = 'optimal_conditions_${stageName}_ec_range';
      changedFields[fieldName] = true;
      previousValues[fieldName] = {
        'min': oldConditions.ecRange.min,
        'max': oldConditions.ecRange.max,
      };
      newValues[fieldName] = {
        'min': newConditions.ecRange.min,
        'max': newConditions.ecRange.max,
      };
    }
    
    // Compare TDS range
    if (oldConditions.tdsRange.min != newConditions.tdsRange.min ||
        oldConditions.tdsRange.max != newConditions.tdsRange.max) {
      final fieldName = 'optimal_conditions_${stageName}_tds_range';
      changedFields[fieldName] = true;
      previousValues[fieldName] = {
        'min': oldConditions.tdsRange.min,
        'max': oldConditions.tdsRange.max,
      };
      newValues[fieldName] = {
        'min': newConditions.tdsRange.min,
        'max': newConditions.tdsRange.max,
      };
    }
  }

  /// Fetch logs directly from the API (remote only, no local cache)
  Future<List<ProfileChangeLog>> fetchRemoteOnlyLogs() async {
    try {
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return [];
      return await _apiService.getProfileChangeLogs('', userId);
    } catch (e) {
      print('Error fetching remote-only logs: $e');
      return [];
    }
  }
} 