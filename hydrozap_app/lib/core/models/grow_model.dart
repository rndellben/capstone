import 'package:hive/hive.dart';

part 'grow_model.g.dart';

@HiveType(typeId: 7)
class Grow {
  @HiveField(0)
  final String? growId;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String deviceId;
  
  @HiveField(3)
  final String profileId;
  
  @HiveField(4)
  final String startDate;
  
  @HiveField(5)
  final bool synced;
  
  @HiveField(6)
  final DateTime lastUpdated;
  
  @HiveField(7)
  final String status;
  
  @HiveField(8)
  final String? harvestDate;

  Grow({
    String? growId,
    required this.userId,
    required this.deviceId,
    required this.profileId,
    required this.startDate,
    this.synced = true,
    DateTime? lastUpdated,
    this.status = 'active',
    this.harvestDate,
  }) : growId = growId ?? DateTime.now().millisecondsSinceEpoch.toString(),
       lastUpdated = lastUpdated ?? DateTime.now();

  // ✅ Convert Grow object to JSON
  Map<String, dynamic> toJson() {
    return {
      "grow_id": growId,
      "user_id": userId,
      "device_id": deviceId,
      "profile_id": profileId,
      "start_date": startDate,
      "status": status,
      "harvest_date": harvestDate,
      "last_updated": lastUpdated.toIso8601String(),
    };
  }

  // ✅ Create Grow object from JSON
  factory Grow.fromJson(Map<String, dynamic> json) {
    return Grow(
      growId: json['grow_id']?.toString() ?? '', // Ensure it's a String, default to empty
      userId: json['user_id'] ?? '',  // Default empty string if null
      deviceId: json['device_id'] ?? '',
      profileId: json['profile_id'] ?? '', // Add a check if profile_id can be null
      startDate: json['start_date'] ?? '',
      status: json['status'] ?? 'active',
      harvestDate: json['harvest_date'],
      synced: true,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
    );
  }
  
  // Copy with method
  Grow copyWith({
    String? growId,
    String? userId,
    String? deviceId,
    String? profileId,
    String? startDate,
    bool? synced,
    DateTime? lastUpdated,
    String? status,
    String? harvestDate,
  }) {
    return Grow(
      growId: growId ?? this.growId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      profileId: profileId ?? this.profileId,
      startDate: startDate ?? this.startDate,
      synced: synced ?? this.synced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      harvestDate: harvestDate ?? this.harvestDate,
    );
  }
}
