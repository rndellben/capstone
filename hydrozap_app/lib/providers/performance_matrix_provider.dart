import 'package:flutter/foundation.dart';
import 'dart:math' show min, max;
import '../core/models/performance_matrix_model.dart';
import '../core/api/api_service.dart';

class PerformanceMatrixProvider with ChangeNotifier {
  PerformanceMatrix? _currentMatrix;
  final List<HarvestResult> _harvestResults = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  // Getter for the current matrix
  PerformanceMatrix? get currentMatrix => _currentMatrix;
  
  // Getter for harvest results
  List<HarvestResult> get harvestResults => _harvestResults;
  
  // Getter for top performers
  List<HarvestResult> get topPerformers {
    if (_harvestResults.isEmpty) return [];
    
    // Sort by total score descending
    final sorted = List<HarvestResult>.from(_harvestResults)
      ..sort((a, b) => (b.totalScore ?? 0).compareTo(a.totalScore ?? 0));
    
    // Return top 30% or at least 3 results
    final topCount = max(3, (_harvestResults.length * 0.3).ceil());
    return sorted.take(topCount).toList();
  }

  bool get isLoading => _isLoading;
  
  // Initialize with default matrix
  void initializeDefaultMatrix() {
    _currentMatrix = PerformanceMatrix(
      id: 'default',
      name: 'Default Matrix',
      description: 'Default Matrix',
      metrics: [
        PerformanceMetric(
          id: 'biomass',
          name: 'Biomass',
          description: 'Total plant mass at harvest',
          unit: 'g',
          category: 'growth',
          isSelected: true,
          weight: 1.0,
          higherIsBetter: true,
          minValue: 0,
        ),
        PerformanceMetric(
          id: 'height',
          name: 'Height',
          description: 'Plant height at harvest',
          unit: 'cm',
          category: 'growth',
          isSelected: true,
          weight: 0.8,
          higherIsBetter: true,
          minValue: 0,
        ),
        PerformanceMetric(
          id: 'leaf_count',
          name: 'Leaf Count',
          description: 'Number of leaves',
          unit: 'count',
          category: 'growth',
          isSelected: true,
          weight: 0.7,
          higherIsBetter: true,
          minValue: 0,
        ),
        PerformanceMetric(
          id: 'leaf_color',
          name: 'Leaf Color',
          description: 'Leaf color rating (1-5)',
          unit: 'rating',
          category: 'quality',
          isSelected: true,
          weight: 1.0,
          higherIsBetter: true,
          minValue: 1,
          maxValue: 5,
        ),
        PerformanceMetric(
          id: 'tipburn',
          name: 'Tipburn Absence',
          description: 'Rating of tipburn absence (1-5)',
          unit: 'rating',
          category: 'quality',
          isSelected: true,
          weight: 0.9,
          higherIsBetter: true,
          minValue: 1,
          maxValue: 5,
        ),
        PerformanceMetric(
          id: 'uniformity',
          name: 'Uniformity',
          description: 'Plant uniformity rating (1-5)',
          unit: 'rating',
          category: 'quality',
          isSelected: true,
          weight: 0.8,
          higherIsBetter: true,
          minValue: 1,
          maxValue: 5,
        ),
      ],
    );
    notifyListeners();
  }
  
  // Update the current matrix
  void updateMatrix(PerformanceMatrix matrix) {
    _currentMatrix = matrix;
    _updateHarvestResults();
    notifyListeners();
  }
  
  // Toggle a metric's selection status
  void toggleMetricSelection(String metricId) {
    if (_currentMatrix == null) return;
    
    final updatedMetrics = _currentMatrix!.metrics.map((metric) {
      if (metric.id == metricId) {
        return metric.copyWith(isSelected: !metric.isSelected);
      }
      return metric;
    }).toList();
    
    _currentMatrix = _currentMatrix!.copyWith(metrics: updatedMetrics);
    _updateHarvestResults();
    notifyListeners();
  }
  
  // Update a metric's weight
  void updateMetricWeight(String metricId, double weight) {
    if (_currentMatrix == null) return;
    
    final updatedMetrics = _currentMatrix!.metrics.map((metric) {
      if (metric.id == metricId) {
        return metric.copyWith(weight: weight);
      }
      return metric;
    }).toList();
    
    _currentMatrix = _currentMatrix!.copyWith(metrics: updatedMetrics);
    _updateHarvestResults();
    notifyListeners();
  }
  
  // Add a harvest result
  void addHarvestResult(HarvestResult result) {
    _harvestResults.add(result);
    _updateHarvestResults();
    notifyListeners();
  }
  
  // Add multiple harvest results
  void addHarvestResults(List<HarvestResult> results) {
    _harvestResults.addAll(results);
    _updateHarvestResults();
    notifyListeners();
  }
  
  // Remove a harvest result
  void removeHarvestResult(String resultId) {
    _harvestResults.removeWhere((result) => result.id == resultId);
    _updateHarvestResults();
    notifyListeners();
  }
  
  // Clear all harvest results
  void clearHarvestResults() {
    _harvestResults.clear();
    notifyListeners();
  }
  
  // Calculate normalized scores and identify top performers
  void _updateHarvestResults() {
    if (_currentMatrix == null) return;
    
    for (final result in _harvestResults) {
      double totalScore = 0;
      double totalWeight = 0;
      
      for (final metric in _currentMatrix!.selectedMetrics) {
        final value = result.metricValues[metric.id];
        if (value == null) continue;
        
        double score = 0;
        if (metric.minValue != null && metric.maxValue != null) {
          // Normalize value between 0 and 1 based on min/max range
          score = (value - metric.minValue!) / (metric.maxValue! - metric.minValue!);
        } else {
          // Use relative scoring based on all results for this metric
          final allValues = _harvestResults
              .map((r) => r.metricValues[metric.id])
              .whereType<double>()
              .toList();
          
          if (allValues.isEmpty) continue;
          
          final minValue = allValues.reduce(min);
          final maxValue = allValues.reduce(max);
          
          if (maxValue == minValue) {
            score = 1; // All values are the same
          } else {
            score = (value - minValue) / (maxValue - minValue);
          }
        }
        
        // Invert score if lower values are better
        if (!metric.higherIsBetter) {
          score = 1 - score;
        }
        
        totalScore += score * metric.weight;
        totalWeight += metric.weight;
      }
      
      // Update result with normalized score
      result.totalScore = totalWeight > 0 ? totalScore / totalWeight : null;
    }
    
    // Mark top performers
    final topPerformerIds = topPerformers.map((r) => r.id).toSet();
    for (final result in _harvestResults) {
      result.isTopPerformer = topPerformerIds.contains(result.id);
    }
  }
  
  // Fetch harvest data from API
  Future<void> fetchHarvestData(String deviceId, {String? growId}) async {
  try {
    _isLoading = true;
    notifyListeners();
    
    // Ensure we have a default matrix defined
    if (_currentMatrix == null) {
      initializeDefaultMatrix();
    }
    
    // Don't clear previous results here - this method is called for each device
    // and we want to aggregate results from all devices
    
    // Make sure deviceId is correctly passed here
    final logs = await _apiService.getHarvestLogs(deviceId, growId);
    _processHarvestLogs(logs);
    
    // Update performance calculations
    _updateHarvestResults();
    
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    print('Error fetching harvest data: $e');
    _isLoading = false;
    notifyListeners();
  }
}
  
  // Fetch and aggregate harvest data from multiple devices
  Future<void> fetchHarvestDataFromMultipleDevices(List<String> deviceIds) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Ensure we have a default matrix defined
      if (_currentMatrix == null) {
        initializeDefaultMatrix();
      }
      
      // Clear previous results only once at the beginning
      _harvestResults.clear();
      
      // Fetch and aggregate harvest logs for all devices
      for (final deviceId in deviceIds) {
        final logs = await _apiService.getHarvestLogs(deviceId);
        _processHarvestLogs(logs);
      }
      
      // Update performance calculations
      _updateHarvestResults();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching harvest data from multiple devices: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper method to process harvest logs
  void _processHarvestLogs(List<dynamic> logs) {
    for (final log in logs) {
      // Convert harvest date to DateTime
      DateTime harvestDate;
      try {
        harvestDate = DateTime.parse(log['harvestDate'] ?? log['harvest_date'] ?? DateTime.now().toString());
      } catch (e) {
        harvestDate = DateTime.now();
      }
      
      // Extract performance metrics if available
      final performanceMetrics = Map<String, double>.from(
        log['performanceMetrics'] ?? log['performance_metrics'] ?? {});
      
      // Create HarvestResult object
      final result = HarvestResult(
        id: log['logId'] ?? log['log_id'] ?? '',
        harvestId: log['growId'] ?? log['grow_id'] ?? '',
        plantId: log['cropName'] ?? log['crop_name'] ?? 'Unknown plant',
        harvestDate: harvestDate,
        metricValues: performanceMetrics,
      );
      
      _harvestResults.add(result);
    }
  }
  
  // Get performance details for a specific harvest result
  Map<String, dynamic> getPerformanceDetails(String resultId) {
    if (_currentMatrix == null) return {};
    
    final result = _harvestResults.firstWhere(
      (r) => r.id == resultId, 
      orElse: () => HarvestResult(
        id: '', 
        harvestId: '', 
        plantId: '', 
        harvestDate: DateTime.now(),
        metricValues: const {},
      ),
    );
    
    if (result.id.isEmpty) return {};
    
    final metricDetails = _currentMatrix!.selectedMetrics.map((metric) {
      final value = result.metricValues[metric.id] ?? 0.0;
      double score = 0;
      
      if (metric.minValue != null && metric.maxValue != null) {
        score = (value - metric.minValue!) / (metric.maxValue! - metric.minValue!);
      } else {
        final allValues = _harvestResults
            .map((r) => r.metricValues[metric.id])
            .whereType<double>()
            .toList();
        
        if (allValues.isNotEmpty) {
          final minValue = allValues.reduce(min);
          final maxValue = allValues.reduce(max);
          
          if (maxValue == minValue) {
            score = 1;
          } else {
            score = (value - minValue) / (maxValue - minValue);
          }
        }
      }
      
      if (!metric.higherIsBetter) {
        score = 1 - score;
      }
      
      final totalWeight = _currentMatrix!.selectedMetrics
          .map((m) => m.weight)
          .reduce((a, b) => a + b);
          
      return {
        'metric': metric,
        'value': value,
        'score': score,
        'contribution': score * metric.weight / totalWeight,
      };
    }).toList();
    
    return {
      'result': result,
      'metricDetails': metricDetails,
    };
  }
} 