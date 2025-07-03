import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/core/models/grow_model.dart';
import 'package:hydrozap_app/core/models/grow_profile_model.dart';
import 'package:hydrozap_app/core/models/alert_model.dart';
import 'package:hydrozap_app/core/models/harvest_log_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../local/shared_prefs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hydrozap_app/core/utils/logger.dart';

/// FirebaseService handles all remote database operations
class FirebaseService {
  // Firebase Realtime Database URL
  static const String _baseUrl = 'https://hydroponics-1bab7-default-rtdb.firebaseio.com/';
  
  // Firebase Auth and Google Sign In - lazy initialization
  FirebaseAuth get _auth => FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: kIsWeb ? '182641552206-nptt4ghfvv5sr933vkp8ou4lb38umhme.apps.googleusercontent.com' : null
  );
  
  // Singleton instance
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal() {
    // Initialize Firebase when this service is first instantiated
    _initializeFirebase();
  }
  
  /// Initialize Firebase if needed
  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized
      Firebase.app();
      logger.d('Firebase already initialized');
    } catch (e) {
      // Firebase not initialized, initialize it
      logger.d('Initializing Firebase for the first time');
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBxr6fiKPQMKtRPKmynPZP9JO54tid9jP0",
            appId: "1:246984811775:web:9cd5bed9ff95b85f39c754",
            messagingSenderId: "246984811775",
            projectId: "hydroponics-1bab7",
            authDomain: "hydroponics-1bab7.firebaseapp.com",
            databaseURL: "https://hydroponics-1bab7-default-rtdb.firebaseio.com",
            storageBucket: "hydroponics-1bab7.appspot.com",
          ),
        );
      } catch (initError) {
        // Handle initialization errors
        logger.e('Firebase initialization error: $initError');
        if (initError.toString().contains('duplicate-app')) {
          logger.d('Using existing Firebase app');
        }
      }
    }
  }
  
  // AUTHENTICATION OPERATIONS
  
  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If user cancels the sign-in process
      if (googleUser == null) return null;
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      logger.e('Error during Google sign in: $e');
      return null;
    }
  }
  
  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      // Clear shared preferences first
      await SharedPrefs.clearUserData();
      // Then sign out from Firebase and Google
      await _auth.signOut();
      await _googleSignIn.signOut();
      logger.i('User signed out successfully');
    } catch (e) {
      logger.e('Error during sign out: $e');
    }
  }
  
  /// Get current user
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      logger.e('Error getting current user: $e');
      return null;
    }
  }
  
  // DEVICE OPERATIONS
  
  /// Fetch all devices for a user
  Future<List<DeviceModel>> fetchDevices(String userId) async {
    final url = '$_baseUrl/devices.json?orderBy="user_id"&equalTo="$userId"';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<DeviceModel> devices = [];
        
        data.forEach((key, value) {
          devices.add(DeviceModel.fromJson(key, value));
        });
        
        return devices;
      } else {
        throw Exception('Failed to load devices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch devices: $e');
    }
  }
  
  /// Create a new device
  Future<DeviceModel> createDevice(DeviceModel device) async {
    final url = '$_baseUrl/devices.json';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(device.toJson()),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String id = data['name']; // Firebase generates ID
        
        // Return device with the generated ID
        return device.copyWith(id: id);
      } else {
        throw Exception('Failed to create device: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create device: $e');
    }
  }
  
  /// Update an existing device
  Future<void> updateDevice(DeviceModel device) async {
    final url = '$_baseUrl/devices/${device.id}.json';
    
    try {
      final response = await http.patch(
        Uri.parse(url),
        body: json.encode(device.toJson()),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update device: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update device: $e');
    }
  }
  
  /// Delete a device
  Future<void> deleteDevice(String deviceId) async {
    final url = '$_baseUrl/devices/$deviceId.json';
    
    try {
      final response = await http.delete(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete device: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete device: $e');
    }
  }
  
  // GROW PROFILE OPERATIONS
  
  /// Fetch all grow profiles for a user
  Future<List<GrowProfile>> fetchGrowProfiles(String userId) async {
    final url = '$_baseUrl/grow_profiles.json?orderBy="user_id"&equalTo="$userId"';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<GrowProfile> profiles = [];
        
        data.forEach((key, value) {
          profiles.add(GrowProfile.fromMap(key, value));
        });
        
        return profiles;
      } else {
        throw Exception('Failed to load grow profiles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch grow profiles: $e');
    }
  }
  
  /// Create a new grow profile
  Future<GrowProfile> createGrowProfile(GrowProfile profile) async {
    final url = '$_baseUrl/grow_profiles.json';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(profile.toMap()),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String id = data['name']; // Firebase generates ID
        
        // Return profile with the generated ID
        return profile.copyWith(id: id);
      } else {
        throw Exception('Failed to create grow profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create grow profile: $e');
    }
  }
  
  /// Update an existing grow profile
  Future<void> updateGrowProfile(GrowProfile profile) async {
    final url = '$_baseUrl/grow_profiles/${profile.id}.json';
    
    try {
      final response = await http.patch(
        Uri.parse(url),
        body: json.encode(profile.toMap()),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update grow profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update grow profile: $e');
    }
  }
  
  /// Delete a grow profile
  Future<void> deleteGrowProfile(String profileId) async {
    final url = '$_baseUrl/grow_profiles/$profileId.json';
    
    try {
      final response = await http.delete(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete grow profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete grow profile: $e');
    }
  }
  
  // GROW OPERATIONS
  
  /// Fetch all grows for a user
  Future<List<Grow>> fetchGrows(String userId) async {
    final url = '$_baseUrl/grows.json?orderBy="user_id"&equalTo="$userId"';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Grow> grows = [];
        
        data.forEach((key, value) {
          final grow = Grow.fromJson(value);
          grows.add(grow.copyWith(growId: key));
        });
        
        return grows;
      } else {
        throw Exception('Failed to load grows: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch grows: $e');
    }
  }
  
  /// Create a new grow
  Future<Grow> createGrow(Grow grow) async {
    final url = '$_baseUrl/grows.json';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(grow.toJson()),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String id = data['name']; // Firebase generates ID
        
        // Return grow with the generated ID
        return grow.copyWith(growId: id);
      } else {
        throw Exception('Failed to create grow: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create grow: $e');
    }
  }
  
  /// Update an existing grow
  Future<void> updateGrow(Grow grow) async {
    final url = '$_baseUrl/grows/${grow.growId}.json';
    
    try {
      final response = await http.patch(
        Uri.parse(url),
        body: json.encode(grow.toJson()),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update grow: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update grow: $e');
    }
  }
  
  /// Delete a grow
  Future<void> deleteGrow(String growId) async {
    final url = '$_baseUrl/grows/$growId.json';
    
    try {
      final response = await http.delete(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete grow: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete grow: $e');
    }
  }
  
  // ALERT OPERATIONS
  
  /// Fetch all alerts for a device
  Future<List<Alert>> fetchAlerts(String deviceId) async {
    final url = '$_baseUrl/alerts.json?orderBy="device_id"&equalTo="$deviceId"';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Alert> alerts = [];
        
        data.forEach((key, value) {
          final alert = Alert.fromJson(value);
          alerts.add(alert.copyWith(alertId: key));
        });
        
        return alerts;
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }
  
  /// Create a new alert
  Future<Alert> createAlert(Alert alert) async {
    final url = '$_baseUrl/alerts.json';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(alert.toJson()),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String id = data['name']; // Firebase generates ID
        
        // Return alert with the generated ID
        return alert.copyWith(alertId: id);
      } else {
        throw Exception('Failed to create alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }
  
  /// Update an existing alert
  Future<void> updateAlert(Alert alert) async {
    final url = '$_baseUrl/alerts/${alert.alertId}.json';
    
    try {
      final response = await http.patch(
        Uri.parse(url),
        body: json.encode(alert.toJson()),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update alert: $e');
    }
  }
  
  /// Delete an alert
  Future<void> deleteAlert(String alertId) async {
    final url = '$_baseUrl/alerts/$alertId.json';
    
    try {
      final response = await http.delete(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete alert: $e');
    }
  }
  
  // HARVEST LOG OPERATIONS
  
  /// Fetch all harvest logs for a user
  Future<List<HarvestLog>> fetchHarvestLogs(String userId) async {
    final url = '$_baseUrl/harvest_logs.json';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<HarvestLog> logs = [];
        
        data.forEach((key, value) {
          final log = HarvestLog.fromJson(value);
          logs.add(log.copyWith(logId: key));
        });
        
        return logs;
      } else {
        throw Exception('Failed to load harvest logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch harvest logs: $e');
    }
  }
  
  /// Create a new harvest log
  Future<HarvestLog> createHarvestLog(HarvestLog log) async {
    final url = '$_baseUrl/harvest_logs.json';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(log.toJson()),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String id = data['name']; // Firebase generates ID
        
        // Return log with the generated ID
        return log.copyWith(logId: id);
      } else {
        throw Exception('Failed to create harvest log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create harvest log: $e');
    }
  }
  
  /// Update an existing harvest log
  Future<void> updateHarvestLog(HarvestLog log) async {
    final url = '$_baseUrl/harvest_logs/${log.logId}.json';
    
    try {
      final response = await http.patch(
        Uri.parse(url),
        body: json.encode(log.toJson()),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update harvest log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update harvest log: $e');
    }
  }
  
  /// Delete a harvest log
  Future<void> deleteHarvestLog(String logId) async {
    final url = '$_baseUrl/harvest_logs/$logId.json';
    
    try {
      final response = await http.delete(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete harvest log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete harvest log: $e');
    }
  }
  
  // FEEDBACK OPERATIONS
  
  /// Submit user feedback
  Future<void> submitFeedback(Map<String, dynamic> feedbackData) async {
    // API endpoint URL for feedback submission
    const apiUrl = 'https://hydrozap-api.example.com/feedback/';
    
    try {
      // Add user ID if authenticated
      final currentUser = getCurrentUser();
      if (currentUser != null) {
        feedbackData['user_id'] = currentUser.uid;
      }
      
      // Send feedback to backend API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(feedbackData),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        // Parse the error message from the response if available
        Map<String, dynamic> errorData = {};
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          // Fallback error message if parsing fails
          throw Exception('Failed to submit feedback: ${response.statusCode}');
        }
        
        throw Exception(errorData['error'] ?? 'Failed to submit feedback');
      }
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
} 