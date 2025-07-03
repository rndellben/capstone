import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hydrozap_app/core/utils/logger.dart';

class SharedPrefs {
  static const String _userIdKey = 'user_id';
  static const String _userTokenKey = 'user_token';
  static const String _userProfileKey = 'user_profile';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _offlineChangesKey = 'offline_changes';

  // User ID methods
  static Future<void> setUserId(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    logger.d("User ID saved to preferences: $userId");
  }

  static Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    logger.d("Got user ID from preferences: $userId");
    return userId;
  }

  // Token methods
  static Future<void> setUserToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTokenKey, token);
  }

  static Future<String?> getUserToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }
  
  // User Profile methods for offline sync
  static Future<void> saveUserProfile(Map<String, dynamic> profileData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String profileJson = json.encode(profileData);
    await prefs.setString(_userProfileKey, profileJson);
    
    // Also update the last sync time
    await updateLastSyncTime();
    
    logger.d("User profile saved to preferences for offline use");
  }
  
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? profileJson = prefs.getString(_userProfileKey);
    
    if (profileJson != null && profileJson.isNotEmpty) {
      try {
        final Map<String, dynamic> profileData = json.decode(profileJson);
        logger.d("Retrieved user profile from preferences");
        return profileData;
      } catch (e) {
        logger.e("Error parsing stored profile data: $e");
        return null;
      }
    }
    return null;
  }
  
  // Sync timestamp methods
  static Future<void> updateLastSyncTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastSyncTimeKey, currentTime);
  }
  
  static Future<DateTime?> getLastSyncTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncTimeKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Profile Image Path
  static Future<void> setProfileImagePath(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, path);
  }

  static Future<String?> getProfileImagePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  // Offline Changes
  static Future<void> addOfflineChange(String changeType, Map<String, dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> offlineChanges = prefs.getStringList(_offlineChangesKey) ?? [];
    
    // Add new change
    final changeData = {
      'type': changeType,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data
    };
    
    // Convert to string
    final changeString = changeData.entries
        .map((entry) {
          if (entry.key == 'data') {
            final dataString = (entry.value as Map<String, dynamic>).entries
                .map((e) => '${e.key}=${e.value}')
                .join('|');
            return '${entry.key}:$dataString';
          }
          return '${entry.key}:${entry.value}';
        })
        .join(';');
    
    offlineChanges.add(changeString);
    await prefs.setStringList(_offlineChangesKey, offlineChanges);
  }

  static Future<List<Map<String, dynamic>>> getOfflineChanges() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final offlineChanges = prefs.getStringList(_offlineChangesKey) ?? [];
    
    return offlineChanges.map((changeString) {
      final Map<String, dynamic> changeData = {};
      final entries = changeString.split(';');
      
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          if (parts[0] == 'data') {
            // Parse data map
            final Map<String, dynamic> dataMap = {};
            final dataEntries = parts[1].split('|');
            
            for (final dataEntry in dataEntries) {
              final dataParts = dataEntry.split('=');
              if (dataParts.length == 2) {
                dataMap[dataParts[0]] = dataParts[1];
              }
            }
            
            changeData[parts[0]] = dataMap;
          } else {
            changeData[parts[0]] = parts[1];
          }
        }
      }
      
      return changeData;
    }).toList();
  }

  static Future<void> clearOfflineChanges() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineChangesKey);
  }

  // Clear all user data
  static Future<void> clearUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_lastSyncTimeKey);
    await prefs.remove(_profileImagePathKey);
    await prefs.remove(_offlineChangesKey);
    logger.d("User data cleared from preferences");
  }

  // Clear user ID
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }
  
  // Clear all stored preferences
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
