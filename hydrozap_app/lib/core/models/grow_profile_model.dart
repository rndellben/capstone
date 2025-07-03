import 'package:hive/hive.dart';

part 'grow_profile_model.g.dart';

@HiveType(typeId: 2)
class GrowProfile {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String userId;
  
  @HiveField(3)
  final int growDurationDays;
  
  @HiveField(4)
  final bool isActive;
  
  @HiveField(5)
  final String plantProfileId;
  
  @HiveField(6)
  final StageConditions optimalConditions;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final bool synced;
  
  @HiveField(9)
  final DateTime lastUpdated;

  @HiveField(10)
  final String mode;

  GrowProfile({
    required this.id,
    required this.name,
    required this.userId,
    required this.growDurationDays,
    required this.isActive,
    required this.plantProfileId,
    required this.optimalConditions,
    required this.createdAt,
    this.synced = true,
    DateTime? lastUpdated,
    this.mode = 'simple',
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // ✅ Factory method to create a GrowProfile from a Map
  factory GrowProfile.fromMap(String id, Map<String, dynamic> data) {
    return GrowProfile(
      id: id,
      name: data['name'] ?? '',
      userId: data['user_id'] ?? '',
      growDurationDays: data['grow_duration_days'] ?? 0,
      isActive: data['is_active'] ?? false,
      plantProfileId: data['plant_profile_id'] ?? '',
      optimalConditions: StageConditions.fromMap(data['optimal_conditions'] ?? {}),
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      synced: true,
      lastUpdated: data['last_updated'] != null 
        ? DateTime.parse(data['last_updated']) 
        : DateTime.now(),
      mode: data['mode'] ?? 'simple',
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'grow_duration_days': growDurationDays,
      'is_active': isActive,
      'plant_profile_id': plantProfileId,
      'optimal_conditions': optimalConditions.toMap(),
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'mode': mode,
    };
  }
  
  // Copy with method for updating fields
  GrowProfile copyWith({
    String? id,
    String? name,
    String? userId,
    int? growDurationDays,
    bool? isActive,
    String? plantProfileId,
    StageConditions? optimalConditions,
    DateTime? createdAt,
    bool? synced,
    DateTime? lastUpdated,
    String? mode,
  }) {
    return GrowProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      growDurationDays: growDurationDays ?? this.growDurationDays,
      isActive: isActive ?? this.isActive,
      plantProfileId: plantProfileId ?? this.plantProfileId,
      optimalConditions: optimalConditions ?? this.optimalConditions,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      mode: mode ?? this.mode,
    );
  }
}

@HiveType(typeId: 3)
class NutrientSchedule {
  @HiveField(0)
  final Stage stage1;
  
  @HiveField(1)
  final Stage stage2;

  NutrientSchedule({required this.stage1, required this.stage2});

  factory NutrientSchedule.fromMap(Map<String, dynamic> data) {
    return NutrientSchedule(
      stage1: Stage.fromMap(data['stage_1'] ?? {}),
      stage2: Stage.fromMap(data['stage_2'] ?? {}),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'stage_1': stage1.toMap(),
      'stage_2': stage2.toMap(),
    };
  }
}

@HiveType(typeId: 4)
class Stage {
  @HiveField(0)
  final int days;
  
  @HiveField(1)
  final String nutrients;

  Stage({required this.days, required this.nutrients});

  factory Stage.fromMap(Map<String, dynamic> data) {
    return Stage(
      days: data['days'] ?? 0,
      nutrients: data['nutrients'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'nutrients': nutrients,
    };
  }
}

@HiveType(typeId: 5)
class StageConditions {
  @HiveField(0)
  final OptimalConditions transplanting;
  
  @HiveField(1)
  final OptimalConditions vegetative;
  
  @HiveField(2)
  final OptimalConditions maturation;

  StageConditions({
    required this.transplanting,
    required this.vegetative,
    required this.maturation,
  });

  factory StageConditions.fromMap(Map<String, dynamic> data) {
    return StageConditions(
      transplanting: OptimalConditions.fromMap(data['transplanting'] ?? {}),
      vegetative: OptimalConditions.fromMap(data['vegetative'] ?? {}),
      maturation: OptimalConditions.fromMap(data['maturation'] ?? {}),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'transplanting': transplanting.toMap(),
      'vegetative': vegetative.toMap(),
      'maturation': maturation.toMap(),
    };
  }
}

@HiveType(typeId: 6)
class OptimalConditions {
  @HiveField(0)
  final Range temperature;
  
  @HiveField(1)
  final Range humidity;
  
  @HiveField(2)
  final Range phRange;
  
  @HiveField(3)
  final Range ecRange;
  
  @HiveField(4)
  final Range tdsRange;

  OptimalConditions({
    required this.temperature,
    required this.humidity,
    required this.phRange,
    required this.ecRange,
    required this.tdsRange,
  });

  factory OptimalConditions.fromMap(Map<String, dynamic> data) {
    return OptimalConditions(
      temperature: Range.fromMap(data['temperature_range'] ?? {}),
      humidity: Range.fromMap(data['humidity_range'] ?? {}),
      phRange: Range.fromMap(data['ph_range'] ?? {}),
      ecRange: Range.fromMap(data['ec_range'] ?? {}),
      tdsRange: Range.fromMap(data['tds_range'] ?? {}),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'temperature_range': temperature.toMap(),
      'humidity_range': humidity.toMap(),
      'ph_range': phRange.toMap(),
      'ec_range': ecRange.toMap(),
      'tds_range': tdsRange.toMap(),
    };
  }
}

@HiveType(typeId: 11)
class Range {
  @HiveField(0)
  final double min;
  
  @HiveField(1)
  final double max;

  Range({required this.min, required this.max});

  factory Range.fromMap(Map<String, dynamic> data) {
    return Range(
      min: (data['min'] ?? 0).toDouble(),
      max: (data['max'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'min': min,
      'max': max,
    };
  }
}
