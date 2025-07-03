import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../utils/logger.dart';

/// Enum representing the different types of predictions
enum PredictionType {
  tipburn,
  leafColor,
  plantHeight,
  leafCount,
  biomass,
  cropSuggestion,
  environmentRecommendation,
}

/// Model class for prediction inputs
class PredictionInput {
  final double? temperature;
  final double? humidity;
  final double? ec;
  final double? ph;
  final int? growthDays;
  final int? leafCount;
  final double? plantHeight;
  final double? leafColorIndex;

  PredictionInput({
    this.temperature,
    this.humidity,
    this.ec,
    this.ph,
    this.growthDays,
    this.leafCount,
    this.plantHeight,
    this.leafColorIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'ec': ec,
      'ph': ph,
      'growth_days': growthDays,
      'leaf_count': leafCount,
      'plant_height': plantHeight,
      'leaf_color_index': leafColorIndex,
    };
  }
}

/// Model class for prediction results
class PredictionResult {
  final PredictionType type;
  final dynamic value;
  final String unit;
  final String message;

  PredictionResult({
    required this.type,
    required this.value,
    required this.unit,
    this.message = '',
  });

  // Helper getters for specific prediction types
  bool get isTipburn => type == PredictionType.tipburn;
  bool get isLeafColor => type == PredictionType.leafColor;
  bool get isPlantHeight => type == PredictionType.plantHeight;
  bool get isLeafCount => type == PredictionType.leafCount;
  bool get isBiomass => type == PredictionType.biomass;
  bool get isCropSuggestion => type == PredictionType.cropSuggestion;
  bool get isEnvironmentRecommendation => type == PredictionType.environmentRecommendation;

  // Helper to convert value to display format
  String get displayValue {
    if (isTipburn) {
      return (value as bool) ? 'Yes' : 'No';
    } else if (isLeafColor) {
      return (value as double).toStringAsFixed(1);
    } else if (isPlantHeight) {
      return '${(value as double).toStringAsFixed(1)} $unit';
    } else if (isLeafCount) {
      return '${value.toString()} $unit';
    } else if (isBiomass) {
      return '${(value as double).toStringAsFixed(1)} $unit';
    } else if (isCropSuggestion) {
      return value.toString();
    } else if (isEnvironmentRecommendation) {
      return value.toString();
    }
    return value.toString();
  }

  // Get color based on prediction type
  Color getTypeColor() {
    switch (type) {
      case PredictionType.tipburn:
        return Colors.red;
      case PredictionType.leafColor:
        return Colors.green.shade700;
      case PredictionType.plantHeight:
        return Colors.blue.shade700;
      case PredictionType.leafCount:
        return Colors.orange;
      case PredictionType.biomass:
        return Colors.purple;
      case PredictionType.cropSuggestion:
        return Colors.teal;
      case PredictionType.environmentRecommendation:
        return Colors.green;
    }
  }

  // Get icon based on prediction type
  IconData getTypeIcon() {
    switch (type) {
      case PredictionType.tipburn:
        return Icons.warning_amber_rounded;
      case PredictionType.leafColor:
        return Icons.color_lens_outlined;
      case PredictionType.plantHeight:
        return Icons.height;
      case PredictionType.leafCount:
        return Icons.eco_outlined;
      case PredictionType.biomass:
        return Icons.scale_outlined;
      case PredictionType.cropSuggestion:
        return Icons.agriculture_outlined;
      case PredictionType.environmentRecommendation:
        return Icons.eco_outlined;
    }
  }
}

/// Service class to perform predictions
class PredictionService {
  static final ApiService _apiService = ApiService();
  
  static Future<PredictionResult> predictTipburn({
    required String cropType,
    required double temperature,
    required double humidity,
    required double ec,
    required double ph,
  }) async {
    try {
      final response = await _apiService.predictTipburn(
        cropType: cropType,
        temperature: temperature,
        humidity: humidity,
        ec: ec,
        ph: ph,
      );
      
      if (response == null) {
        throw Exception('Failed to get prediction from server');
      }
      
      final bool tipburnAbsent = response['tipburn_absent'] ?? false;
      final double confidenceLevel = response['confidence_level'] ?? 0.0;
      
      String message = tipburnAbsent 
          ? 'Low risk of tipburn under these conditions. (Confidence: ${(confidenceLevel * 100).toStringAsFixed(1)}%)' 
          : 'Risk of tipburn detected. Consider adjusting EC or pH. (Confidence: ${(confidenceLevel * 100).toStringAsFixed(1)}%)';
      
      return PredictionResult(
        type: PredictionType.tipburn,
        value: !tipburnAbsent, // Convert to "has tipburn"
        unit: '',
        message: message,
      );
    } catch (e) {
      logger.e('Error in tipburn prediction: $e');
      // Fallback to existing heuristic in case of API failure
      final probability = (temperature > 26 || ec > 2.0 || ph < 5.5 || ph > 6.5) ? 0.75 : 0.25;
      final hasTipburn = probability > 0.5;
      
      String message = hasTipburn 
          ? 'Risk of tipburn detected. Consider adjusting EC, pH or temperature. (Fallback prediction)' 
          : 'Low risk of tipburn under these conditions. (Fallback prediction)';
      
      return PredictionResult(
        type: PredictionType.tipburn,
        value: hasTipburn,
        unit: '',
        message: message,
      );
    }
  }
  
  static Future<PredictionResult> predictLeafColor({
    required double ec,
    required double ph,
    required int growthDays,
    required double temperature,
  }) async {
    try {
      final colorIndex = await _apiService.predictColorIndex(
        ec: ec,
        ph: ph,
        growthDays: growthDays,
        temperature: temperature,
      );
      
      if (colorIndex == null) {
        throw Exception('Failed to get prediction from server');
      }
      
      String message = '';
      if (colorIndex < 4) {
        message = 'Pale leaf color indicates potential nutrient deficiency.';
      } else if (colorIndex > 7) {
        message = 'Excellent leaf coloration expected under these conditions.';
      } else {
        message = 'Average leaf coloration expected.';
      }
      
      return PredictionResult(
        type: PredictionType.leafColor,
        value: colorIndex,
        unit: '',
        message: message,
      );
    } catch (e) {
      logger.e('Error in leaf color prediction: $e');
      // Fallback to the existing heuristic implementation
      
      double colorIndex = 5.0; // Default middle value
      
      if (ec < 1.0) {
        colorIndex -= 2.0;
      } else if (ec > 2.0) {
        colorIndex += 1.5;
      }
      
      if (ph < 5.5 || ph > 6.5) {
        colorIndex -= 1.5;
      }
      
      if (temperature < 18 || temperature > 28) {
        colorIndex -= 1.0;
      }
      
      if (growthDays < 14) {
        colorIndex -= 1.0;
      } else if (growthDays > 28) {
        colorIndex += 1.0;
      }
      
      colorIndex = colorIndex.clamp(0, 10);
      
      String message = '';
      if (colorIndex < 4) {
        message = 'Pale leaf color indicates potential nutrient deficiency. (Fallback prediction)';
      } else if (colorIndex > 7) {
        message = 'Excellent leaf coloration expected under these conditions. (Fallback prediction)';
      } else {
        message = 'Average leaf coloration expected. (Fallback prediction)';
      }
      
      return PredictionResult(
        type: PredictionType.leafColor,
        value: colorIndex,
        unit: '',
        message: message,
      );
    }
  }
  
  static Future<PredictionResult> predictLeafCount({
    String cropType = 'lettuce',
    required int growthDays,
    required double temperature,
    required double ph,
  }) async {
    try {
      final leafCount = await _apiService.predictLeafCount(
        cropType: cropType,
        growthDays: growthDays,
        temperature: temperature,
        ph: ph,
      );
      
      if (leafCount == null) {
        throw Exception('Failed to get prediction from server');
      }
      
      String message = leafCount > 12 
          ? 'Excellent leaf development expected.' 
          : 'Moderate leaf development expected.';
      
      return PredictionResult(
        type: PredictionType.leafCount,
        value: leafCount,
        unit: '',
        message: message,
      );
    } catch (e) {
      logger.e('Error in leaf count prediction: $e');
      // Fallback to the existing heuristic implementation
      
      int baseLeafCount = 4;
      double growthFactor = growthDays / 7;
      
      double tempFactor = 1.0;
      if (temperature < 18 || temperature > 28) {
        tempFactor = 0.8;
      } else if (temperature >= 20 && temperature <= 25) {
        tempFactor = 1.2;
      }
      
      double phFactor = 1.0;
      if (ph < 5.5 || ph > 6.5) {
        phFactor = 0.9;
      } else {
        phFactor = 1.1;
      }
      
      int leafCount = (baseLeafCount + (growthFactor * tempFactor * phFactor * 2)).round();
      
      String message = leafCount > 12 
          ? 'Excellent leaf development expected. (Fallback prediction)' 
          : 'Moderate leaf development expected. (Fallback prediction)';
      
      return PredictionResult(
        type: PredictionType.leafCount,
        value: leafCount,
        unit: '',
        message: message,
      );
    }
  }
  
  static Future<PredictionResult> predictPlantHeight({
    required int growthDays,
    required double temperature,
    required int leafCount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple height prediction based on growth days and temperature
    double baseHeight = 5.0; // Starting height in cm
    
    // Growth days contribution (linear growth assumption)
    double heightFromDays = growthDays * 0.8;
    
    // Temperature impact (optimal range promotes growth)
    double tempFactor = 1.0;
    if (temperature < 18) {
      tempFactor = 0.7;
    } else if (temperature > 26) {
      tempFactor = 0.8;
    } else {
      tempFactor = 1.2; // Optimal range
    }
    
    // Leaf count impact
    double leafFactor = leafCount > 10 ? 1.2 : 0.9;
    
    double height = baseHeight + (heightFromDays * tempFactor * leafFactor);
    
    String message = height > 25 
        ? 'Plant is predicted to grow tall under these conditions.' 
        : 'Plant height may be less than optimal under these conditions.';
    
    return PredictionResult(
      type: PredictionType.plantHeight,
      value: height,
      unit: 'cm',
      message: message,
    );
  }
  
  static Future<PredictionResult> predictBiomass({
    required double plantHeight,
    required int leafCount,
    required double leafColorIndex,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple biomass prediction based on height and leaf count
    double baseBiomass = 50.0; // grams
    
    // Height contribution (taller plants generally have more biomass)
    double heightFactor = plantHeight / 20.0; // normalized to typical height
    
    // Leaf count contribution
    double leafFactor = leafCount / 10.0; // normalized to typical leaf count
    
    // Leaf color contribution (healthier plants have more biomass)
    double colorFactor = leafColorIndex / 5.0; // normalized to middle of color scale
    
    double biomass = baseBiomass * heightFactor * leafFactor * colorFactor;
    
    String message = biomass > 200 
        ? 'High biomass yield expected.' 
        : 'Moderate biomass yield expected.';
    
    return PredictionResult(
      type: PredictionType.biomass,
      value: biomass,
      unit: 'g',
      message: message,
    );
  }
} 