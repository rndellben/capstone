import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Service to manage device configuration settings
class DeviceConfigService {
  static final DeviceConfigService _instance = DeviceConfigService._internal();
  factory DeviceConfigService() => _instance;
  DeviceConfigService._internal();

  // SharedPreferences keys
  static const String _espIpAddressKey = 'esp_ip_address';
  static const String _defaultEspIpAddress = '192.168.1.100';

  /// Get the ESP8266 IP address
  /// 
  /// Returns the stored IP address or a default value
  Future<String> getEspIpAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_espIpAddressKey) ?? _defaultEspIpAddress;
    } catch (e) {
      logger.e('Error getting ESP IP address: $e');
      return _defaultEspIpAddress;
    }
  }

  /// Set the ESP8266 IP address
  /// 
  /// [ipAddress] - The IP address to store
  Future<bool> setEspIpAddress(String ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_espIpAddressKey, ipAddress);
      if (success) {
        logger.i('ESP IP address saved: $ipAddress');
      }
      return success;
    } catch (e) {
      logger.e('Error setting ESP IP address: $e');
      return false;
    }
  }

  /// Validate IP address format
  /// 
  /// [ipAddress] - The IP address to validate
  /// Returns true if the IP address format is valid
  bool isValidIpAddress(String ipAddress) {
    // Simple IP address validation
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    return ipRegex.hasMatch(ipAddress);
  }

  /// Get default ESP8266 IP address
  String getDefaultEspIpAddress() {
    return _defaultEspIpAddress;
  }
} 