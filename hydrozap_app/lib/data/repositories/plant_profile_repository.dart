import 'dart:async';
import 'package:hydrozap_app/core/models/plant_profile_model.dart';
import 'package:hydrozap_app/core/services/connectivity_service.dart';
import 'package:hydrozap_app/data/local/hive_service.dart';
import 'package:hydrozap_app/core/api/api_service.dart';

/// Repository for plant profile-related operations with offline-first support
class PlantProfileRepository {
  final HiveService _hiveService = HiveService();
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Stream controller for plant profiles
  final _profilesStreamController = StreamController<List<PlantProfile>>.broadcast();
  
  // Stream of plant profiles
  Stream<List<PlantProfile>> get profilesStream => _profilesStreamController.stream;
  
  // Current list of plant profiles
  List<PlantProfile> _cachedProfiles = [];
  
  PlantProfileRepository() {
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
    try {
      _cachedProfiles = _hiveService.getAllPlantProfiles();
      _notifyListeners();
    } catch (e) {
      print("Error loading cached plant profiles: $e");
      _cachedProfiles = [];
      _notifyListeners();
    }
  }
  
  /// Notify listeners of changes
  void _notifyListeners() {
    _profilesStreamController.add(_cachedProfiles);
  }
  
  /// Get all plant profiles
  Future<List<PlantProfile>> getProfiles({String? userId}) async {
    // If online, try to sync first
    if (_connectivityService.isConnected) {
      await _syncProfiles(userId: userId);
    }
    
    // Return cached profiles (local storage)
    if (userId != null) {
      // Return both user and default profiles
      return _cachedProfiles.where((profile) => profile.userId == userId || profile.userId == null).toList();
    }
    return _cachedProfiles;
  }
  
  /// Get a plant profile by ID
  Future<PlantProfile?> getProfile(String id) async {
    // Check local cache first
    PlantProfile? profile = _hiveService.getPlantProfile(id);
    
    // If online and profile not found, try to fetch from remote
    if (_connectivityService.isConnected && profile == null) {
      try {
        final remoteProfile = await _apiService.getPlantProfile(id);
        
        if (remoteProfile != null) {
          // Update local cache
          await _hiveService.savePlantProfile(remoteProfile);
          
          // Update cached profiles
          int index = _cachedProfiles.indexWhere((p) => p.id == id);
          if (index != -1) {
            _cachedProfiles[index] = remoteProfile;
          } else {
            _cachedProfiles.add(remoteProfile);
          }
          
          _notifyListeners();
          
          return remoteProfile;
        }
      } catch (e) {
        print("Error fetching plant profile from API: $e");
        // If remote fetch fails, return local profile
        return profile;
      }
    }
    
    return profile;
  }
  
  /// Sync plant profiles with remote
  Future<void> _syncProfiles({String? userId}) async {
    try {
      // Fetch profiles from remote
      final remoteProfiles = await _apiService.getPlantProfiles(userId: userId);
      
      // Update local storage with remote profiles
      for (var profile in remoteProfiles) {
        await _hiveService.savePlantProfile(profile);
      }
      
      // Update cached profiles
      _cachedProfiles = remoteProfiles;
      _notifyListeners();
    } catch (e) {
      print("Error syncing plant profiles: $e");
      // If sync fails, use local profiles
      _loadCachedProfiles();
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