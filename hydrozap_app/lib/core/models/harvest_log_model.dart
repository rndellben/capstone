// lib/core/models/harvest_log_model.dart
import 'package:hive/hive.dart';

part 'harvest_log_model.g.dart';

@HiveType(typeId: 8)
class HarvestLog {
  @HiveField(0)
  final String logId;
  
  @HiveField(1)
  final String deviceId;
  
  @HiveField(2)
  final String growId;
  
  @HiveField(3)
  final String cropName;
  
  @HiveField(4)
  final String harvestDate;
  
  @HiveField(5)
  final double yieldAmount;
  
  @HiveField(6)
  final int rating;
  
  @HiveField(7)
  final Map<String, double> performanceMetrics;
  
  @HiveField(8)
  final bool synced;
  
  @HiveField(9)
  final DateTime lastUpdated;

  HarvestLog({
    required this.logId,
    required this.deviceId,
    required this.growId,
    required this.cropName,
    required this.harvestDate,
    required this.yieldAmount,
    required this.rating,
    this.performanceMetrics = const {},
    this.synced = true,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'deviceId': deviceId,
      'growId': growId,
      'cropName': cropName,
      'harvestDate': harvestDate,
      'yieldAmount': yieldAmount,
      'rating': rating,
      'performanceMetrics': performanceMetrics,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory HarvestLog.fromJson(Map<String, dynamic> json) {
    return HarvestLog(
      logId: json['logId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      growId: json['growId'] ?? '',
      cropName: json['cropName'] ?? '',
      harvestDate: json['harvestDate'] ?? '',
      yieldAmount: (json['yieldAmount'] ?? 0.0).toDouble(),
      rating: json['rating'] ?? 3,
      performanceMetrics: Map<String, double>.from(json['performanceMetrics'] ?? {}),
      synced: true,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
    );
  }

  HarvestLog copyWith({
    String? logId,
    String? deviceId,
    String? growId,
    String? cropName,
    String? harvestDate,
    double? yieldAmount,
    int? rating,
    Map<String, double>? performanceMetrics,
    bool? synced,
    DateTime? lastUpdated,
  }) {
    return HarvestLog(
      logId: logId ?? this.logId,
      deviceId: deviceId ?? this.deviceId,
      growId: growId ?? this.growId,
      cropName: cropName ?? this.cropName,
      harvestDate: harvestDate ?? this.harvestDate,
      yieldAmount: yieldAmount ?? this.yieldAmount,
      rating: rating ?? this.rating,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      synced: synced ?? this.synced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}