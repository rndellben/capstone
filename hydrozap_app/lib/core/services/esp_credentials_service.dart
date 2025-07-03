import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import 'device_config_service.dart';

/// Service to send Firebase credentials to ESP8266 devices
class EspCredentialsService {
  static final EspCredentialsService _instance = EspCredentialsService._internal();
  factory EspCredentialsService() => _instance;
  EspCredentialsService._internal();

  final DeviceConfigService _deviceConfigService = DeviceConfigService();

  /// Send Firebase credentials to ESP8266 device
  /// 
  /// [deviceIp] - The IP address of the ESP8266 device (optional, will use stored config if not provided)
  /// [email] - The user's Firebase email
  /// [password] - The user's Firebase password (if available)
  /// 
  /// Returns true if credentials were sent successfully, false otherwise
  Future<bool> sendCredentialsToEsp({
    String? deviceIp,
    required String email,
    String? password,
  }) async {
    try {
      // Get ESP IP address from config if not provided
      final espIp = deviceIp ?? await _deviceConfigService.getEspIpAddress();
      
      // Construct the URL for the ESP8266 credentials endpoint
      final url = 'http://$espIp/credentials';
      
      // Prepare the JSON payload
      final Map<String, dynamic> payload = {
        'email': email,
        'password': password ?? '', // Send empty string if password is not available
      };

      logger.i('Sending credentials to ESP8266 at $url');
      
      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(
        const Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          logger.e('Timeout sending credentials to ESP8266');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        logger.i('Credentials sent successfully to ESP8266');
        return true;
      } else {
        logger.e('Failed to send credentials to ESP8266. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e('Error sending credentials to ESP8266: $e');
      return false;
    }
  }

  /// Get current user's Firebase credentials
  /// 
  /// Returns a map with email and password (if available)
  /// Note: Firebase Auth doesn't store passwords for security reasons,
  /// so the password will typically be null for Firebase users
  Future<Map<String, String?>> getCurrentUserCredentials() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        logger.w('No current user found');
        return {'email': null, 'password': null};
      }

      final email = user.email;
      
      // Note: Firebase Auth doesn't provide access to the user's password
      // for security reasons. The password will be null for Firebase users.
      // For ESP8266 authentication, you might need to use a different approach
      // such as using Firebase ID tokens or custom tokens.
      
      logger.i('Retrieved credentials for user: ${email ?? 'unknown'}');
      
      return {
        'email': email,
        'password': null, // Firebase Auth doesn't provide password access
      };
    } catch (e) {
      logger.e('Error getting current user credentials: $e');
      return {'email': null, 'password': null};
    }
  }

  /// Send Firebase ID token to ESP8266 (alternative to email/password)
  /// 
  /// This method sends the Firebase ID token which can be used for authentication
  /// instead of email/password combination
  Future<bool> sendFirebaseTokenToEsp({
    String? deviceIp,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        logger.w('No current user found for token generation');
        return false;
      }

      // Get the Firebase ID token
      final idToken = await user.getIdToken();
      
      if (idToken == null) {
        logger.e('Failed to get Firebase ID token');
        return false;
      }

      // Get ESP IP address from config if not provided
      final espIp = deviceIp ?? await _deviceConfigService.getEspIpAddress();

      // Construct the URL for the ESP8266 token endpoint
      final url = 'http://$espIp/firebase_token';
      
      // Prepare the JSON payload
      final Map<String, dynamic> payload = {
        'token': idToken,
        'email': user.email ?? '',
      };

      logger.i('Sending Firebase token to ESP8266 at $url');
      
      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.e('Timeout sending Firebase token to ESP8266');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        logger.i('Firebase token sent successfully to ESP8266');
        return true;
      } else {
        logger.e('Failed to send Firebase token to ESP8266. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e('Error sending Firebase token to ESP8266: $e');
      return false;
    }
  }
} 