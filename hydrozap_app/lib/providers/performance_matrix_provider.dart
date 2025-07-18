import 'package:flutter/material.dart';
import 'dart:math';
import '../core/models/performance_matrix_model.dart';
import '../core/api/api_service.dart';

class PerformanceMatrixProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  PerformanceMatrix? _currentMatrix;
  final List<HarvestResult> _harvestResults = [];
  final List<LeaderboardEntry> _globalLeaderboard = [];
  bool _isLoadingLeaderboard = false;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  PerformanceMatrix? get currentMatrix => _currentMatrix;
  List<HarvestResult> get harvestResults => List.unmodifiable(_harvestResults);
  List<LeaderboardEntry> get globalLeaderboard => List.unmodifiable(_globalLeaderboard);
  
  // Get top performers (top 5 by score)
  List<HarvestResult> get topPerformers {
    final sortedResults = List<HarvestResult>.from(_harvestResults);
    sortedResults.sort((a, b) {
      final scoreA = a.totalScore ?? 0;
      final scoreB = b.totalScore ?? 0;
      return scoreB.compareTo(scoreA);
    });
    return sortedResults.take(5).toList();
  }

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

  // Fetch global leaderboard data
  Future<void> fetchGlobalLeaderboard() async {
    try {
      _isLoadingLeaderboard = true;
      notifyListeners();
      
      final leaderboardData = await _apiService.getGlobalLeaderboard();
     
      
      final newLeaderboard = <LeaderboardEntry>[];
      
      for (final entry in leaderboardData) {
      
        // Parse harvest date
        DateTime harvestDate;
        try {
          harvestDate = DateTime.parse(entry['harvestDate']);
        } catch (e) {
          harvestDate = DateTime.now();
          print('Error parsing harvest date: $e');
        }
        
        // Parse performance metrics
        Map<String, double> performanceMetrics = {};
        if (entry['performanceMetrics'] != null) {
          final metrics = entry['performanceMetrics'] as Map<String, dynamic>;
          metrics.forEach((key, value) {
            if (value is int) {
              performanceMetrics[key] = value.toDouble();
            } else if (value is double) {
              performanceMetrics[key] = value;
            }
          });
        }
        
        // Parse optimal conditions
        Map<String, dynamic>? optimalConditions;
        if (entry['optimalConditions'] != null) {
          optimalConditions = Map<String, dynamic>.from(entry['optimalConditions']);
        
        }
        
        // Parse rank with proper type handling
        int rank = 0;
        if (entry['rank'] is int) {
          rank = entry['rank'];
        } else if (entry['rank'] is String) {
          rank = int.tryParse(entry['rank']) ?? 0;
        }
        
        // Parse rating with proper type handling
        int rating = 0;
        if (entry['rating'] is int) {
          rating = entry['rating'];
        } else if (entry['rating'] is String) {
          rating = int.tryParse(entry['rating']) ?? 0;
        }
        
        // Parse yield amount with proper type handling
        double yieldAmount = 0.0;
        if (entry['yieldAmount'] is double) {
          yieldAmount = entry['yieldAmount'];
        } else if (entry['yieldAmount'] is int) {
          yieldAmount = (entry['yieldAmount'] as int).toDouble();
        } else if (entry['yieldAmount'] is String) {
          yieldAmount = double.tryParse(entry['yieldAmount']) ?? 0.0;
        }
        
        // Parse score with proper type handling
        double score = 0.0;
        if (entry['score'] is double) {
          score = entry['score'];
        } else if (entry['score'] is int) {
          score = (entry['score'] as int).toDouble();
        } else if (entry['score'] is String) {
          score = double.tryParse(entry['score']) ?? 0.0;
        }
        
        // Parse growth duration with proper type handling
        int growthDuration = 0;
        if (entry['growthDuration'] is int) {
          growthDuration = entry['growthDuration'];
        } else if (entry['growthDuration'] is String) {
          growthDuration = int.tryParse(entry['growthDuration']) ?? 0;
        }
        
        newLeaderboard.add(LeaderboardEntry(
          rank: rank,
          logId: entry['logId'] ?? '',
          userId: entry['userId'] ?? '',
          cropName: entry['cropName'] ?? 'Unknown Crop',
          growProfileId: entry['growProfileId'] ?? '',
          growProfileName: entry['growProfileName'] ?? 'Custom Profile',
          harvestDate: harvestDate,
          yieldAmount: yieldAmount,
          rating: rating,
          score: score,
          performanceMetrics: performanceMetrics,
          growthDuration: growthDuration,
          optimalConditions: optimalConditions,
          remarks: entry['remarks'] ?? '', // <-- Add this line
        ));
      }
      
      // Sort by rank
      newLeaderboard.sort((a, b) => a.rank.compareTo(b.rank));
      
      // Clear and add all items to the existing list
      _globalLeaderboard.clear();
      _globalLeaderboard.addAll(newLeaderboard);
      
      _isLoadingLeaderboard = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLeaderboard = false;
      _globalLeaderboard.clear();
      notifyListeners();
    }
  }
} 