import 'package:hive/hive.dart';

part 'device_model.g.dart';

@HiveType(typeId: 1)
class DeviceModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String deviceName;
  
  @HiveField(2)
  final String type;
  
  @HiveField(3)
  final String kit;
  
  @HiveField(4)
  final bool emergencyStop;
  
  @HiveField(5)
  final String status;
  
  @HiveField(6)
  final Map<String, Map<String, dynamic>> sensors;
  
  @HiveField(7)
  final Map<String, dynamic> actuators;
  
  @HiveField(8)
  final String userId;
  
  @HiveField(9)
  final String? plantProfile;
  
  @HiveField(10)
  final List<Map<String, dynamic>>? actuatorConditions;
  
  @HiveField(11)
  final bool synced;
  
  @HiveField(12)
  final DateTime lastUpdated;
  
  @HiveField(13)
  final double waterVolumeInLiters;
  
  @HiveField(14)
  final String? activeGrowId;
  
  @HiveField(15)
  final Map<String, dynamic>? thresholds;

  @HiveField(16)
  final bool autoDoseEnabled;

  DeviceModel({
    required this.id,
    required this.deviceName,
    required this.type,
    required this.kit,
    required this.emergencyStop,
    required this.status,
    required this.sensors,
    required this.actuators,
    required this.userId,
    this.plantProfile,
    this.actuatorConditions,
    this.synced = true,
    this.waterVolumeInLiters = 0.0,
    DateTime? lastUpdated,
    this.activeGrowId,
    this.thresholds,
    this.autoDoseEnabled = false,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // ✅ Convert Device object to JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': id,
      'device_name': deviceName,
      'type': type,
      'kit': kit,
      'emergency_stop': emergencyStop,
      'status': status,
      'sensors': sensors,
      'actuators': actuators,
      'user_id': userId,
      'plant_profile': plantProfile,
      'actuator_conditions': actuatorConditions,
      'water_volume_liters': waterVolumeInLiters,
      'last_updated': lastUpdated.toIso8601String(),
      'active_grow_id': activeGrowId,
      'thresholds': thresholds,
      'auto_dose_enabled': autoDoseEnabled,
    };
  }

  // ✅ Create factory constructor for JSON to Device object
  factory DeviceModel.fromJson(String id, Map<String, dynamic> json) {
    // Properly cast actuator_conditions to List<Map<String, dynamic>>
    List<Map<String, dynamic>>? actuatorConditions;
    if (json['actuator_conditions'] != null) {
      actuatorConditions = (json['actuator_conditions'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Properly cast sensors to Map<String, Map<String, dynamic>>
    Map<String, Map<String, dynamic>> sensors = {};
    if (json['sensors'] != null) {
      final sensorsData = json['sensors'] as Map<String, dynamic>;
      sensorsData.forEach((key, value) {
        if (value is Map) {
          sensors[key] = Map<String, dynamic>.from(value);
        }
      });
    }

    return DeviceModel(
      id: id,
      deviceName: json['device_name'] ?? '',
      type: json['type'] ?? '',
      kit: json['kit'] ?? '',
      emergencyStop: json['emergency_stop'] ?? false,
      status: json['status'] ?? 'off',
      sensors: sensors,
      actuators: json['actuators'] ?? {},
      userId: json['user_id'] ?? '',
      plantProfile: json['plant_profile'] ?? '',
      actuatorConditions: actuatorConditions,
      waterVolumeInLiters: (json['water_volume_liters'] as num?)?.toDouble() ?? 0.0,
      synced: true,
      lastUpdated: json['last_updated'] != null 
        ? DateTime.parse(json['last_updated']) 
        : DateTime.now(),
      activeGrowId: json['active_grow_id'] ?? '',
      thresholds: json['thresholds'] as Map<String, dynamic>?,
      autoDoseEnabled: json['auto_dose_enabled'] ?? false,
    );
  }
  
  // Copy with method for updating fields
  DeviceModel copyWith({
    String? id,
    String? deviceName,
    String? type,
    String? kit,
    bool? emergencyStop,
    String? status,
    Map<String, Map<String, dynamic>>? sensors,
    Map<String, dynamic>? actuators,
    String? userId,
    String? plantProfile,
    List<Map<String, dynamic>>? actuatorConditions,
    bool? synced,
    DateTime? lastUpdated,
    double? waterVolumeInLiters,
    String? activeGrowId,
    Map<String, dynamic>? thresholds,
    bool? autoDoseEnabled,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      type: type ?? this.type,
      kit: kit ?? this.kit,
      emergencyStop: emergencyStop ?? this.emergencyStop,
      status: status ?? this.status,
      sensors: sensors ?? this.sensors,
      actuators: actuators ?? this.actuators,
      userId: userId ?? this.userId,
      plantProfile: plantProfile ?? this.plantProfile,
      actuatorConditions: actuatorConditions ?? this.actuatorConditions,
      synced: synced ?? this.synced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      waterVolumeInLiters: waterVolumeInLiters ?? this.waterVolumeInLiters,
      activeGrowId: activeGrowId ?? this.activeGrowId,
      thresholds: thresholds ?? this.thresholds,
      autoDoseEnabled: autoDoseEnabled ?? this.autoDoseEnabled,
    );
  }
  
  // Helper method to get the most recent sensor reading for a specific sensor type
  Map<String, dynamic>? getLatestSensorReading(String sensorType) {
    try {
      // Check if sensor type exists
    if (!sensors.containsKey(sensorType) || sensors[sensorType]!.isEmpty) {
      return null;
    }
    
      final sensorData = sensors[sensorType]!;
      
      // Case 1: If there's only one entry with key 'value', this is legacy format
      if (sensorData.length == 1 && sensorData.containsKey('value')) {
        return sensorData;
      }
      
      // Case 2: If sensor data is a flat map with no nested structures, just return it
      bool hasNestedMaps = false;
      for (var value in sensorData.values) {
        if (value is Map) {
          hasNestedMaps = true;
          break;
        }
      }
      
      if (!hasNestedMaps) {
        return sensorData;
      }
      
      // Case 3: Structured format with timestamps
    String? latestTimestampKey;
    DateTime? latestDateTime;
    
      // First pass: look for entries with timestamps
      sensorData.forEach((key, reading) {
        if (reading is Map && reading['timestamp'] != null) {
          try {
            final timestamp = DateTime.parse(reading['timestamp'].toString());
            if (latestDateTime == null || timestamp.isAfter(latestDateTime!)) {
              latestDateTime = timestamp;
              latestTimestampKey = key;
            }
          } catch (e) {
            // Skip this entry on timestamp parsing error
          }
        }
      });
      
      // If we found a reading with a timestamp, return it
      if (latestTimestampKey != null) {
        return Map<String, dynamic>.from(sensorData[latestTimestampKey!] as Map);
      }
      
      // Case 4: Look for the first Map value as fallback
      for (var entry in sensorData.entries) {
        if (entry.value is Map) {
          return Map<String, dynamic>.from(entry.value as Map);
        }
      }
      
      // Case 5: Just return the whole sensor data as is
      return Map<String, dynamic>.from(sensorData);
    } catch (e) {
      return null;
    }
  }
  
  // Helper method to get a specific sensor value with fallback
  double getSensorValue(String sensorType, String valueName, {double defaultValue = 0.0}) {
    try {
      // The structure is different - sensors is a map with random keys
      // Each key contains a map with all sensor values
      if (sensors.isEmpty) {
        return defaultValue;
      }

      // Find the latest sensor reading based on timestamp
      Map<String, dynamic>? latestReading;
      DateTime? latestTimestamp;

      // Check all entries in the sensors map to find the one with the latest timestamp
      for (var entry in sensors.entries) {
        final sensorData = entry.value;
        
        // Check if this entry has a timestamp
        if (sensorData.containsKey('timestamp')) {
          try {
            final timestamp = DateTime.parse(sensorData['timestamp'].toString());
            // If this is the first entry or it's newer than our current latest
            if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
              latestTimestamp = timestamp;
              latestReading = sensorData;
            }
          } catch (e) {
            // Skip this entry on timestamp parsing error
          }
        }
      }

      // If we found a reading with a timestamp, use it
      if (latestReading != null) {
        if (latestReading.containsKey(sensorType)) {
          var value = latestReading[sensorType];
          if (value is num) {
            return value.toDouble();
          } else if (value is String) {
            try {
              return double.parse(value);
            } catch (e) {
              // Could not parse string to double
            }
          }
        }
      } else {
        // Fallback: Check all entries for the sensor type (no timestamp ordering)
        for (var entry in sensors.entries) {
          final sensorData = entry.value;
          if (sensorData.containsKey(sensorType)) {
            var value = sensorData[sensorType];
            if (value is num) {
              return value.toDouble();
            } else if (value is String) {
              try {
                return double.parse(value);
              } catch (e) {
                // Could not parse string to double
              }
            }
          }
        }
      }

      // If we get here, we didn't find the sensor type
      return defaultValue;
    } catch (e) {
    return defaultValue;
    }
  }
  
  // Helper method to get a string sensor value with fallback
  String getSensorStringValue(String sensorType, String valueName, {String defaultValue = 'Unknown'}) {
    try {
      // The structure is different - sensors is a map with random keys
      // Each key contains a map with all sensor values
      if (sensors.isEmpty) {
        return defaultValue;
      }

      // Find the latest sensor reading based on timestamp
      Map<String, dynamic>? latestReading;
      DateTime? latestTimestamp;

      // Check all entries in the sensors map to find the one with the latest timestamp
      for (var entry in sensors.entries) {
        final sensorData = entry.value;
        
        // Check if this entry has a timestamp
        if (sensorData.containsKey('timestamp')) {
          try {
            final timestamp = DateTime.parse(sensorData['timestamp'].toString());
            // If this is the first entry or it's newer than our current latest
            if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
              latestTimestamp = timestamp;
              latestReading = sensorData;
            }
          } catch (e) {
            // Skip this entry on timestamp parsing error
          }
        }
      }

      // If we found a reading with a timestamp, use it
      if (latestReading != null) {
        if (latestReading.containsKey(sensorType)) {
          var value = latestReading[sensorType];
          if (value != null) {
            return value.toString();
          }
        }
      } else {
        // Fallback: Check all entries for the sensor type (no timestamp ordering)
        for (var entry in sensors.entries) {
          final sensorData = entry.value;
          if (sensorData.containsKey(sensorType)) {
            var value = sensorData[sensorType];
            if (value != null) {
              return value.toString();
            }
          }
        }
      }

      // If we get here, we didn't find the sensor type
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // Get all latest sensor readings at once for better performance
  Map<String, dynamic> getLatestSensorReadings() {
    final result = <String, dynamic>{};
    
    try {
      // Find the entry with the most recent timestamp
      Map<String, dynamic>? latestReading;
      DateTime? latestTimestamp;
      
      // Check all entries for timestamps
      for (var entry in sensors.entries) {
        if (entry.value.containsKey('timestamp')) {
          try {
            final timestamp = DateTime.parse(entry.value['timestamp'].toString());
            if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
              latestTimestamp = timestamp;
              latestReading = entry.value;
            }
          } catch (e) {
            // Skip this entry on timestamp parsing error
          }
        }
      }
      
      // If we found a timestamped reading, use it
      if (latestReading != null) {
        // Copy all sensor values except timestamp
        for (var entry in latestReading.entries) {
          if (entry.key != 'timestamp') {
            result[entry.key] = entry.value;
          }
        }
        // Add timestamp as a DateTime object
        if (latestTimestamp != null) {
          result['_timestamp'] = latestTimestamp;
        }
      } else {
        // Fallback: Check each sensor type individually
        final sensorTypes = ['temperature', 'ph', 'ec', 'tds', 'waterLevel', 'humidity', 'ambientTemperature'];
        for (var sensorType in sensorTypes) {
          for (var entry in sensors.entries) {
            if (entry.value.containsKey(sensorType)) {
              result[sensorType] = entry.value[sensorType];
              break;
            }
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
    
    return result;
  }
  
  // Debug method to print sensor data
  void debugPrintSensors() {
    print('----------- DEVICE SENSORS DEBUG -----------');
    print('Device: $deviceName (ID: $id)');
    
    if (sensors.isEmpty) {
      print('No sensor data available');
      print('------------------------------------------');
      return;
    }
    
    // Print sensor data structure
    print('Sensor data structure: ${sensors.length} entries');
    
    // Print latest readings
    final latestReadings = getLatestSensorReadings();
    print('Latest readings:');
    latestReadings.forEach((key, value) {
      if (key != '_timestamp') {
        print('  $key: $value');
      }
    });
    
    if (latestReadings.containsKey('_timestamp')) {
      print('Timestamp: ${latestReadings['_timestamp']}');
    }
    
    print('------------------------------------------');
  }
}
