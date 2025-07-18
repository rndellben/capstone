// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api/api_service.dart';
import '../core/services/push_notification_service.dart';
import '../data/remote/firebase_service.dart';
import '../data/local/shared_prefs.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();
  PushNotificationService? _pushNotificationService;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Initialize push notification service
  void initializePushNotifications(BuildContext context) {
    if (_pushNotificationService == null) {
      _pushNotificationService = Provider.of<PushNotificationService>(context, listen: false);
    }
  }

  // Subscribe to user-specific topics for push notifications
  Future<void> _subscribeToUserTopics(String userId) async {
    if (_pushNotificationService != null) {
      await _pushNotificationService!.subscribeToUserTopics(userId);
    }
  }

  Future<Map<String, dynamic>?> login(String identifier, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService().loginUser(identifier, password);
      _isLoading = false;
      notifyListeners();

      if (response != null && response['token'] != null) {
        // Save user ID to shared preferences if available
        if (response['user'] != null && response['user']['uid'] != null) {
          final userId = response['user']['uid'];
          await SharedPrefs.setUserId(userId);
          
          // Save username if available
          if (response['user']['username'] != null) {
            await SharedPrefs.setUserName(response['user']['username']);
          }
          
          // Subscribe to user topics for push notifications
          await _subscribeToUserTopics(userId);
        }
        // ✅ Return the response with user data
        return response;
      } else {
        return null; // Return null if login fails
      }
    } catch (e) {
      print("Login error: $e");
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> googleLogin() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Use Firebase service to handle Google sign-in
      final userCredential = await _firebaseService.signInWithGoogle();
      
      // If sign-in is cancelled or fails
      if (userCredential == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Get the ID token from Firebase
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Send the ID token to our backend
      final response = await _apiService.googleLoginUser(idToken);
      
      _isLoading = false;
      notifyListeners();
      
      // Save user ID to shared preferences if available
      if (response != null && response['user'] != null && response['user']['uid'] != null) {
        final userId = response['user']['uid'];
        await SharedPrefs.setUserId(userId);
        
        // Save username if available
        if (response['user']['username'] != null) {
            await SharedPrefs.setUserName(response['user']['username']);
        } else if (response['user']['email'] != null) {
            // Use email as fallback for username
            final email = response['user']['email'];
            final username = email.split('@')[0]; // Use part before @ as username
            await SharedPrefs.setUserName(username);
        }
        
        // Subscribe to user topics for push notifications
        await _subscribeToUserTopics(userId);
      }
      
      return response;
    } catch (e) {
      print("Google login error: $e");
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.registerUser(userData);
    _isLoading = false;
    notifyListeners();

    if (success) {
      print("Registration successful!");
      return true;
    } else {
      print("Registration failed!");
      return false;
    }
  }
  
  // Get current Firebase user
  Future<String?> getCurrentUserId() async {
    try {
      // First try to get from Firebase Auth
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser?.uid != null) {
        return currentUser!.uid;
      }
    } catch (e) {
      print("Error getting current user from Firebase: $e");
      // Continue to shared preferences if Firebase fails
    }
    
    // If not available from Firebase, try to get from shared preferences
    try {
      return await SharedPrefs.getUserId();
    } catch (e) {
      print("Error getting user ID from shared preferences: $e");
      return null;
    }
  }
  
  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final currentUser = _firebaseService.getCurrentUser();
    if (currentUser != null) {
      return true;
    }
    
    // Check in shared preferences
    final storedUserId = await SharedPrefs.getUserId();
    return storedUserId != null;
  }
  
  // Logout and unsubscribe from topics
  Future<void> logout() async {
    try {
      // Get user ID before logging out
      final userId = await getCurrentUserId();
      
      // Unsubscribe from user topics if user ID is available
      if (userId != null && _pushNotificationService != null) {
        await _pushNotificationService!.unsubscribeFromUserTopics(userId);
      }
      
      // Sign out from Firebase
      await _firebaseService.signOut();
      
      // Clear shared preferences
      await SharedPrefs.clearAll();
      
      notifyListeners();
    } catch (e) {
      print("Logout error: $e");
    }
  }
}
