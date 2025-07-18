import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/models/grow_profile_model.dart';
import '../core/models/pending_sync_item.dart';
import '../core/services/connectivity_service.dart';
import '../data/local/hive_service.dart';
import '../data/local/shared_prefs.dart';
import '../data/repositories/profile_change_log_repository.dart';

class GrowProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final ProfileChangeLogRepository _changeLogRepository = ProfileChangeLogRepository();
  
  List<GrowProfile> _growProfiles = [];
  bool _isLoading = true;
  GrowProfile? selectedProfile;

  List<GrowProfile> get growProfiles => _growProfiles;
  bool get isLoading => _isLoading;

  GrowProfileProvider() {
    // Initialize the change log repository
    _changeLogRepository.initialize();
  }

  Future<void> fetchGrowProfiles(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_connectivityService.isConnected) {
        // Online - fetch from API
        final response = await _apiService.getGrowProfiles(userId);
        if (response.isNotEmpty) {
          _growProfiles = response;
          
          // Cache profiles for offline use
          for (final profile in _growProfiles) {
            await _hiveService.saveGrowProfile(profile);
          }
        } else {
          _growProfiles = []; // Ensure it sets an empty list
        }
      } else {
        // Offline - get from local storage
        _growProfiles = _hiveService.getLocalGrowProfiles(userId);
      }
    } catch (e) {
      print("Error fetching grow profiles: $e");
      
      // Try to load from local storage as fallback
      try {
        _growProfiles = _hiveService.getLocalGrowProfiles(userId);
      } catch (cacheError) {
        print("Error loading from cache: $cacheError");
        _growProfiles = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGrowProfile(Map<String, dynamic> profileData) async {
    try {
      if (_connectivityService.isConnected) {
        // Online - send directly to API
        final success = await _apiService.addGrowProfile(profileData);
        if (success) {
          // Fetch the updated profiles
          fetchGrowProfiles(profileData['user_id']);
          
          // Log the creation
          await _logProfileChange(
            profileId: profileData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            userId: profileData['user_id'],
            changeType: 'create',
            previousValues: {},
            newValues: profileData,
            changedFields: profileData,
          );
        }
        return success;
      } else {
        // Offline - store locally and mark for sync
        final String profileId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Create a GrowProfile object
        final Map<String, dynamic> profileWithId = {...profileData, 'id': profileId};
        final newProfile = GrowProfile.fromMap(profileId, profileWithId);
        
        // Create pending sync item
        final pendingItem = PendingSyncItem(
          id: profileId,
          itemType: 'grow_profile',
          operation: 'create',
          data: profileData,
        );
        
        // Save the profile locally
        await _hiveService.saveGrowProfile(newProfile);
        
        // Add to pending sync items
        await _hiveService.addPendingSyncItem(pendingItem);
        
        // Update the local list
        _growProfiles.add(newProfile);
        notifyListeners();
        
        // Log the creation
        await _logProfileChange(
          profileId: profileId,
          userId: profileData['user_id'],
          changeType: 'create',
          previousValues: {},
          newValues: profileData,
          changedFields: profileData,
        );
        
        return true;
      }
    } catch (e) {
      print("Error adding grow profile: $e");
      return false;
    }
  }

  Future<bool> updateGrowProfile(Map<String, dynamic> profileData) async {
    try {
      final String profileId = profileData['id'];
      
      // Find the existing profile to compare changes
      final existingProfile = _growProfiles.firstWhere(
        (profile) => profile.id == profileId,
        orElse: () => GrowProfile.fromMap(profileId, {}),
      );
      
      // Convert to map for comparison
      final existingProfileData = existingProfile.toMap();
      
      if (_connectivityService.isConnected) {
        // Online - send directly to API
        final success = await _apiService.updateGrowProfile(profileData);
        if (success) {
          // Get the user ID from the profile data to ensure we fetch the correct profiles
          final userId = profileData['user_id'];
          if (userId != null && userId.isNotEmpty) {
            fetchGrowProfiles(userId);
          }
          
          // Log the update
          await _logProfileChange(
            profileId: profileId,
            userId: profileData['user_id'],
            changeType: 'update',
            previousValues: existingProfileData,
            newValues: profileData,
            changedFields: _getChangedFields(existingProfileData, profileData),
          );
        }
        return success;
      } else {
        // Offline - store locally and mark for sync
        // Create a GrowProfile object
        final updatedProfile = GrowProfile.fromMap(profileId, profileData);
        
        // Create pending sync item
        final pendingItem = PendingSyncItem(
          id: profileId,
          itemType: 'grow_profile',
          operation: 'update',
          data: profileData,
        );
        
        // Update the profile locally
        await _hiveService.updateGrowProfile(updatedProfile);
        
        // Add to pending sync items
        await _hiveService.addPendingSyncItem(pendingItem);
        
        // Update the local list
        final index = _growProfiles.indexWhere((profile) => profile.id == profileId);
        if (index != -1) {
          _growProfiles[index] = updatedProfile;
          notifyListeners();
        }
        
        // Log the update
        await _logProfileChange(
          profileId: profileId,
          userId: profileData['user_id'],
          changeType: 'update',
          previousValues: existingProfileData,
          newValues: profileData,
          changedFields: _getChangedFields(existingProfileData, profileData),
        );
        
        return true;
      }
    } catch (e) {
      print("Error updating grow profile: $e");
      return false;
    }
  }

  Future<bool> deleteGrowProfile(String profileId) async {
    try {
      // Find the existing profile before deletion
      final existingProfile = _growProfiles.firstWhere(
        (profile) => profile.id == profileId,
        orElse: () => GrowProfile.fromMap(profileId, {}),
      );
      
      // Convert to map for logging
      final existingProfileData = existingProfile.toMap();
      final userId = existingProfile.userId;
      
      final success = await _apiService.deleteGrowProfile(profileId);
      if (success) {
        _growProfiles.removeWhere((profile) => profile.id == profileId);
        notifyListeners();
        
        // Log the deletion
        await _logProfileChange(
          profileId: profileId,
          userId: userId,
          changeType: 'delete',
          previousValues: existingProfileData,
          newValues: {},
          changedFields: existingProfileData,
        );
      }
      return success;
    } catch (e) {
      print("Error deleting grow profile: $e");
      return false;
    }
  }
  
  // Helper method to get changed fields between two profile data maps
  Map<String, dynamic> _getChangedFields(
    Map<String, dynamic> oldData, 
    Map<String, dynamic> newData
  ) {
    final changedFields = <String, dynamic>{};
    
    // Compare basic fields
    for (final key in ['name', 'grow_duration_days', 'is_active', 'plant_profile_id', 'mode']) {
      if (oldData[key] != newData[key]) {
        changedFields[key] = newData[key];
      }
    }
    
    // Compare optimal conditions if they exist
    if (oldData.containsKey('optimal_conditions') && newData.containsKey('optimal_conditions')) {
      final oldConditions = oldData['optimal_conditions'];
      final newConditions = newData['optimal_conditions'];
      
      // Compare each stage
      for (final stage in ['transplanting', 'vegetative', 'maturation']) {
        if (oldConditions.containsKey(stage) && newConditions.containsKey(stage)) {
          final oldStage = oldConditions[stage];
          final newStage = newConditions[stage];
          
          // Compare each parameter
          for (final param in ['temperature_range', 'humidity_range', 'ph_range', 'ec_range', 'tds_range']) {
            if (oldStage.containsKey(param) && newStage.containsKey(param)) {
              if (oldStage[param].toString() != newStage[param].toString()) {
                changedFields['optimal_conditions.$stage.$param'] = newStage[param];
              }
            }
          }
        }
      }
    }
    
    return changedFields;
  }
  
  // Log profile changes
  Future<void> _logProfileChange({
    required String profileId,
    required String userId,
    required String changeType,
    required Map<String, dynamic> previousValues,
    required Map<String, dynamic> newValues,
    required Map<String, dynamic> changedFields,
  }) async {
    try {
      // Get the user name from shared preferences
      final userName = await SharedPrefs.getUserName() ?? 'Unknown User';
      
      // Create the change log
      await _changeLogRepository.createChangeLog(
        profileId: profileId,
        userId: userId,
        userName: userName,
        changedFields: changedFields,
        previousValues: previousValues,
        newValues: newValues,
        changeType: changeType,
      );
    } catch (e) {
      print("Error logging profile change: $e");
    }
  }
  
  // Get change logs for a specific profile
  Future<List<dynamic>> getProfileChangeLogs(String profileId) async {
    return await _changeLogRepository.getChangeLogsForProfile(profileId, syncWithRemote: false);
  }
  
  // Get the change log repository for manual syncing
  ProfileChangeLogRepository getChangeLogRepository() {
    return _changeLogRepository;
  }
}
