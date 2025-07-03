class OptimalConditions {
  final Map<String, Map<String, Map<String, double>>> stageConditions;

  OptimalConditions({
    required this.stageConditions,
  });

  factory OptimalConditions.fromJson(Map<String, dynamic> json) {
    final Map<String, Map<String, Map<String, double>>> conditions = {};
    
    // Handle the stage-based format
    if (json.containsKey('optimal_conditions')) {
      final optimalConditions = json['optimal_conditions'] as Map<String, dynamic>;
      for (var stage in optimalConditions.keys) {
        final stageData = optimalConditions[stage] as Map<String, dynamic>;
        conditions[stage] = {};
        
        // Process each range
        for (var range in stageData.keys) {
          final rangeData = stageData[range] as Map<String, dynamic>;
          conditions[stage]![range] = {
            'min': (rangeData['min'] as num).toDouble(),
            'max': (rangeData['max'] as num).toDouble(),
          };
        }
      }
    }
    
    return OptimalConditions(stageConditions: conditions);
  }

  Map<String, dynamic> toJson() {
    return stageConditions;
  }
}

class PlantProfile {
  final String id;
  final String name;
  final String identifier;
  final String notes;
  final OptimalConditions optimalConditions;
  final int growDurationDays;
  final String? userId;
  final String mode;
  final Map<String, dynamic> _originalJson;

  Map<String, dynamic> get originalJson => _originalJson;

  PlantProfile({
    required this.id,
    required this.name,
    required this.identifier,
    required this.notes,
    required this.optimalConditions,
    required this.growDurationDays,
    this.userId,
    this.mode = 'simple',
    Map<String, dynamic>? originalJson,
  }) : _originalJson = originalJson ?? {};

  factory PlantProfile.fromJson(String id, Map<String, dynamic> json) {
    // Handle potential nested structure where the actual profile data is under 'plant_profile'
    Map<String, dynamic> profileData = json;
    if (json.containsKey('plant_profile')) {
      profileData = json['plant_profile'] as Map<String, dynamic>;
    }
    
    final name = profileData['name'] ?? '';
    final identifier = profileData['identifier'] ?? name.toLowerCase();
    final notes = profileData['notes'] ?? '';
    final growDurationDays = profileData['grow_duration_days'] ?? 0;
    final userId = profileData['user_id'];
    final mode = profileData['mode'] ?? 'simple';
    
    // Get optimal conditions
    final optimalConditions = OptimalConditions.fromJson(
      profileData.containsKey('optimal_conditions') 
          ? profileData 
          : {'optimal_conditions': profileData}
    );
    
    return PlantProfile(
      id: id,
      name: name,
      identifier: identifier,
      notes: notes,
      optimalConditions: optimalConditions,
      growDurationDays: growDurationDays is int ? growDurationDays : (growDurationDays as num).toInt(),
      userId: userId,
      mode: mode,
      originalJson: profileData,
    );
  }

  Map<String, dynamic> toJson() {
    if (_originalJson.isNotEmpty) {
      return _originalJson;
    }
    
    return {
      'identifier': identifier,
      'name': name,
      'notes': notes,
      'grow_duration_days': growDurationDays,
      'optimal_conditions': optimalConditions.toJson(),
      'user_id': userId,
      'mode': mode,
    };
  }
} 