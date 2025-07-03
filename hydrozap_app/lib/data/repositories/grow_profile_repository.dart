import 'dart:async';
import 'package:hydrozap_app/core/models/grow_profile_model.dart';
import 'package:hydrozap_app/core/models/pending_sync_item.dart';
import 'package:hydrozap_app/core/services/connectivity_service.dart';
import 'package:hydrozap_app/data/local/hive_service.dart';
import 'package:hydrozap_app/data/remote/firebase_service.dart';
import 'package:hydrozap_app/data/local/shared_prefs.dart';

/// Repository for grow profile-related operations with offline-first support
class GrowProfileRepository {
  final HiveService _hiveService = HiveService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Stream controller for grow profiles
  final _profilesStreamController = StreamController<List<GrowProfile>>.broadcast();
  
  // Stream of grow profiles
  Stream<List<GrowProfile>> get profilesStream => _profilesStreamController.stream;
  
  // Current list of grow profiles
  List<GrowProfile> _cachedProfiles = [];
  
  GrowProfileRepository() {
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        // Sync profiles when back online
        _syncProfiles();
      }
    });
  }
  
  /// Initialize the repository
  Future<void> initialize() async {
    // Load cached profiles from local storage
    _loadCachedProfiles();
    
    // Check if online, then sync with remote
    if (_connectivityService.isConnected) {
      _syncProfiles();
    }
  }
  
  /// Load cached profiles from local storage
  void _loadCachedProfiles() {
    _cachedProfiles = _hiveService.getAllGrowProfiles();
    _notifyListeners();
  }
  
  /// Notify listeners of changes
  void _notifyListeners() {
    _profilesStreamController.add(_cachedProfiles);
  }
  
  /// Get all grow profiles
  Future<List<GrowProfile>> getProfiles() async {
    // If online, try to sync first
    if (_connectivityService.isConnected) {
      await _syncProfiles();
    }
    
    // Return cached profiles (local storage)
    return _cachedProfiles;
  }
  
  /// Get a grow profile by ID
  Future<GrowProfile?> getProfile(String id) async {
    // Check local cache first
    GrowProfile? profile = _hiveService.getGrowProfile(id);
    
    // If online and profile not found or synced is false, try to fetch from remote
    if (_connectivityService.isConnected && (profile == null || !profile.synced)) {
      try {
        final profiles = await _firebaseService.fetchGrowProfiles(await SharedPrefs.getUserId() ?? '');
        final remoteProfile = profiles.firstWhere((p) => p.id == id, orElse: () => profile!);
        
        // Update local cache
        await _hiveService.saveGrowProfile(remoteProfile);
        
        // Update cached profiles
        int index = _cachedProfiles.indexWhere((p) => p.id == id);
        if (index != -1) {
          _cachedProfiles[index] = remoteProfile;
        } else {
          _cachedProfiles.add(remoteProfile);
        }
        
        _notifyListeners();
        
        return remoteProfile;
      } catch (e) {
        // If remote fetch fails, return local profile
        return profile;
      }
    }
    
    return profile;
  }
  
  /// Create a new grow profile
  Future<GrowProfile> createProfile(GrowProfile profile) async {
    // If online, create on remote and update local
    if (_connectivityService.isConnected) {
      try {
        final createdProfile = await _firebaseService.createGrowProfile(profile);
        
        // Update local cache
        await _hiveService.saveGrowProfile(createdProfile);
        
        // Update cached profiles
        _cachedProfiles.add(createdProfile);
        _notifyListeners();
        
        return createdProfile;
      } catch (e) {
        // If remote creation fails, save locally with synced = false
        return _saveProfileOffline(profile);
      }
    } else {
      // If offline, save locally with synced = false
      return _saveProfileOffline(profile);
    }
  }
  
  /// Save a grow profile offline with pending sync
  Future<GrowProfile> _saveProfileOffline(GrowProfile profile) async {
    // Set synced to false
    final offlineProfile = profile.copyWith(synced: false);
    
    // Save to local storage
    await _hiveService.saveGrowProfile(offlineProfile);
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: profile.id,
      itemType: 'grow_profile',
      operation: 'create',
      data: offlineProfile.toMap(),
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached profiles
    _cachedProfiles.add(offlineProfile);
    _notifyListeners();
    
    return offlineProfile;
  }
  
  /// Update an existing grow profile
  Future<void> updateProfile(GrowProfile profile) async {
    // If online, update on remote and local
    if (_connectivityService.isConnected) {
      try {
        await _firebaseService.updateGrowProfile(profile);
        
        // Update local cache with synced = true
        final updatedProfile = profile.copyWith(synced: true);
        await _hiveService.saveGrowProfile(updatedProfile);
        
        // Update cached profiles
        int index = _cachedProfiles.indexWhere((p) => p.id == profile.id);
        if (index != -1) {
          _cachedProfiles[index] = updatedProfile;
        }
        
        _notifyListeners();
      } catch (e) {
        // If remote update fails, update locally with synced = false
        await _updateProfileOffline(profile);
      }
    } else {
      // If offline, update locally with synced = false
      await _updateProfileOffline(profile);
    }
  }
  
  /// Update a grow profile offline with pending sync
  Future<void> _updateProfileOffline(GrowProfile profile) async {
    // Set synced to false
    final offlineProfile = profile.copyWith(synced: false);
    
    // Save to local storage
    await _hiveService.saveGrowProfile(offlineProfile);
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: profile.id,
      itemType: 'grow_profile',
      operation: 'update',
      data: offlineProfile.toMap(),
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached profiles
    int index = _cachedProfiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _cachedProfiles[index] = offlineProfile;
    }
    
    _notifyListeners();
  }
  
  /// Delete a grow profile
  Future<void> deleteProfile(String id) async {
    // If online, delete from remote and local
    if (_connectivityService.isConnected) {
      try {
        await _firebaseService.deleteGrowProfile(id);
        
        // Delete from local storage
        await _hiveService.deleteGrowProfile(id);
        
        // Update cached profiles
        _cachedProfiles.removeWhere((p) => p.id == id);
        _notifyListeners();
      } catch (e) {
        // If remote deletion fails, mark for deletion locally
        await _deleteProfileOffline(id);
      }
    } else {
      // If offline, mark for deletion locally
      await _deleteProfileOffline(id);
    }
  }
  
  /// Mark a grow profile for deletion offline with pending sync
  Future<void> _deleteProfileOffline(String id) async {
    // Get the profile
    final profile = _hiveService.getGrowProfile(id);
    if (profile == null) return;
    
    // Add to pending sync items
    final pendingItem = PendingSyncItem(
      id: id,
      itemType: 'grow_profile',
      operation: 'delete',
      data: {'id': id},
    );
    
    await _hiveService.savePendingSyncItem(pendingItem);
    
    // Update cached profiles
    int index = _cachedProfiles.indexWhere((p) => p.id == id);
    if (index != -1) {
      _cachedProfiles[index] = profile.copyWith(synced: false);
    }
    
    _notifyListeners();
  }
  
  /// Sync grow profiles with remote
  Future<void> _syncProfiles() async {
    try {
      // Get user ID
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;
      
      // Fetch profiles from remote
      final remoteProfiles = await _firebaseService.fetchGrowProfiles(userId);
      
      // Process pending sync items
      await _processPendingSyncItems();
      
      // Update local storage with remote profiles
      for (var profile in remoteProfiles) {
        await _hiveService.saveGrowProfile(profile);
      }
      
      // Update cached profiles
      _cachedProfiles = remoteProfiles;
      _notifyListeners();
    } catch (e) {
      // If sync fails, use local profiles
      _loadCachedProfiles();
    }
  }
  
  /// Process pending sync items
  Future<void> _processPendingSyncItems() async {
    try {
      // Get all pending sync items for grow profiles
      final pendingItems = _hiveService.getPendingSyncItemsByType('grow_profile');
      
      for (var item in pendingItems) {
        try {
          switch (item.operation) {
            case 'create':
              // Create profile on remote
              final profile = GrowProfile.fromMap(
                item.id,
                item.data,
              );
              await _firebaseService.createGrowProfile(profile);
              break;
            case 'update':
              // Update profile on remote
              final profile = GrowProfile.fromMap(
                item.id,
                item.data,
              );
              await _firebaseService.updateGrowProfile(profile);
              break;
            case 'delete':
              // Delete profile on remote
              await _firebaseService.deleteGrowProfile(item.id);
              // Remove from local storage
              await _hiveService.deleteGrowProfile(item.id);
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
      await _syncProfiles();
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _profilesStreamController.close();
  }
}
