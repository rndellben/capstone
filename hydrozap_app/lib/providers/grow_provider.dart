import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/models/grow_model.dart';
import '../core/models/pending_sync_item.dart';
import '../core/api/api_service.dart';
import '../core/services/connectivity_service.dart';
import '../data/local/hive_service.dart';
import '../core/utils/logger.dart';
import '../providers/grow_profile_provider.dart';

class GrowProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<Grow> _grows = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Grow> get grows => _grows.where((grow) => grow.status != 'harvested').toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch grows from API for a specific user
  Future<void> fetchGrows(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      if (_connectivityService.isConnected) {
        // Online - fetch from API
        _grows = await _apiService.getGrows(userId);
      } else {
        // Offline - get from local storage
        _grows = _hiveService.getLocalGrows(userId);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Failed to fetch grows: ${e.toString()}";
      notifyListeners();
      logger.e("Error fetching grows: $e");  
    }
  }

  // Add a new grow
  Future<bool> addGrow(Grow grow) async {
    try {
      _errorMessage = null;
      final growProfileProvider = GrowProfileProvider();
      if (_connectivityService.isConnected) {
        // Online - send directly to API
        final success = await _apiService.addGrow(grow);
        if (success) {
          _grows.add(grow);
          // Set the grow profile as active
          await growProfileProvider.updateGrowProfile({
            'id': grow.profileId,
            'is_active': true,
            'user_id': grow.userId,
          });
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // Check if device is already assigned in local storage
        final existingGrow = _grows.where((g) => g.deviceId == grow.deviceId).toList();
        if (existingGrow.isNotEmpty) {
          _errorMessage = "Device is already assigned to an active grow";
          notifyListeners();
          return false;
        }
        
        // Offline - store locally and mark for sync
        final pendingItem = PendingSyncItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemType: 'grow',
          operation: 'create',
          data: grow.toJson(),
        );
        
        // Save the grow locally
        await _hiveService.addLocalGrow(grow);
        
        // Add to pending sync items
        await _hiveService.addPendingSyncItem(pendingItem);
        
        // Update the local list
        _grows.add(grow);
        
        // Set the grow profile as active locally
        await growProfileProvider.updateGrowProfile({
          'id': grow.profileId,
          'is_active': true,
          'user_id': grow.userId,
        });
        
        notifyListeners();
        
        return true;
      }
    } catch (e) {
      logger.e("Error adding grow: $e");
      _errorMessage = "Failed to add grow: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }
  
  // Clear error message
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Delete a grow record
  Future<bool> deleteGrow(String growId, String userId) async {
    try {
      _errorMessage = null;
      
      if (_connectivityService.isConnected) {
        // Online - send delete request to API
        final result = await _apiService.deleteGrow(growId);
        
        if (result['success']) {
          // Remove from local list
          _grows.removeWhere((grow) => grow.growId == growId);
          // Also remove from local storage
          await _hiveService.deleteLocalGrow(growId);
          notifyListeners();
          return true;
        } else {
          // Handle error - Check if grow is active
          if (result['statusCode'] == 409) {
            _errorMessage = "Cannot delete an active grow. Please harvest it first.";
          } else {
            _errorMessage = result['message'] ?? "Failed to delete grow.";
          }
          notifyListeners();
          return false;
        }
      } else {
        // Check if grow is active (not harvested) in local list
        final grow = _grows.firstWhere(
          (g) => g.growId == growId,
          orElse: () => Grow(
            userId: userId,
            deviceId: '',
            profileId: '',
            startDate: '',
            status: 'harvested' // Default to harvested to allow deletion if not found
          )
        );
        
        // If grow is active (not harvested), prevent deletion
        if (grow.status == 'active' && grow.harvestDate == null) {
          _errorMessage = "Cannot delete an active grow. Please harvest it first.";
          notifyListeners();
          return false;
        }
        
        // Offline - mark for deletion when back online
        final pendingItem = PendingSyncItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemType: 'grow',
          operation: 'delete',
          data: {'grow_id': growId, 'user_id': userId},
        );
        
        // Add to pending sync items
        await _hiveService.addPendingSyncItem(pendingItem);
        
        // Remove from local list
        _grows.removeWhere((grow) => grow.growId == growId);
        // Also remove from local storage
        await _hiveService.deleteLocalGrow(growId);
        notifyListeners();
        
        return true;
      }
    } catch (e) {
      logger.e("Error deleting grow: $e");
      _errorMessage = "Failed to delete grow: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }
}
