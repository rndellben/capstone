import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/api/api_service.dart';
import '../core/models/plant_profile_model.dart';
import '../data/repositories/plant_profile_repository.dart';
import '../core/services/connectivity_service.dart';

class PlantProfileProvider with ChangeNotifier {
  final ApiService _apiService;
  final PlantProfileRepository _repository;
  final ConnectivityService _connectivityService;
  
  List<PlantProfile> _plantProfiles = [];
  PlantProfile? _selectedProfile;
  bool _isLoading = false;
  String? _error;

  PlantProfileProvider(
    this._apiService, {
    required PlantProfileRepository repository,
    required ConnectivityService connectivityService,
  }) : 
    _repository = repository,
    _connectivityService = connectivityService {
    // Listen to profile updates from the repository
    _repository.profilesStream.listen((profiles) {
      _plantProfiles = profiles;
      notifyListeners();
    });
  }

  List<PlantProfile> get plantProfiles => _plantProfiles;
  PlantProfile? get selectedProfile => _selectedProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _connectivityService.isConnected;

  Future<void> fetchPlantProfiles({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the repository to get profiles (with offline support)
      _plantProfiles = await _repository.getProfiles(userId: userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPlantProfile(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the repository to get the profile (with offline support)
      _selectedProfile = await _repository.getProfile(id);
      
      // If we couldn't find it, try to find it in the already loaded profiles
      _selectedProfile ??= _plantProfiles.firstWhere(
          (profile) => profile.id == id || profile.name.toLowerCase() == id.toLowerCase(),
          orElse: () => throw Exception("Plant profile not found"),
        );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print("Error fetching plant profile: $e");
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedProfile() {
    _selectedProfile = null;
    notifyListeners();
  }
  
  Future<bool> addPlantProfile(PlantProfile profile) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // First try to add the profile through the API
      final success = await _apiService.addPlantProfile(profile);
      
      if (success) {
        // If successful, add to local list and notify listeners
        _plantProfiles.add(profile);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // If API call fails but we're offline, add to local list
        if (!_connectivityService.isConnected) {
          _plantProfiles.add(profile);
          _isLoading = false;
          notifyListeners();
          return true;
        }
        
        _error = "Failed to add plant profile";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlantProfile(String identifier, Map<String, dynamic> updateData, {String? userId}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // First try to update the profile through the API
      final success = await _apiService.updatePlantProfile(identifier, updateData, userId: userId);
      
      if (success) {
        // If successful, update local list and notify listeners
        final index = _plantProfiles.indexWhere((profile) => profile.identifier == identifier);
        if (index != -1) {
          // Create updated profile
          final existingProfile = _plantProfiles[index];
          final updatedProfile = PlantProfile(
            id: existingProfile.id,
            name: updateData['name'] ?? existingProfile.name,
            identifier: existingProfile.identifier,
            notes: updateData['description'] ?? existingProfile.notes,
            optimalConditions: updateData['optimal_conditions'] != null 
                ? OptimalConditions.fromJson({'optimal_conditions': updateData['optimal_conditions']})
                : existingProfile.optimalConditions,
            growDurationDays: existingProfile.growDurationDays,
            userId: updateData['user_id'] ?? existingProfile.userId,
            mode: updateData['mode'] ?? existingProfile.mode,
          );
          
          _plantProfiles[index] = updatedProfile;
          
          // Update selected profile if it's the same one
          if (_selectedProfile?.identifier == identifier) {
            _selectedProfile = updatedProfile;
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // If API call fails but we're offline, update local list
        if (!_connectivityService.isConnected) {
          final index = _plantProfiles.indexWhere((profile) => profile.identifier == identifier);
          if (index != -1) {
            final existingProfile = _plantProfiles[index];
            final updatedProfile = PlantProfile(
              id: existingProfile.id,
              name: updateData['name'] ?? existingProfile.name,
              identifier: existingProfile.identifier,
              notes: updateData['description'] ?? existingProfile.notes,
              optimalConditions: updateData['optimal_conditions'] != null 
                  ? OptimalConditions.fromJson({'optimal_conditions': updateData['optimal_conditions']})
                  : existingProfile.optimalConditions,
              growDurationDays: existingProfile.growDurationDays,
              userId: updateData['user_id'] ?? existingProfile.userId,
              mode: updateData['mode'] ?? existingProfile.mode,
            );
            
            _plantProfiles[index] = updatedProfile;
            
            if (_selectedProfile?.identifier == identifier) {
              _selectedProfile = updatedProfile;
            }
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
        
        _error = "Failed to update plant profile";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> uploadPlantProfilesCsv({
    required String userId,
    required File csvFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.uploadPlantProfilesCsv(
        userId: userId,
        csvFile: csvFile,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'error': _error};
    }
  }
} 