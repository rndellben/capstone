import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/core/models/grow_model.dart';
import 'package:hydrozap_app/core/models/grow_profile_model.dart';
import 'package:hydrozap_app/core/models/alert_model.dart';
import 'package:hydrozap_app/core/models/harvest_log_model.dart';
import 'package:hydrozap_app/core/models/pending_sync_item.dart';
import 'package:hydrozap_app/core/models/plant_profile_model.dart';
import 'package:hydrozap_app/core/utils/logger.dart';

/// HiveService is responsible for all local storage operations using Hive
class HiveService {
  // Singleton instance
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();
  
  // Box names
  static const String devicesBoxName = 'devices';
  static const String growsBoxName = 'grows';
  static const String growProfilesBoxName = 'grow_profiles';
  static const String alertsBoxName = 'alerts';
  static const String harvestLogsBoxName = 'harvest_logs';
  static const String pendingSyncBoxName = 'pending_sync';
  static const String plantProfilesBoxName = 'plant_profiles';
  
  // Initialization flag
  bool _isInitialized = false;
  
  /// Initialize Hive and register adapters
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(DeviceModelAdapter());
    Hive.registerAdapter(GrowAdapter());
    Hive.registerAdapter(GrowProfileAdapter());
    Hive.registerAdapter(NutrientScheduleAdapter());
    Hive.registerAdapter(StageAdapter());
    Hive.registerAdapter(OptimalConditionsAdapter());
    Hive.registerAdapter(RangeAdapter());
    Hive.registerAdapter(StageConditionsAdapter());
    Hive.registerAdapter(AlertAdapter());
    Hive.registerAdapter(HarvestLogAdapter());
    Hive.registerAdapter(PendingSyncItemAdapter());
    
    // Open boxes
    await Hive.openBox<DeviceModel>(devicesBoxName);
    await Hive.openBox<Grow>(growsBoxName);
    await Hive.openBox<GrowProfile>(growProfilesBoxName);
    await Hive.openBox<Alert>(alertsBoxName);
    await Hive.openBox<HarvestLog>(harvestLogsBoxName);
    await Hive.openBox<PendingSyncItem>(pendingSyncBoxName);
    await Hive.openBox(plantProfilesBoxName); // Use dynamic box for storing JSON strings
    
    _isInitialized = true;
  }
  
  // DEVICE OPERATIONS
  
  /// Save a device to local storage
  Future<void> saveDevice(DeviceModel device) async {
    final box = Hive.box<DeviceModel>(devicesBoxName);
    await box.put(device.id, device);
  }
  
  /// Get a device by ID from local storage
  DeviceModel? getDevice(String deviceId) {
    final box = Hive.box<DeviceModel>(devicesBoxName);
    return box.get(deviceId);
  }
  
  /// Get all devices from local storage
  List<DeviceModel> getAllDevices() {
    final box = Hive.box<DeviceModel>(devicesBoxName);
    return box.values.toList();
  }
  
  /// Delete a device from local storage
  Future<void> deleteDevice(String deviceId) async {
    final box = Hive.box<DeviceModel>(devicesBoxName);
    await box.delete(deviceId);
  }
  
  // GROW PROFILE OPERATIONS
  
  /// Save a grow profile to local storage
  Future<void> saveGrowProfile(GrowProfile profile) async {
    final box = await Hive.openBox<GrowProfile>(growProfilesBoxName);
    await box.put(profile.id, profile);
  }
  
  /// Get a grow profile by ID from local storage
  GrowProfile? getGrowProfile(String profileId) {
    final box = Hive.box<GrowProfile>(growProfilesBoxName);
    return box.get(profileId);
  }
  
  /// Get all grow profiles from local storage
  List<GrowProfile> getAllGrowProfiles() {
    final box = Hive.box<GrowProfile>(growProfilesBoxName);
    return box.values.toList();
  }
  
  /// Delete a grow profile from local storage
  Future<void> deleteGrowProfile(String profileId) async {
    final box = Hive.box<GrowProfile>(growProfilesBoxName);
    await box.delete(profileId);
  }
  
  // PLANT PROFILE OPERATIONS
  
  /// Save a plant profile to local storage
  Future<void> savePlantProfile(PlantProfile profile) async {
    final box = Hive.box(plantProfilesBoxName);
    final profileJson = profile.toJson();
    await box.put(profile.id, jsonEncode(profileJson));
  }
  
  /// Get a plant profile by ID from local storage
  PlantProfile? getPlantProfile(String profileId) {
    final box = Hive.box(plantProfilesBoxName);
    final jsonString = box.get(profileId);
    if (jsonString != null) {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return PlantProfile.fromJson(profileId, data);
    }
    return null;
  }
  
  /// Get all plant profiles from local storage
  List<PlantProfile> getAllPlantProfiles() {
    final box = Hive.box(plantProfilesBoxName);
    final profiles = <PlantProfile>[];
    
    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonString);
          profiles.add(PlantProfile.fromJson(key.toString(), data));
        } catch (e) {
          logger.e('Error parsing plant profile: $e');
        }
      }
    }
    
    return profiles;
  }
  
  /// Delete a plant profile from local storage
  Future<void> deletePlantProfile(String profileId) async {
    final box = Hive.box(plantProfilesBoxName);
    await box.delete(profileId);
  }
  
  // GROW OPERATIONS
  
  /// Save a grow to local storage
  Future<void> saveGrow(Grow grow) async {
    final box = Hive.box<Grow>(growsBoxName);
    await box.put(grow.growId, grow);
  }
  
  /// Get a grow by ID from local storage
  Grow? getGrow(String growId) {
    final box = Hive.box<Grow>(growsBoxName);
    return box.get(growId);
  }
  
  /// Get all grows from local storage
  List<Grow> getAllGrows() {
    final box = Hive.box<Grow>(growsBoxName);
    return box.values.toList();
  }
  
  /// Delete a grow from local storage
  Future<void> deleteGrow(String growId) async {
    final box = Hive.box<Grow>(growsBoxName);
    await box.delete(growId);
  }
  
  // ALERT OPERATIONS
  
  /// Save an alert to local storage
  Future<void> saveAlert(Alert alert) async {
    final box = Hive.box<Alert>(alertsBoxName);
    await box.put(alert.alertId, alert);
  }
  
  /// Get an alert by ID from local storage
  Alert? getAlert(String alertId) {
    final box = Hive.box<Alert>(alertsBoxName);
    return box.get(alertId);
  }
  
  /// Get all alerts from local storage
  List<Alert> getAllAlerts() {
    final box = Hive.box<Alert>(alertsBoxName);
    return box.values.toList();
  }
  
  /// Delete an alert from local storage
  Future<void> deleteAlert(String alertId) async {
    final box = Hive.box<Alert>(alertsBoxName);
    await box.delete(alertId);
  }
  
  // HARVEST LOG OPERATIONS
  
  /// Save a harvest log to local storage
  Future<void> saveHarvestLog(HarvestLog log) async {
    final box = Hive.box<HarvestLog>(harvestLogsBoxName);
    await box.put(log.logId, log);
  }
  
  /// Get a harvest log by ID from local storage
  HarvestLog? getHarvestLog(String logId) {
    final box = Hive.box<HarvestLog>(harvestLogsBoxName);
    return box.get(logId);
  }
  
  /// Get all harvest logs from local storage
  List<HarvestLog> getAllHarvestLogs() {
    final box = Hive.box<HarvestLog>(harvestLogsBoxName);
    return box.values.toList();
  }
  
  /// Delete a harvest log from local storage
  Future<void> deleteHarvestLog(String logId) async {
    final box = Hive.box<HarvestLog>(harvestLogsBoxName);
    await box.delete(logId);
  }
  
  // PENDING SYNC OPERATIONS
  
  /// Save a pending sync item to local storage
  Future<void> savePendingSyncItem(PendingSyncItem item) async {
    final box = Hive.box<PendingSyncItem>(pendingSyncBoxName);
    await box.put(item.id, item);
  }
  
  /// Get a pending sync item by ID from local storage
  PendingSyncItem? getPendingSyncItem(String id) {
    final box = Hive.box<PendingSyncItem>(pendingSyncBoxName);
    return box.get(id);
  }
  
  /// Get all pending sync items from local storage
  List<PendingSyncItem> getAllPendingSyncItems() {
    final box = Hive.box<PendingSyncItem>(pendingSyncBoxName);
    return box.values.toList();
  }
  
  /// Delete a pending sync item from local storage
  Future<void> deletePendingSyncItem(String id) async {
    final box = Hive.box<PendingSyncItem>(pendingSyncBoxName);
    await box.delete(id);
  }
  
  /// Get all pending sync items for a specific type
  List<PendingSyncItem> getPendingSyncItemsByType(String itemType) {
    final box = Hive.box<PendingSyncItem>(pendingSyncBoxName);
    return box.values.where((item) => item.itemType == itemType).toList();
  }
  
  /// Clear all pending sync items that have been synced
  Future<void> clearSyncedItems() async {
    final box = Hive.box<PendingSyncItem>(pendingSyncBoxName);
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.syncFailed) {
        keysToDelete.add(key);
      }
    }
    
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Add a pending sync item to the queue
  Future<void> addPendingSyncItem(PendingSyncItem item) async {
    await savePendingSyncItem(item);
  }

  /// Remove a specific pending sync item (after successful sync)
  Future<void> removePendingSyncItem(String id) async {
    await deletePendingSyncItem(id);
  }

  /// Clear all data (useful for logout)
  Future<void> clearAllData() async {
    await Hive.box<PendingSyncItem>(pendingSyncBoxName).clear();
    await Hive.box<Grow>(growsBoxName).clear();
    await Hive.box<DeviceModel>(devicesBoxName).clear();
    await Hive.box<GrowProfile>(growProfilesBoxName).clear();
  }

  // GROW OPERATIONS
  
  /// Add a grow to local storage
  Future<void> addLocalGrow(Grow grow) async {
    await saveGrow(grow);
  }
  
  /// Get all locally stored grows for a user
  List<Grow> getLocalGrows(String userId) {
    final box = Hive.box<Grow>(growsBoxName);
    return box.values.where((grow) => grow.userId == userId).toList();
  }
  
  /// Delete a locally stored grow
  Future<void> deleteLocalGrow(String growId) async {
    final box = Hive.box<Grow>(growsBoxName);
    await box.delete(growId);
  }
  
  // DEVICE OPERATIONS
  
  /// Add a device to local storage
  Future<void> addLocalDevice(DeviceModel device) async {
    await saveDevice(device);
  }
  
  /// Get all locally stored devices for a user
  List<DeviceModel> getLocalDevices(String userId) {
    final box = Hive.box<DeviceModel>(devicesBoxName);
    return box.values.where((device) => device.userId == userId).toList();
  }
  
  /// Delete a locally stored device
  Future<void> deleteLocalDevice(String deviceId) async {
    final box = Hive.box<DeviceModel>(devicesBoxName);
    await box.delete(deviceId);
  }
  
  // GROW PROFILE OPERATIONS
  
  /// Add a grow profile to local storage
  Future<void> addLocalGrowProfile(GrowProfile profile) async {
    final box = await Hive.openBox<GrowProfile>(growProfilesBoxName);
    await box.put(profile.id, profile);
  }
  
  /// Get all locally stored grow profiles for a user
  List<GrowProfile> getLocalGrowProfiles(String userId) {
    final box = Hive.box<GrowProfile>(growProfilesBoxName);
    return box.values.where((profile) => profile.userId == userId).toList();
  }
  
  /// Delete a locally stored grow profile
  Future<void> deleteLocalGrowProfile(String profileId) async {
    final box = Hive.box<GrowProfile>(growProfilesBoxName);
    await box.delete(profileId);
  }

  Future<void> updateGrowProfile(GrowProfile profile) async {
    await saveGrowProfile(profile);
  }

  /// Reset grow profiles box (use only in case of data corruption)
  Future<void> resetGrowProfiles() async {
    try {
      logger.w('Attempting to reset grow profiles box due to data corruption');
      final box = await Hive.openBox<GrowProfile>(growProfilesBoxName);
      await box.clear();
      await box.close();
      logger.i('Grow profiles box reset successful');
    } catch (e) {
      logger.e('Error while resetting grow profiles box: $e');
      // If opening the box fails, try to delete it
      try {
        logger.w('Attempting to delete grow profiles box file');
        await Hive.deleteBoxFromDisk(growProfilesBoxName);
        logger.i('Grow profiles box deleted successfully');
      } catch (e) {
        logger.e('Error while deleting grow profiles box: $e');
      }
    }
  }
} 