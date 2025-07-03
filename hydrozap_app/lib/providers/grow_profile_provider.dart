import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/models/grow_profile_model.dart';
import '../core/models/pending_sync_item.dart';
import '../core/services/connectivity_service.dart';
import '../data/local/hive_service.dart';

class GrowProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<GrowProfile> _growProfiles = [];
  bool _isLoading = true;
  GrowProfile? selectedProfile;

  List<GrowProfile> get growProfiles => _growProfiles;
  bool get isLoading => _isLoading;

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
          fetchGrowProfiles(profileData['user_id']);
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
        
        return true;
      }
    } catch (e) {
      print("Error adding grow profile: $e");
      return false;
    }
  }

  Future<bool> updateGrowProfile(Map<String, dynamic> profileData) async {
    try {
      if (_connectivityService.isConnected) {
        // Online - send directly to API
        final success = await _apiService.updateGrowProfile(profileData);
        if (success) {
          // Get the user ID from the profile data to ensure we fetch the correct profiles
          final userId = profileData['user_id'];
          if (userId != null && userId.isNotEmpty) {
            fetchGrowProfiles(userId);
          }
        }
        return success;
      } else {
        // Offline - store locally and mark for sync
        final String profileId = profileData['id'];
        
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
        
        return true;
      }
    } catch (e) {
      print("Error updating grow profile: $e");
      return false;
    }
  }

  Future<bool> deleteGrowProfile(String profileId) async {
    final success = await _apiService.deleteGrowProfile(profileId);
    if (success) {
      _growProfiles.removeWhere((profile) => profile.id == profileId);
      notifyListeners();
    }
    return success;
  }
}
