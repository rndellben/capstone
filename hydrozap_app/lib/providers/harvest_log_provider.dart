import 'package:flutter/foundation.dart';
import '../core/api/api_service.dart';
import '../core/models/harvest_log_model.dart';

class HarvestLogProvider with ChangeNotifier {
  final ApiService _apiService;
  List<HarvestLog> _logs = [];
  bool _isLoading = false;

  HarvestLogProvider(this._apiService);

  List<HarvestLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> fetchHarvestLogs(String deviceId, String growId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final logsData = await _apiService.getHarvestLogs(deviceId, growId);
      _logs = logsData.map((log) => HarvestLog.fromJson({...log, 'logId': log['log_id']})).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Error in HarvestLogProvider: $e');
      notifyListeners();
    }
  }

  Future<bool> addHarvestLog(String deviceId, String growId, HarvestLog log) async {
    try {
      final response = await _apiService.addHarvestLog(deviceId, {...log.toJson(), 'growId': growId});
      final success = response['error'] == null;
      if (success) {
        await fetchHarvestLogs(deviceId, growId);
      }
      return success;
    } catch (e) {
      print('Error adding harvest log: $e');
      return false;
    }
  }
} 