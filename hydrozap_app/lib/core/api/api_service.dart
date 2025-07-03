import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoints.dart';
import '../models/device_model.dart';
import '../models/alert_model.dart';
import '../models/grow_model.dart';
import '../models/actuator_condition.dart';
import '../models/grow_profile_model.dart';
import '../models/plant_profile_model.dart' as plant;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../data/local/shared_prefs.dart';
import '../utils/logger.dart';

class ApiService {
  /// ✅ Register a new user
  Future<bool> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  /// ✅ Login user using email or username
  Future<Map<String, dynamic>?> loginUser(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": identifier,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> googleLoginUser(String idToken) async {
  try {
    final response = await http.post(
      Uri.parse(ApiEndpoints.googleLogin),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idToken": idToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}
   /// ✅ Reset user password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.reset),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return {"success": true};
      } else {
        final responseData = jsonDecode(response.body);
        return {"success": false, "error": responseData['error'] ?? "Unknown error occurred"};
      }
    } catch (e) {
      return {"success": false, "error": "An error occurred while processing your request"};
    }
  }
  /// ✅ Fetch user profile by UID
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      // Construct the URL with query parameters
      final uri = Uri.parse(ApiEndpoints.userProfile).replace(
        queryParameters: {'uid': uid}
      );
      
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Convert the response to our User model format
        final user = User.fromJson(data);
        return {
          'firstName': user.name.split(' ').first,
          'lastName': user.name.split(' ').length > 1 ? user.name.split(' ').sublist(1).join(' ') : '',
          'email': user.email,
          'phone': user.phone,
          'username': user.username,
        };
      } else {
        logger.e("Error fetching user profile: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      logger.e("Error getting user profile: $e");
      return null;
    }
  }

  /// 📝 Update user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> profileData) async {
    try {
      // Use the correct API endpoint with trailing slash for Django
      final uri = Uri.parse(ApiEndpoints.userProfile);
      
      // Prepare the request data with uid and other profile fields
      final Map<String, dynamic> requestData = {
        "uid": uid,
      };
      
      // Add name if present
      if (profileData.containsKey('name')) {
        requestData['name'] = profileData['name'];
      }
      
      // Add username if present
      if (profileData.containsKey('username')) {
        requestData['username'] = profileData['username'];
      }
      
      // Add phone if present
      if (profileData.containsKey('phone')) {
        requestData['phone'] = profileData['phone'];
      }
      
      // Add password if present
      if (profileData.containsKey('password')) {
        requestData['password'] = profileData['password'];
      }
      
      // Log the request for debugging
      logger.d("Updating profile for UID: $uid with data: $requestData");
      
      final response = await http.patch(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        logger.i("Profile update successful");
        return true;
      } else {
        logger.e("Profile update error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      logger.e("Error updating profile: $e");
      return false;
    }
  }

  /// 📡 Get Devices by User ID
  Future<List<DeviceModel>> getDevices(String userId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.getDevices}?user_id=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['devices'] != null && data['devices'] is Map<String, dynamic>) {
          List<DeviceModel> devices = (data['devices'] as Map<String, dynamic>)
              .entries
              .map((entry) {
                return DeviceModel.fromJson(entry.key, entry.value as Map<String, dynamic>);
              })
              .toList();
          return devices;
        }
      }
      return [];
    } catch (e) {
      logger.e("Error getting devices: $e");
      return [];
    }
  }

  /// 📝 Update grow record
  Future<bool> updateGrow(Grow grow) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.updateGrow}${grow.growId}/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(grow.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      logger.e("Error updating grow: $e");
      return false;
    }
  }

  /// Get dashboard counts
  Future<Map<String, int>> getDashboardCounts(String userId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.getDashboardCounts}?user_id=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'deviceCount': data['device_count'] ?? 0,
          'alertCount': data['alert_count'] ?? 0,
          'growCount': data['grow_count'] ?? 0,
        };
      }

      return {'deviceCount': 0, 'alertCount': 0, 'growCount': 0};
    } catch (e) {
      return {'deviceCount': 0, 'alertCount': 0, 'growCount': 0};
    }
  }

  /// ➕ Add Device
  Future<bool> addDevice(DeviceModel device) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addDevice),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(device.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 📝 Update Device
  Future<bool> updateDevice(String deviceId, Map<String, dynamic> updateData) async {
    final url = Uri.parse('${ApiEndpoints.updateDevice}$deviceId/');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// ❌ Delete Device by ID
  Future<Map<String, dynamic>> deleteDevice(String deviceId) async {
    try {
      final response = await http.delete(Uri.parse('${ApiEndpoints.deleteDevice}$deviceId/'));

      if (response.statusCode == 200) {
        return {"success": true, "statusCode": response.statusCode};
      } else {
        // Try to parse the error message from the response
        String errorMessage = "Failed to delete device";
        try {
          Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": errorMessage
        };
      }
    } catch (e) {
      return {
        "success": false,
        "statusCode": 500,
        "message": "Exception: ${e.toString()}"
      };
    }
  }

  /// 🌱 Get Grow Profiles
  Future<List<GrowProfile>> getGrowProfiles(String userId) async {
    final response = await http.get(Uri.parse('${ApiEndpoints.getGrowProfiles}?user_id=$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if the grow_profiles key exists and is a Map
      if (data['grow_profiles'] == null) {
        return [];
      }
      
      if (data['grow_profiles'] is! Map) {
        return [];
      }
      
      final profilesMap = data['grow_profiles'] as Map;

      // ✅ Convert the map to a list of GrowProfile objects
      final filteredProfiles = profilesMap.entries
          .where((entry) {
            final profileUserId = entry.value['user_id'];
            final isMatch = profileUserId == userId;
            return isMatch;
          })
          .map((entry) => GrowProfile.fromMap(entry.key, entry.value))
          .toList();
      
      return filteredProfiles;
    } else {
      return [];
    }
  }

  /// 🌱 Add Grow Profile
  Future<bool> addGrowProfile(Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.addGrowProfile),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  /// 🌱 Update Grow Profile
  Future<bool> updateGrowProfile(Map<String, dynamic> profileData) async {
    final response = await http.patch(
      Uri.parse('${ApiEndpoints.updateGrowProfile}${profileData['id']}/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// ❌ Delete Grow Profile
  Future<bool> deleteGrowProfile(String profileId) async {
    final response = await http.delete(Uri.parse('${ApiEndpoints.deleteGrowProfile}$profileId/'));

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// 🔔 Get Alerts by User ID
  Future<List<Alert>> getAlerts(String userId) async {
    // Ensure we don't have any trailing slashes in the ID
    final cleanUserId = userId.endsWith('/') ? userId.substring(0, userId.length - 1) : userId;
    
    final url = '${ApiEndpoints.getAlerts}$cleanUserId/';
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      try {
        if (data['alerts'] != null && data['alerts'] is Map) {
          List<Alert> alerts = (data['alerts'] as Map)
              .entries
              .map((entry) {
                // For each alert, add the key as the alert_id if not present
                final alertData = entry.value as Map<String, dynamic>;
                if (!alertData.containsKey('alert_id')) {
                  alertData['alert_id'] = entry.key;
                }
                return Alert.fromJson(alertData);
              })
              .toList();
          
          return alerts;
        } else {
          return [];
        }
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }
  }

  /// 🔔 Trigger Alert
  Future<bool> triggerAlert(Map<String, dynamic> alertData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.triggerAlert),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(alertData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  /// 📝 Update Alert
  Future<bool> updateAlert(String alertId, String userId, Map<String, dynamic> updateData) async {
    // Ensure we don't have any trailing slashes in the IDs which would create double slashes
    final cleanUserId = userId.endsWith('/') ? userId.substring(0, userId.length - 1) : userId;
    final cleanAlertId = alertId.endsWith('/') ? alertId.substring(0, alertId.length - 1) : alertId;
    
    // Construct the URL with the correct format
    final url = '${ApiEndpoints.getAlerts}$cleanUserId/$cleanAlertId/';
    
    // Use getAlerts endpoint with the pattern <userId>/<alertId>/
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// ❌ Delete Alert by ID
  Future<bool> deleteAlert(String alertId, String userId) async {
    // Ensure we don't have any trailing slashes in the IDs which would create double slashes
    final cleanUserId = userId.endsWith('/') ? userId.substring(0, userId.length - 1) : userId;
    final cleanAlertId = alertId.endsWith('/') ? alertId.substring(0, alertId.length - 1) : alertId;
    
    // Construct the URL with the correct format
    final url = '${ApiEndpoints.deleteAlert}$cleanUserId/$cleanAlertId/';
    
    final response = await http.delete(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<ActuatorCondition>> getActuatorConditions(String deviceId) async {
    final url = Uri.parse('${ApiEndpoints.getActuatorConditions}$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((condition) => ActuatorCondition.fromJson(condition))
            .toList();
      } else {
        throw Exception('Failed to load actuator conditions');
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> addActuatorCondition(Map<String, dynamic> conditionData) async {
    final url = Uri.parse(ApiEndpoints.addActuatorCondition);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(conditionData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteActuatorCondition(String conditionId) async {
    final url = Uri.parse("${ApiEndpoints.deleteActuatorCondition}$conditionId/");

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Fetch all grow records for a specific user
  Future<List<Grow>> getGrows(String userId) async {
    final response = await http.get(Uri.parse('${ApiEndpoints.getGrows}?user_id=$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is Map) {
        // Filter grows by user_id and convert to list
        return data.entries
            .where((entry) {
              final growData = entry.value as Map<String, dynamic>;
              return growData['user_id'] == userId;
            })
            .map((entry) {
              final growData = entry.value as Map<String, dynamic>;
              return Grow.fromJson({...growData, 'grow_id': entry.key});
            })
            .toList();
      } else {
        throw Exception("Unexpected JSON format");
      }
    } else {
      throw Exception('Failed to load grow records');
    }
  }

  // Add a new grow record
  Future<bool> addGrow(Grow grow) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addGrow),
        headers: {"Content-Type": "application/json"},
        body: json.encode(grow.toJson()),
      );
      
      if (response.statusCode == 201) {
        return true; // Created successfully
      } else if (response.statusCode == 409) {
        // Conflict: Device already assigned
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  // Delete a grow record
  Future<Map<String, dynamic>> deleteGrow(String growId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.deleteGrow}$growId/'),
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 200) {
        return {"success": true, "statusCode": response.statusCode};
      } else {
        // Try to parse the error message from the response
        String errorMessage = "Failed to delete grow";
        try {
          Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": errorMessage
        };
      }
    } catch (e) {
      return {
        "success": false,
        "statusCode": 500,
        "message": "Exception: ${e.toString()}"
      };
    }
  }
  
  // Get harvest logs for a device
  Future<List<dynamic>> getHarvestLogs(String deviceId, [String? growId]) async {
    try {
      String url = '${ApiEndpoints.harvestLogs}$deviceId/';
      if (growId != null && growId.isNotEmpty) {
        url += '?grow_id=$growId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['logs'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  // Add a harvest log
  Future<Map<String, dynamic>> addHarvestLog(String deviceId, Map<String, dynamic> logData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.addHarvestLog}$deviceId/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(logData),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to add harvest log'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<plant.PlantProfile>> getPlantProfiles({String? userId}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.getPlantProfiles}${userId != null ? '?user_id=$userId' : ''}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> profilesMap = data['plant_profiles'] ?? {};
        return profilesMap.entries.map((entry) => 
          plant.PlantProfile.fromJson(entry.key, entry.value)
        ).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching plant profiles: $e");
      return [];
    }
  }

  Future<plant.PlantProfile?> getPlantProfile(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.getPlantProfiles}$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Handle both response formats
        if (data.containsKey('plant_profile')) {
          // This is the format {"plant_profile": {...}}
          return plant.PlantProfile.fromJson(id, data);
        } else {
          // This might be the format returned from a list endpoint
          return plant.PlantProfile.fromJson(id, data['plant_profile'] ?? data);
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> addPlantProfile(plant.PlantProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.getPlantProfiles),
        headers: await _getHeaders(),
        body: jsonEncode(profile.toJson()),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error adding plant profile: $e");
      return false;
    }
  }

  Future<bool> updatePlantProfile(String identifier, Map<String, dynamic> updateData, {String? userId}) async {
    try {
      final queryParams = userId != null ? '?user_id=$userId' : '';
      final response = await http.patch(
        Uri.parse('${ApiEndpoints.getPlantProfiles}$identifier/$queryParams'),
        headers: await _getHeaders(),
        body: jsonEncode(updateData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error updating plant profile: $e");
      return false;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
    };
  }
  
  /// Predict tipburn based on environmental conditions
  Future<Map<String, dynamic>?> predictTipburn({
    required String cropType,
    required double temperature,
    required double humidity,
    required double ec,
    required double ph,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.predictTipburn),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "temperature": temperature,
          "humidity": humidity,
          "ec": ec,
          "ph": ph,
          "crop_type": cropType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e("Tipburn prediction error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      logger.e("Error in tipburn prediction API call: $e");
      return null;
    }
  }
  
  /// Predict leaf color index based on growth conditions
  Future<double?> predictColorIndex({
    required double ec,
    required double ph,
    required int growthDays,
    required double temperature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.predictColorIndex),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ec': ec,
          'ph': ph,
          'growth_days': growthDays,
          'temperature': temperature,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['leaf_color_index'] as double;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Predict leaf count based on growth conditions
  Future<int?> predictLeafCount({
    required String cropType,
    required int growthDays,
    required double temperature,
    required double ph,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.predictLeafCount),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'crop_type': cropType,
          'growth_days': growthDays,
          'temperature': temperature,
          'ph': ph,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['leaf_count'] as int;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>?> predictCropSuggestion({
    required double temperature,
    required double humidity,
    required double ph,
    required double ec,
    required double tds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.predictCropSuggestion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temperature': temperature,
          'humidity': humidity,
          'ph': ph,
          'ec': ec,
          'tds': tds,
        }),
      );  

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'suggested_crop': data['suggested_crop'] as String,
          'recommendation': data['recommendation'] as String,
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> predictEnvironmentRecommendation({
    required String cropType,
    required String growthStage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.predictEnvironmentRecommendation),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'crop_type': cropType,
          'growth_stage': growthStage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final envData = data['recommended_environment'];
        
        return {
          'temperature': envData['temperature'],
          'humidity': envData['humidity'],
          'ec': envData['ec'],
          'ph': envData['ph'],
          'recommendation': data['recommendation']
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  // Helper method to parse active grows from response
  List<Map<String, dynamic>> _parseActiveGrows(String responseBody) {
    try {
      final Map<String, dynamic> data = json.decode(responseBody);
      final List<dynamic> grows = data['active_grows'] ?? [];
      return grows.map<Map<String, dynamic>>((grow) => {
        'grow_id': grow['grow_id'] ?? '',
        'grow_name': grow['grow_name'] ?? 'Unnamed Grow'
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Register FCM token
  Future<bool> registerFcmToken(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.fcmToken),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
        }),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Unregister FCM token
  Future<bool> unregisterFcmToken(String userId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.fcmToken),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendTestNotification(String deviceId, String title, String message, String alertType) async {
    try {
      // Get the user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        return false;
      }
      
      // Instead of directly calling FCM API, use your backend API to trigger an alert
      // This will use the FcmTokenView in your Django backend
      final response = await http.post(
        Uri.parse(ApiEndpoints.triggerAlert),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'device_id': deviceId,
          'message': message,
          'alert_type': alertType
        }),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Send a high-priority alert notification through your backend
  Future<bool> sendHighPriorityTestAlert(String userId, String deviceId) async {
    try {
      // Create a high-priority alert payload
      final payload = {
        'user_id': userId,
        'device_id': deviceId,
        'message': '🚨 CRITICAL ALERT: Testing high-priority notification',
        'alert_type': 'critical',
        'priority': 'high',  // Explicitly request high priority
        'is_test': true      // Flag to indicate this is a test notification
      };
      
      // Send through your backend API
      final response = await http.post(
        Uri.parse(ApiEndpoints.triggerAlert),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Get a device by ID
  Future<DeviceModel?> getDeviceById(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.getDevices}?device_id=$deviceId'),
        headers: {'Content-Type': 'application/json'}
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['devices'] != null && data['devices'] is Map<String, dynamic>) {
          final devicesMap = data['devices'] as Map<String, dynamic>;
          
          // Look for the device with matching ID
          if (devicesMap.containsKey(deviceId)) {
            return DeviceModel.fromJson(deviceId, devicesMap[deviceId]);
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get historical sensor data for a device
  Future<Map<String, List<Map<String, dynamic>>>> getHistoricalSensorData(
    String deviceId, 
    DateTime startDate, 
    DateTime endDate,
    String sensorType
  ) async {
    try {
      final formattedStartDate = startDate.toIso8601String();
      final formattedEndDate = endDate.toIso8601String();
      
      final url = Uri.parse(
        '${ApiEndpoints.sensorData}$deviceId/?start_date=$formattedStartDate&end_date=$formattedEndDate&sensor_type=$sensorType'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract sensor readings
        if (data['sensor_data'] != null && data['sensor_data'] is Map) {
          final sensorData = data['sensor_data'] as Map<String, dynamic>;
          
          // Convert the data to a format suitable for charts
          final result = <String, List<Map<String, dynamic>>>{};
          
          // Process each sensor type
          if (sensorType == 'all') {
            // Process all sensor types
            final Map<String, List<Map<String, dynamic>>> typedData = {};
            
            // Initialize lists for each sensor type
            typedData['temperature'] = [];
            typedData['ph'] = [];
            typedData['ec'] = [];
            typedData['tds'] = [];
            
            // For each data point
            sensorData.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                final timestamp = value['timestamp'];
                
                if (timestamp != null) {
                  final DateTime recordTime = DateTime.parse(timestamp);
                  
                  // Add data points for each sensor type if they exist
                  if (value['temperature'] != null) {
                    typedData['temperature']!.add({
                      'timestamp': recordTime.millisecondsSinceEpoch,
                      'value': (value['temperature'] as num).toDouble(),
                    });
                  }
                  
                  if (value['ph'] != null) {
                    typedData['ph']!.add({
                      'timestamp': recordTime.millisecondsSinceEpoch,
                      'value': (value['ph'] as num).toDouble(),
                    });
                  }
                  
                  if (value['ec'] != null) {
                    typedData['ec']!.add({
                      'timestamp': recordTime.millisecondsSinceEpoch,
                      'value': (value['ec'] as num).toDouble(),
                    });
                  }
                  
                  if (value['tds'] != null) {
                    typedData['tds']!.add({
                      'timestamp': recordTime.millisecondsSinceEpoch,
                      'value': (value['tds'] as num).toDouble(),
                    });
                  }
                }
              }
            });
            
            // Sort each list by timestamp
            typedData.forEach((type, dataPoints) {
              dataPoints.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
            });
            
            return typedData;
          } else {
            // Process only the requested sensor type
            result[sensorType] = [];
            
            sensorData.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                final timestamp = value['timestamp'];
                final sensorValue = value[sensorType];
                
                if (timestamp != null && sensorValue != null) {
                  final DateTime recordTime = DateTime.parse(timestamp);
                  
                  result[sensorType]!.add({
                    'timestamp': recordTime.millisecondsSinceEpoch,
                    'value': (sensorValue as num).toDouble(),
                  });
                }
              }
            });
            
            // Sort by timestamp
            result[sensorType]!.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
            
            return result;
          }
        }
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  // Update user password
  Future<bool> changePassword(String uid, String currentPassword, String newPassword) async {
    try {
      final uri = Uri.parse(ApiEndpoints.reset); // Using reset password endpoint
      
      // Get the email from the user's uid
      final email = await _getUserEmail(uid);
      if (email == null || email.isEmpty) {
        logger.e("Error: Cannot change password - no email found for user");
        return false;
      }
      
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": currentPassword,
          "new_password": newPassword
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        logger.e("Password change error: ${response.body}");
        return false;
      }
    } catch (e) {
      logger.e("Error changing password: $e");
      return false;
    }
  }
  
  // Helper method to get user email
  Future<String?> _getUserEmail(String uid) async {
    try {
      // Try to get user profile which contains the email
      final userProfile = await getUserProfile(uid);
      if (userProfile != null && userProfile['email'] != null) {
        return userProfile['email'];
      }
      
      // If we couldn't get it from the profile, return null
      return null;
    } catch (e) {
      logger.e("Error getting user email: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> checkHarvestReadiness(String growId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.harvestReadiness}$growId/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'error': 'Failed to check harvest readiness',
          'statusCode': response.statusCode,
          'message': response.body
        };
      }
    } catch (e) {
      return {
        'error': 'Exception occurred',
        'message': e.toString()
      };
    }
  }

  // Get notification preferences for a user
  Future<Map<String, dynamic>?> getNotificationPreferences(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.notificationPreferences}$userId/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['preferences'];
      } else {
        logger.e('Failed to get notification preferences: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting notification preferences: $e');
      return null;
    }
  }
  
  // Update notification preferences for a user
  Future<bool> updateNotificationPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiEndpoints.updateNotificationPreferences),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'preferences': preferences,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      logger.e('Error updating notification preferences: $e');
      return false;
    }
  }

  Future<bool> sendFeedback(Map<String, dynamic> feedbackData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.feedback),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedbackData),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        // Parse the error message from the response if available
        Map<String, dynamic> errorData = {};
        try {
          errorData = json.decode(response.body);
          logger.e("Feedback submission error: ${errorData['error'] ?? 'Unknown error'}");
        } catch (e) {
          logger.e("Failed to submit feedback: ${response.statusCode}");
        }
        return false;
      }
      
      return true;
    } catch (e) {
      logger.e("Error submitting feedback: $e");
      return false;
    }
  }

 Future<Uint8List?> generateReport({
    required String userId,
    required String deviceId,
 
  }) async {
    try {
      final url = Uri.parse(ApiEndpoints.generateReport);

      final body = jsonEncode({
        'user_id': userId,
        'device_id': deviceId,
       
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 406) {
        print('Client must accept application/pdf');
        return null;
      } else {
        print('Failed to generate PDF: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error generating report: $e');
      return null;
    }
  }

  /// Update individual actuator status and duration
  Future<bool> updateDeviceActuator(String deviceId, String actuatorId, int duration) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.updateDevice}$deviceId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'actuator_flush': {
            'actuator_id': actuatorId,
            'duration': duration,
          }
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      logger.e("Error updating actuator: $e");
      return false;
    }
  }

  /// Update system flush status and duration
  Future<bool> updateDeviceFlush(String deviceId, int duration, String type) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.updateDevice}$deviceId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'actuator_flush': {
            'actuator_id': 'flush',
            'duration': duration,
            'type': type,
          }
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      logger.e("Error updating system flush: $e");
      return false;
    }
  }

  /// Check if a device is registered and available
  Future<Map<String, dynamic>?> checkRegisteredDevice(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.registeredDevices}$deviceId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      logger.e("Error checking registered device: $e");
      return null;
    }
  }

  /// Get current environmental thresholds based on grow stage
  Future<Map<String, dynamic>?> getCurrentThresholds(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.getCurrentThresholds.replaceAll('<str:device_id>', deviceId)),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.e('Failed to get current thresholds: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting current thresholds: $e');
      return null;
    }
  }

  /// Gets a grow by ID
  Future<Grow?> getGrow(String growId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.getGrows}$growId/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Grow.fromJson(data);
      }
      return null;
    } catch (e) {
      logger.e('Error getting grow: $e');
      return null;
    }
  }

  /// Gets a grow profile by ID
  Future<GrowProfile?> getGrowProfile(String profileId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.getGrowProfiles}$profileId/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GrowProfile.fromMap(profileId, data);
      }
      return null;
    } catch (e) {
      logger.e('Error getting grow profile: $e');
      return null;
    }
  }
}
