import 'package:hive/hive.dart';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/core/models/grow_model.dart';
import 'package:hydrozap_app/core/models/grow_profile_model.dart';
import 'package:hydrozap_app/core/models/alert_model.dart';
import 'package:hydrozap_app/core/models/harvest_log_model.dart';
import 'package:hydrozap_app/core/models/pending_sync_item.dart';

/// Adapter for DeviceModel
class DeviceModelAdapter extends TypeAdapter<DeviceModel> {
  @override
  final int typeId = 1;

  // Helper method to convert Map to Map<String, Map<String, dynamic>>
  Map<String, Map<String, dynamic>> _convertToNestedMap(Map map) {
    Map<String, Map<String, dynamic>> result = {};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = Map<String, dynamic>.from(value);
      } else if (value is num || value is String || value is bool) {
        // For primitive values like double, int, String, bool
        result[key.toString()] = {'value': value};
      } else if (value == null) {
        // Handle null values
        result[key.toString()] = {'value': null};
      } else {
        // For other types, safely stringify
        result[key.toString()] = {'value': value.toString()};
      }
    });
    return result;
  }

  @override
  DeviceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceModel(
      id: fields[0] as String,
      deviceName: fields[1] as String,
      type: fields[2] as String,
      kit: fields[3] as String,
      emergencyStop: fields[4] as bool,
      status: fields[5] as String,
      sensors: _convertToNestedMap(fields[6] as Map),
      actuators: (fields[7] as Map).cast<String, dynamic>(),
      userId: fields[8] as String,
      plantProfile: fields[9] as String?,
      actuatorConditions: (fields[10] as List?)?.cast<Map<String, dynamic>>(),
      synced: fields[11] as bool,
      lastUpdated: fields[12] as DateTime,
      waterVolumeInLiters: fields.containsKey(13) ? (fields[13] as double?) ?? 0.0 : 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceModel obj) {
    writer.writeByte(14);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.deviceName);
    writer.writeByte(2);
    writer.write(obj.type);
    writer.writeByte(3);
    writer.write(obj.kit);
    writer.writeByte(4);
    writer.write(obj.emergencyStop);
    writer.writeByte(5);
    writer.write(obj.status);
    writer.writeByte(6);
    writer.write(obj.sensors);
    writer.writeByte(7);
    writer.write(obj.actuators);
    writer.writeByte(8);
    writer.write(obj.userId);
    writer.writeByte(9);
    writer.write(obj.plantProfile);
    writer.writeByte(10);
    writer.write(obj.actuatorConditions);
    writer.writeByte(11);
    writer.write(obj.synced);
    writer.writeByte(12);
    writer.write(obj.lastUpdated);
    writer.writeByte(13);
    writer.write(obj.waterVolumeInLiters);
  }
}

/// Adapter for GrowProfile
class GrowProfileAdapter extends TypeAdapter<GrowProfile> {
  @override
  final int typeId = 2;

  @override
  GrowProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GrowProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      userId: fields[2] as String,
      growDurationDays: fields[3] as int,
      isActive: fields[4] as bool,
      plantProfileId: fields[5] as String,
      optimalConditions: fields[6] as StageConditions,
      createdAt: fields[7] as DateTime,
      synced: fields[8] as bool,
      lastUpdated: fields[9] as DateTime,
      mode: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GrowProfile obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.userId);
    writer.writeByte(3);
    writer.write(obj.growDurationDays);
    writer.writeByte(4);
    writer.write(obj.isActive);
    writer.writeByte(5);
    writer.write(obj.plantProfileId);
    writer.writeByte(6);
    writer.write(obj.optimalConditions);
    writer.writeByte(7);
    writer.write(obj.createdAt);
    writer.writeByte(8);
    writer.write(obj.synced);
    writer.writeByte(9);
    writer.write(obj.lastUpdated);
    writer.writeByte(10);
    writer.write(obj.mode);
  }
}

/// Adapter for NutrientSchedule
class NutrientScheduleAdapter extends TypeAdapter<NutrientSchedule> {
  @override
  final int typeId = 3;

  @override
  NutrientSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutrientSchedule(
      stage1: fields[0] as Stage,
      stage2: fields[1] as Stage,
    );
  }

  @override
  void write(BinaryWriter writer, NutrientSchedule obj) {
    writer.writeByte(2);
    writer.writeByte(0);
    writer.write(obj.stage1);
    writer.writeByte(1);
    writer.write(obj.stage2);
  }
}

/// Adapter for Stage
class StageAdapter extends TypeAdapter<Stage> {
  @override
  final int typeId = 4;

  @override
  Stage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stage(
      days: fields[0] as int,
      nutrients: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Stage obj) {
    writer.writeByte(2);
    writer.writeByte(0);
    writer.write(obj.days);
    writer.writeByte(1);
    writer.write(obj.nutrients);
  }
}

/// Adapter for OptimalConditions
class OptimalConditionsAdapter extends TypeAdapter<OptimalConditions> {
  @override
  final int typeId = 5;

  @override
  OptimalConditions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OptimalConditions(
      temperature: fields[0] as Range,
      humidity: fields[1] as Range,
      phRange: fields[2] as Range,
      ecRange: fields[3] as Range,
      tdsRange: fields[4] as Range,
    );
  }

  @override
  void write(BinaryWriter writer, OptimalConditions obj) {
    writer.writeByte(4);
    writer.writeByte(0);
    writer.write(obj.temperature);
    writer.writeByte(1);
    writer.write(obj.humidity);
    writer.writeByte(2);
    writer.write(obj.phRange);
    writer.writeByte(3);
    writer.write(obj.ecRange);
    writer.writeByte(4);
    writer.write(obj.tdsRange);
  }
}

/// Adapter for Range
class RangeAdapter extends TypeAdapter<Range> {
  @override
  final int typeId = 6;

  @override
  Range read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Range(
      min: fields[0] as double,
      max: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Range obj) {
    writer.writeByte(2);
    writer.writeByte(0);
    writer.write(obj.min);
    writer.writeByte(1);
    writer.write(obj.max);
  }
}

/// Adapter for Grow
class GrowAdapter extends TypeAdapter<Grow> {
  @override
  final int typeId = 7;

  @override
  Grow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Grow(
      growId: fields[0] as String?,
      userId: fields[1] as String,
      deviceId: fields[2] as String,
      profileId: fields[3] as String,
      startDate: fields[4] as String,
      synced: fields[5] as bool,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Grow obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.growId);
    writer.writeByte(1);
    writer.write(obj.userId);
    writer.writeByte(2);
    writer.write(obj.deviceId);
    writer.writeByte(3);
    writer.write(obj.profileId);
    writer.writeByte(4);
    writer.write(obj.startDate);
    writer.writeByte(5);
    writer.write(obj.synced);
    writer.writeByte(6);
    writer.write(obj.lastUpdated);
  }
}

/// Adapter for HarvestLog
class HarvestLogAdapter extends TypeAdapter<HarvestLog> {
  @override
  final int typeId = 8;

  @override
  HarvestLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HarvestLog(
      logId: fields[0] as String,
      deviceId: fields[1] as String,
      growId: fields[2] as String,
      cropName: fields[3] as String,
      harvestDate: fields[4] as String,
      yieldAmount: fields[5] as double,
      rating: fields[6] as int,
      performanceMetrics: (fields[7] as Map).cast<String, double>(),
      synced: fields[8] as bool,
      lastUpdated: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HarvestLog obj) {
    writer.writeByte(10);
    writer.writeByte(0);
    writer.write(obj.logId);
    writer.writeByte(1);
    writer.write(obj.deviceId);
    writer.writeByte(2);
    writer.write(obj.growId);
    writer.writeByte(3);
    writer.write(obj.cropName);
    writer.writeByte(4);
    writer.write(obj.harvestDate);
    writer.writeByte(5);
    writer.write(obj.yieldAmount);
    writer.writeByte(6);
    writer.write(obj.rating);
    writer.writeByte(7);
    writer.write(obj.performanceMetrics);
    writer.writeByte(8);
    writer.write(obj.synced);
    writer.writeByte(9);
    writer.write(obj.lastUpdated);
  }
}

/// Adapter for Alert
class AlertAdapter extends TypeAdapter<Alert> {
  @override
  final int typeId = 9;

  @override
  Alert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Alert(
      alertId: fields[0] as String,
      deviceId: fields[1] as String,
      message: fields[2] as String,
      alertType: fields[3] as String,
      status: fields[4] as String,
      timestamp: fields[5] as String,
      synced: fields[6] as bool,
      lastUpdated: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Alert obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.alertId);
    writer.writeByte(1);
    writer.write(obj.deviceId);
    writer.writeByte(2);
    writer.write(obj.message);
    writer.writeByte(3);
    writer.write(obj.alertType);
    writer.writeByte(4);
    writer.write(obj.status);
    writer.writeByte(5);
    writer.write(obj.timestamp);
    writer.writeByte(6);
    writer.write(obj.synced);
    writer.writeByte(7);
    writer.write(obj.lastUpdated);
  }
}

/// Adapter for PendingSyncItem
class PendingSyncItemAdapter extends TypeAdapter<PendingSyncItem> {
  @override
  final int typeId = 20;

  @override
  PendingSyncItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingSyncItem(
      id: fields[0] as String,
      itemType: fields[1] as String,
      operation: fields[2] as String,
      data: (fields[3] as Map).cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      syncFailed: fields[5] as bool,
      syncAttempts: fields[6] as int,
      lastSyncAttempt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingSyncItem obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.itemType);
    writer.writeByte(2);
    writer.write(obj.operation);
    writer.writeByte(3);
    writer.write(obj.data);
    writer.writeByte(4);
    writer.write(obj.createdAt);
    writer.writeByte(5);
    writer.write(obj.syncFailed);
    writer.writeByte(6);
    writer.write(obj.syncAttempts);
    writer.writeByte(7);
    writer.write(obj.lastSyncAttempt);
  }
} 