import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Service to automatically discover ESP8266 devices on the local network
class NetworkDiscoveryService {
  static final NetworkDiscoveryService _instance = NetworkDiscoveryService._internal();
  factory NetworkDiscoveryService() => _instance;
  NetworkDiscoveryService._internal();

  /// Discover ESP8266 devices on the local network
  Future<List<DiscoveredDevice>> discoverEspDevices() async {
    final List<DiscoveredDevice> discoveredDevices = [];
    
    try {
      logger.i('Starting ESP8266 device discovery...');
      
      // Get local network information
      final localIp = await _getLocalIpAddress();
      if (localIp == null) {
        logger.e('Could not determine local IP address');
        return discoveredDevices;
      }

      final networkPrefix = _getNetworkPrefix(localIp);
      logger.i('Scanning network: $networkPrefix');

      // Quick scan of common IP addresses
      final commonIps = [
        '192.168.1.100',
        '192.168.1.101',
        '192.168.1.102',
        '192.168.1.200',
        '192.168.1.201',
        '192.168.4.1', // ESP8266 AP mode default
      ];

      final futures = <Future<void>>[];
      
      for (final ip in commonIps) {
        futures.add(_scanIpAddress(ip, discoveredDevices));
      }

      await Future.wait(futures).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.w('Network discovery timed out');
          return <void>[];
        },
      );

      logger.i('Discovery completed. Found ${discoveredDevices.length} ESP8266 devices');
      return discoveredDevices;
    } catch (e) {
      logger.e('Error during network discovery: $e');
      return discoveredDevices;
    }
  }

  /// Get the local device's IP address
  Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      
      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('loopback') ||
            interface.addresses.isEmpty) {
          continue;
        }

        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            final ip = address.address;
            if (_isLocalNetwork(ip)) {
              logger.i('Found local IP: $ip');
              return ip;
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      logger.e('Error getting local IP address: $e');
      return null;
    }
  }

  /// Check if an IP address is in a local network range
  bool _isLocalNetwork(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    final firstOctet = int.tryParse(parts[0]);
    if (firstOctet == null) return false;
    
    return firstOctet == 10 || 
           (firstOctet == 172 && int.parse(parts[1]) >= 16 && int.parse(parts[1]) <= 31) ||
           (firstOctet == 192 && int.parse(parts[1]) == 168);
  }

  /// Get network prefix from local IP
  String _getNetworkPrefix(String localIp) {
    final parts = localIp.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}.';
  }

  /// Scan a specific IP address for ESP8266 devices
  Future<void> _scanIpAddress(String ipAddress, List<DiscoveredDevice> discoveredDevices) async {
    try {
      final device = await _checkEspDevice(ipAddress, 80);
      if (device != null) {
        discoveredDevices.add(device);
        logger.i('Found ESP8266 device: ${device.name} at ${device.ipAddress}');
      }
    } catch (e) {
      // Silently ignore connection errors
    }
  }

  /// Check if a specific IP hosts an ESP8266 device
  Future<DiscoveredDevice?> _checkEspDevice(String ipAddress, int port) async {
    try {
      final url = 'http://$ipAddress:$port';
      
      final response = await http.get(
        Uri.parse('$url/device_info'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final deviceName = data['name'] ?? 'ESP8266 Device';
          
          return DiscoveredDevice(
            ipAddress: ipAddress,
            port: port,
            name: deviceName,
            type: 'ESP8266',
            isEspDevice: true,
          );
        } catch (e) {
          return DiscoveredDevice(
            ipAddress: ipAddress,
            port: port,
            name: 'ESP8266 Device',
            type: 'ESP8266',
            isEspDevice: true,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Represents a discovered device on the network
class DiscoveredDevice {
  final String ipAddress;
  final int port;
  final String name;
  final String type;
  final bool isEspDevice;

  DiscoveredDevice({
    required this.ipAddress,
    required this.port,
    required this.name,
    required this.type,
    required this.isEspDevice,
  });

  String get url => 'http://$ipAddress:$port';
  String get displayName => isEspDevice ? name : '$name ($type)';

  @override
  String toString() {
    return 'DiscoveredDevice(ipAddress: $ipAddress, port: $port, name: $name, type: $type, isEspDevice: $isEspDevice)';
  }
}