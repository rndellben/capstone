
class PerformanceMetric {
  final String id;
  final String name;
  final String category; // "growth" or "quality"
  final String unit;
  final String description;
  bool isSelected;
  double weight; // 0.0 to 1.0 
  double? minValue; // Optional minimum acceptable value
  double? maxValue; // Optional maximum acceptable value
  double? targetValue; // Optional target value
  bool higherIsBetter; // Whether higher values are better (true) or lower values are better (false)

  PerformanceMetric({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.description,
    this.isSelected = false,
    this.weight = 1.0,
    this.minValue,
    this.maxValue,
    this.targetValue,
    this.higherIsBetter = true,
  });

  PerformanceMetric copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    String? description,
    bool? isSelected,
    double? weight,
    double? minValue,
    double? maxValue,
    double? targetValue,
    bool? higherIsBetter,
  }) {
    return PerformanceMetric(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      isSelected: isSelected ?? this.isSelected,
      weight: weight ?? this.weight,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      targetValue: targetValue ?? this.targetValue,
      higherIsBetter: higherIsBetter ?? this.higherIsBetter,
    );
  }
}

class PerformanceMatrix {
  final String id;
  final String name;
  final String description;
  final List<PerformanceMetric> metrics;
  
  PerformanceMatrix({
    required this.id,
    required this.name,
    required this.description,
    required this.metrics,
  });

  // Get selected metrics
  List<PerformanceMetric> get selectedMetrics => 
      metrics.where((metric) => metric.isSelected).toList();
      
  // Get growth metrics
  List<PerformanceMetric> get growthMetrics => 
      metrics.where((metric) => metric.category == 'growth').toList();
      
  // Get quality metrics
  List<PerformanceMetric> get qualityMetrics => 
      metrics.where((metric) => metric.category == 'quality').toList();
      
  // Get total weight of selected metrics
  double get totalWeight {
    final total = selectedMetrics.fold(0.0, (sum, metric) => sum + metric.weight);
    return total > 0 ? total : 1.0; // Avoid division by zero
  }
  
  // Calculate normalized weights (ensuring they sum to 1.0)
  Map<String, double> get normalizedWeights {
    final Map<String, double> weights = {};
    final double total = totalWeight;
    
    for (final metric in selectedMetrics) {
      weights[metric.id] = metric.weight / total;
    }
    
    return weights;
  }
  
  PerformanceMatrix copyWith({
    String? id,
    String? name,
    String? description,
    List<PerformanceMetric>? metrics,
  }) {
    return PerformanceMatrix(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      metrics: metrics ?? List.from(this.metrics),
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metrics': metrics.map((metric) => {
        'id': metric.id,
        'name': metric.name,
        'category': metric.category,
        'unit': metric.unit,
        'description': metric.description,
        'isSelected': metric.isSelected,
        'weight': metric.weight,
        'minValue': metric.minValue,
        'maxValue': metric.maxValue,
        'targetValue': metric.targetValue,
        'higherIsBetter': metric.higherIsBetter,
      }).toList(),
    };
  }
  
  // Create from JSON
  factory PerformanceMatrix.fromJson(Map<String, dynamic> json) {
    return PerformanceMatrix(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      metrics: (json['metrics'] as List).map((metricJson) => PerformanceMetric(
        id: metricJson['id'],
        name: metricJson['name'],
        category: metricJson['category'],
        unit: metricJson['unit'],
        description: metricJson['description'],
        isSelected: metricJson['isSelected'] ?? false,
        weight: metricJson['weight'] ?? 1.0,
        minValue: metricJson['minValue'],
        maxValue: metricJson['maxValue'],
        targetValue: metricJson['targetValue'],
        higherIsBetter: metricJson['higherIsBetter'] ?? true,
      )).toList(),
    );
  }
  
  // Create default performance matrix with common metrics
  factory PerformanceMatrix.createDefault() {
    return PerformanceMatrix(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Default Matrix',
      description: 'Default performance evaluation criteria',
      metrics: [
        // Growth metrics
        PerformanceMetric(
          id: 'biomass',
          name: 'Biomass',
          category: 'growth',
          unit: 'g',
          description: 'Total plant weight/biomass',
          isSelected: true,
          weight: 1.0,
          higherIsBetter: true,
        ),
        PerformanceMetric(
          id: 'height',
          name: 'Height',
          category: 'growth',
          unit: 'cm',
          description: 'Plant height',
          isSelected: true,
          weight: 0.8,
          higherIsBetter: true,
        ),
        PerformanceMetric(
          id: 'leaf_count',
          name: 'Leaf Count',
          category: 'growth',
          unit: 'count',
          description: 'Number of leaves',
          isSelected: true,
          weight: 0.9,
          higherIsBetter: true,
        ),
        PerformanceMetric(
          id: 'growth_rate',
          name: 'Growth Rate',
          category: 'growth',
          unit: 'g/day',
          description: 'Average daily growth rate',
          isSelected: false,
          weight: 0.7,
          higherIsBetter: true,
        ),
        
        // Quality metrics
        PerformanceMetric(
          id: 'leaf_color',
          name: 'Leaf Color',
          category: 'quality',
          unit: 'rating',
          description: 'Leaf color rating (1-5)',
          isSelected: true,
          weight: 0.9,
          minValue: 1,
          maxValue: 5,
          higherIsBetter: true,
        ),
        PerformanceMetric(
          id: 'tipburn',
          name: 'Tipburn Absence',
          category: 'quality',
          unit: 'rating',
          description: 'Absence of tipburn (1-5)',
          isSelected: true,
          weight: 1.0,
          minValue: 1,
          maxValue: 5,
          higherIsBetter: true,
        ),
        PerformanceMetric(
          id: 'uniformity',
          name: 'Uniformity',
          category: 'quality',
          unit: 'rating',
          description: 'Plant growth uniformity (1-5)',
          isSelected: true,
          weight: 0.8,
          minValue: 1,
          maxValue: 5,
          higherIsBetter: true,
        ),
        PerformanceMetric(
          id: 'texture',
          name: 'Leaf Texture',
          category: 'quality',
          unit: 'rating',
          description: 'Leaf texture quality (1-5)',
          isSelected: false,
          weight: 0.7,
          minValue: 1,
          maxValue: 5,
          higherIsBetter: true,
        ),
      ],
    );
  }
}

// Class to represent a harvest result with performance metrics
class HarvestResult {
  final String id;
  final String harvestId;
  final String plantId;
  final DateTime harvestDate;
  final Map<String, double> metricValues;
  double? totalScore;
  bool isTopPerformer = false;
  
  HarvestResult({
    required this.id,
    required this.harvestId,
    required this.plantId,
    required this.harvestDate,
    required this.metricValues,
    this.totalScore,
    this.isTopPerformer = false,
  });
  
  HarvestResult copyWith({
    String? id,
    String? harvestId,
    String? plantId,
    DateTime? harvestDate,
    Map<String, double>? metricValues,
    bool? isTopPerformer,
    double? totalScore,
  }) {
    return HarvestResult(
      id: id ?? this.id,
      harvestId: harvestId ?? this.harvestId,
      plantId: plantId ?? this.plantId,
      harvestDate: harvestDate ?? this.harvestDate,
      metricValues: metricValues ?? Map.from(this.metricValues),
      isTopPerformer: isTopPerformer ?? this.isTopPerformer,
      totalScore: totalScore ?? this.totalScore,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'harvestId': harvestId,
      'plantId': plantId,
      'harvestDate': harvestDate.toIso8601String(),
      'metricValues': metricValues,
      'isTopPerformer': isTopPerformer,
      'totalScore': totalScore,
    };
  }
  
  // Create from JSON
  factory HarvestResult.fromJson(Map<String, dynamic> json) {
    return HarvestResult(
      id: json['id'],
      harvestId: json['harvestId'],
      plantId: json['plantId'],
      harvestDate: DateTime.parse(json['harvestDate']),
      metricValues: Map<String, double>.from(json['metricValues']),
      isTopPerformer: json['isTopPerformer'] ?? false,
      totalScore: json['totalScore'],
    );
  }
}

// Class to represent a global leaderboard entry
class LeaderboardEntry {
  final int rank;
  final String logId;
  final String userId;
  final String cropName;
  final String growProfileId;
  final String growProfileName;
  final DateTime harvestDate;
  final double yieldAmount;
  final int rating;
  final double score;
  final Map<String, double> performanceMetrics;
  
  // Additional fields for detailed view
  final String growerName;
  final int growthDuration;
  final String? remarks;
  final double averageTemperature;
  final double averageHumidity;
  final double averagePh;
  final double averageEc;
  final int lightHours;
  final double yieldScore;
  final double qualityScore;
  final double efficiencyScore;
  final double consistencyScore;
  
  // Optimal growing conditions from backend
  final Map<String, dynamic>? optimalConditions;
  
  LeaderboardEntry({
    required this.rank,
    required this.logId,
    required this.userId,
    required this.cropName,
    required this.growProfileId,
    required this.growProfileName,
    required this.harvestDate,
    required this.yieldAmount,
    required this.rating,
    required this.score,
    required this.performanceMetrics,
    this.growerName = 'Anonymous',
    this.growthDuration = 0,
    this.remarks,
    this.averageTemperature = 0.0,
    this.averageHumidity = 0.0,
    this.averagePh = 0.0,
    this.averageEc = 0.0,
    this.lightHours = 0,
    this.yieldScore = 0.0,
    this.qualityScore = 0.0,
    this.efficiencyScore = 0.0,
    this.consistencyScore = 0.0,
    this.optimalConditions,
  });
  
  // Create a copy with optional new values
  LeaderboardEntry copyWith({
    int? rank,
    String? logId,
    String? userId,
    String? cropName,
    String? growProfileId,
    String? growProfileName,
    DateTime? harvestDate,
    double? yieldAmount,
    int? rating,
    double? score,
    Map<String, double>? performanceMetrics,
    String? growerName,
    int? growthDuration,
    String? remarks,
    double? averageTemperature,
    double? averageHumidity,
    double? averagePh,
    double? averageEc,
    int? lightHours,
    double? yieldScore,
    double? qualityScore,
    double? efficiencyScore,
    double? consistencyScore,
    Map<String, dynamic>? optimalConditions,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      cropName: cropName ?? this.cropName,
      growProfileId: growProfileId ?? this.growProfileId,
      growProfileName: growProfileName ?? this.growProfileName,
      harvestDate: harvestDate ?? this.harvestDate,
      yieldAmount: yieldAmount ?? this.yieldAmount,
      rating: rating ?? this.rating,
      score: score ?? this.score,
      performanceMetrics: performanceMetrics ?? Map.from(this.performanceMetrics),
      growerName: growerName ?? this.growerName,
      growthDuration: growthDuration ?? this.growthDuration,
      remarks: remarks ?? this.remarks,
      averageTemperature: averageTemperature ?? this.averageTemperature,
      averageHumidity: averageHumidity ?? this.averageHumidity,
      averagePh: averagePh ?? this.averagePh,
      averageEc: averageEc ?? this.averageEc,
      lightHours: lightHours ?? this.lightHours,
      yieldScore: yieldScore ?? this.yieldScore,
      qualityScore: qualityScore ?? this.qualityScore,
      efficiencyScore: efficiencyScore ?? this.efficiencyScore,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      optimalConditions: optimalConditions ?? this.optimalConditions,
    );
  }
} 