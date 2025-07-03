import 'package:hive/hive.dart';
import 'package:hydrozap_app/core/utils/logger.dart';

part 'alert_model.g.dart';

@HiveType(typeId: 9)
class Alert {
  @HiveField(0)
  final String alertId;
  
  @HiveField(1)
  final String deviceId;
  
  @HiveField(2)
  final String message;
  
  @HiveField(3)
  final String alertType;
  
  @HiveField(4)
  final String status;
  
  @HiveField(5)
  final String timestamp;
  
  @HiveField(6)
  final bool synced;
  
  @HiveField(7)
  final DateTime lastUpdated;

  @HiveField(8)
  final Map<String, dynamic>? sensorData;

  @HiveField(9)
  final String? suggestedAction;

  Alert({
    required this.alertId,
    required this.deviceId,
    required this.message,
    required this.alertType,
    required this.status,
    required this.timestamp,
    this.synced = true,
    DateTime? lastUpdated,
    this.sensorData,
    this.suggestedAction,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Convert JSON to Alert object
  factory Alert.fromJson(Map<String, dynamic> json) {
    // Log the raw JSON to help with debugging
    logger.d("🔍 Alert JSON: $json");
    
    final alertId = json['alert_id'] ?? json['id'] ?? '';
    logger.d("🔍 Parsed Alert ID: $alertId");
    
    return Alert(
      alertId: alertId,
      deviceId: json['device_id'] ?? '',
      message: json['message'] ?? '',
      alertType: json['alert_type'] ?? 'sensor',
      status: json['status'] ?? 'unread',
      timestamp: json['timestamp'] ?? '',
      synced: true,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
      sensorData: json['sensor_data'] != null && json['sensor_data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['sensor_data'])
        : null,
      suggestedAction: json['suggested_action'],
    );
  }

  /// Convert Alert object to JSON
  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'device_id': deviceId,
      'message': message,
      'alert_type': alertType,
      'status': status,
      'timestamp': timestamp,
      'last_updated': lastUpdated.toIso8601String(),
      if (sensorData != null) 'sensor_data': sensorData,
      if (suggestedAction != null) 'suggested_action': suggestedAction,
    };
  }
  
  // Copy with method
  Alert copyWith({
    String? alertId,
    String? deviceId,
    String? message,
    String? alertType,
    String? status,
    String? timestamp,
    bool? synced,
    DateTime? lastUpdated,
    Map<String, dynamic>? sensorData,
    String? suggestedAction,
  }) {
    return Alert(
      alertId: alertId ?? this.alertId,
      deviceId: deviceId ?? this.deviceId,
      message: message ?? this.message,
      alertType: alertType ?? this.alertType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sensorData: sensorData ?? this.sensorData,
      suggestedAction: suggestedAction ?? this.suggestedAction,
    );
  }

  // Helper to get sensor timestamp if available
  String? get sensorTimestamp => sensorData != null && sensorData!['timestamp'] != null ? sensorData!['timestamp'] : null;
}
