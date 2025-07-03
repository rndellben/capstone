
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

class HarvestResult {
  final String id;
  final String harvestId;
  final String plantId;
  final DateTime harvestDate;
  final Map<String, double> metricValues; // Maps metric ID to measured value
  bool isTopPerformer;
  Map<String, double>? normalizedScores;
  double? totalScore;
  
  HarvestResult({
    required this.id,
    required this.harvestId,
    required this.plantId,
    required this.harvestDate,
    required this.metricValues,
    this.isTopPerformer = false,
    this.normalizedScores,
    this.totalScore,
  });
  
  HarvestResult copyWith({
    String? id,
    String? harvestId,
    String? plantId,
    DateTime? harvestDate,
    Map<String, double>? metricValues,
    bool? isTopPerformer,
    Map<String, double>? normalizedScores,
    double? totalScore,
  }) {
    return HarvestResult(
      id: id ?? this.id,
      harvestId: harvestId ?? this.harvestId,
      plantId: plantId ?? this.plantId,
      harvestDate: harvestDate ?? this.harvestDate,
      metricValues: metricValues ?? Map.from(this.metricValues),
      isTopPerformer: isTopPerformer ?? this.isTopPerformer,
      normalizedScores: normalizedScores ?? this.normalizedScores,
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
      'normalizedScores': normalizedScores,
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
      normalizedScores: json['normalizedScores'] != null 
          ? Map<String, double>.from(json['normalizedScores']) 
          : null,
      totalScore: json['totalScore'],
    );
  }
} 