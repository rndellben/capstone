// providers/actuator_provider.dart
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class ActuatorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _actuatorConditions = [];
  bool _isLoading = false;

  List<dynamic> get actuatorConditions => _actuatorConditions;
  bool get isLoading => _isLoading;

  Future<void> fetchActuatorConditions(String deviceId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.getActuatorConditions(deviceId);
    _actuatorConditions = response;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addActuatorCondition(Map<String, dynamic> conditionData) async {
    final success = await _apiService.addActuatorCondition(conditionData);
    if (success) {
      fetchActuatorConditions(conditionData['device_id']);
    }
    return success;
  }

  Future<bool> deleteActuatorCondition(String conditionId, String deviceId) async {
    final success = await _apiService.deleteActuatorCondition(conditionId);
    if (success) {
      fetchActuatorConditions(deviceId);
    }
    return success;
  }
}
