import 'api_config.dart';

class ApiEndpoints {
  // Base URL
  static final String baseUrl = ApiConfig.baseUrl;

  // Auth endpoints
  static final String register = '$baseUrl/api/register/';
  static final String login = '$baseUrl/api/login/';
  static final String reset = '$baseUrl/api/reset-password/';
  static final String googleLogin = '$baseUrl/api/google-login/';
  static final String userProfile = '$baseUrl/api/user-profile/';

  // Device endpoints
  static final String getDevices = '$baseUrl/api/devices/';
  static final String addDevice = '$baseUrl/api/devices/';
  static final String updateDevice = '$baseUrl/api/devices/';
  static final String deleteDevice = '$baseUrl/api/devices/';
  static final String registeredDevices = '$baseUrl/api/registered-devices/';
  static final String getDeviceCount = '$baseUrl/api/device-count/';
  static final String getCurrentThresholds = '$baseUrl/api/devices/<str:device_id>/current_thresholds/';

  // Alert endpoints
  static final String getAlerts = '$baseUrl/api/alerts/';
  static final String triggerAlert = '$baseUrl/api/alerts/';
  static final String deleteAlert = '$baseUrl/api/alerts/';
  static final String getAlertCount = '$baseUrl/api/alerts/count/';

  // Grow Profile endpoints
  static final String getGrowProfiles = '$baseUrl/api/grow-profiles/';
  static final String addGrowProfile = '$baseUrl/api/grow-profiles/';
  static final String updateGrowProfile = '$baseUrl/api/grow-profiles/';
  static final String deleteGrowProfile = '$baseUrl/api/grow-profiles/';
  static String growProfileCsvDownload(String profileId) => '$baseUrl/api/grow-profiles/$profileId/download-csv/';
  
  // Profile Change Log endpoints
  static final String profileChangeLogs = '$baseUrl/api/profile-change-logs/';

  // Grow endpoints
  static final String getGrows = '$baseUrl/api/grows/';
  static final String addGrow = '$baseUrl/api/grows/';
  static final String updateGrow = '$baseUrl/api/grows/';
  static final String deleteGrow = '$baseUrl/api/grows/';
  static final String getGrowCount = '$baseUrl/api/grows/count/';
  static final String harvestReadiness = '$baseUrl/api/harvest-readiness/';

  // Sensor and Actuator Data Endpoints
  static final String sensorData = '$baseUrl/api/sensor-data/';
  static final String actuatorData = '$baseUrl/api/actuator-data/';
  static final String getActuatorConditions = '$baseUrl/api/actuator-conditions/';
  static final String addActuatorCondition = '$baseUrl/api/actuator-conditions/';
  static final String deleteActuatorCondition = '$baseUrl/api/actuator-conditions/';

  // Dashboard data
  static final String getDashboardCounts = '$baseUrl/api/dashboard-counts/';

  // Harvest logs
  static final String harvestLogs = '$baseUrl/api/harvest-logs/';
  static final String addHarvestLog = '$baseUrl/api/harvest-logs/';
  static final String globalLeaderboard = '$baseUrl/api/global-leaderboard/';

  // Plant Profile
  static final String getPlantProfiles = '$baseUrl/api/plant-profiles/';
  static final String addPlantProfile = '$baseUrl/api/plant-profiles/';
  static final String updatePlantProfile = '$baseUrl/api/plant-profiles/';
  static final String deletePlantProfile = '$baseUrl/api/plant-profiles/';
  static final String plantProfilesCsvUpload = '$baseUrl/api/plant-profiles/upload-csv/';
  static String plantProfileCsvDownload(String identifier) => '$baseUrl/api/plant-profiles/$identifier/download-csv/';

  // Predictive model endpoints
  static final String predictTipburn = '$baseUrl/api/predict/tipburn/';
  static final String predictColorIndex = '$baseUrl/api/predict/color-index/';
  static final String predictLeafCount = '$baseUrl/api/predict/leaf-count/';
  static final String predictCropSuggestion = '$baseUrl/api/predict/crop-suggestion/';
  static final String predictEnvironmentRecommendation = '$baseUrl/api/predict/environment-recommendation/';

   // FCM token endpoint
  static final String fcmToken = '$baseUrl/api/fcm-token/';

  // Notification preferences endpoints
  static final String notificationPreferences = '$baseUrl/api/notification-preferences/';
  static final String updateNotificationPreferences = '$baseUrl/api/update-notification-preferences/';

  // Feedback endpoint
  static final String feedback = '$baseUrl/api/feedback/';

  //Reports and analytics
  static final String generateReport = '$baseUrl/api/generate-report/';

  // Dosing logs endpoint
  static String dosingLogs(String deviceId) => '$baseUrl/api/devices/$deviceId/dosing-logs/';
}
