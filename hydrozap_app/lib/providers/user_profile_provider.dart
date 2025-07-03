import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../data/local/shared_prefs.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class UserProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  bool _isOffline = false;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isOffline => _isOffline;

  /// Fetch user profile from backend with offline sync support
  Future<bool> fetchUserProfile(String uid) async {
    try {
      _isLoading = true;
      _isOffline = false;
      notifyListeners();
      print("Fetching user profile for UID: $uid");

      // First try to get the profile from the backend
      try {
        final profileData = await _apiService.getUserProfile(uid);
        print("Profile data received from API: $profileData");
        
        if (profileData != null) {
          // Process profile data
          _processProfileData(profileData);
          
          // Save to shared preferences for offline use
          await SharedPrefs.saveUserProfile(profileData);
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (e) {
        // Error communicating with the backend - check if it's a connectivity issue
        if (e is SocketException || e.toString().contains('SocketException')) {
          print("Network error, trying to load from cache: $e");
          _isOffline = true;
          // Fall through to load from cache
        } else {
          // Some other error with the API
          print("API error: $e");
          _isOffline = false;
          _userProfile = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      
      // If we're offline or the backend failed, try to load from SharedPrefs
      if (_isOffline || _userProfile == null) {
        final cachedProfile = await SharedPrefs.getUserProfile();
        if (cachedProfile != null) {
          print("Loaded profile from cache: $cachedProfile");
          _processProfileData(cachedProfile);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          print("No cached profile available");
          _userProfile = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print("Fetch user profile error: $e");
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to process profile data
  void _processProfileData(Map<String, dynamic> profileData) {
    // Split name into first and last name if it exists
    if (profileData['name'] != null) {
      List<String> nameParts = profileData['name'].split(' ');
      profileData['firstName'] = nameParts[0];
      profileData['lastName'] = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }
    
    _userProfile = profileData;
  }
  
  /// Update user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> profileData) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create a copy of profile data for API call
      final Map<String, dynamic> apiProfileData = Map.from(profileData);
      
      // Combine first and last name into full name for backend API
      if (profileData.containsKey('firstName') && profileData.containsKey('lastName')) {
        apiProfileData['name'] = '${profileData['firstName']} ${profileData['lastName']}'.trim();
        // The backend doesn't expect firstName and lastName fields
        apiProfileData.remove('firstName');
        apiProfileData.remove('lastName');
        
        print('Setting name field for API call: ${apiProfileData['name']}');
      }
      
      // Check if we're online
      bool isOnline = await _checkConnectivity();
      
      if (isOnline) {
        // If online, try to update on the server
        final success = await _apiService.updateUserProfile(uid, apiProfileData);
        
        if (success) {
          // Also save the original data (with firstName/lastName) to shared preferences
          await SharedPrefs.saveUserProfile(profileData);
          
          // Refresh profile data after update
          _processProfileData(profileData);
          _isLoading = false;
          _isOffline = false;
          notifyListeners();
          return true;
        } else {
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // If offline, save to shared preferences and mark the app as offline
        // This is a simplistic approach - a real app might queue updates for later sync
        _isOffline = true;
        await SharedPrefs.saveUserProfile(profileData);
        _processProfileData(profileData);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Update user profile error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to check connectivity
  Future<bool> _checkConnectivity() async {
    try {
      // Use the connectivity_plus package which is already imported in the app
      // Instead of using InternetAddress.lookup which is causing the error
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print("Connectivity check error: $e");
      return false;
    }
  }
  
  // Method to manually sync when connectivity is restored
  Future<bool> syncProfile(String uid) async {
    if (await _checkConnectivity()) {
      _isOffline = false;
      return await fetchUserProfile(uid);
    }
    return false;
  }
} 