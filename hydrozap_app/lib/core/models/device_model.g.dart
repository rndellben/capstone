// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceModelAdapter extends TypeAdapter<DeviceModel> {
  @override
  final int typeId = 1;

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
      emergencyStop: (fields[4] as bool?) ?? false,
      status: fields[5] as String,
      sensors: (fields[6] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, dynamic>())),
      actuators: (fields[7] as Map).cast<String, dynamic>(),
      userId: fields[8] as String,
      plantProfile: fields[9] as String?,
      actuatorConditions: (fields[10] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      synced: (fields[11] as bool?) ?? false,
      waterVolumeInLiters: fields[13] as double,
      lastUpdated: fields[12] as DateTime?,
      activeGrowId: fields[14] as String?,
      thresholds: (fields[15] as Map?)?.cast<String, dynamic>(),
      autoDoseEnabled: (fields[16] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deviceName)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.kit)
      ..writeByte(4)
      ..write(obj.emergencyStop)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.sensors)
      ..writeByte(7)
      ..write(obj.actuators)
      ..writeByte(8)
      ..write(obj.userId)
      ..writeByte(9)
      ..write(obj.plantProfile)
      ..writeByte(10)
      ..write(obj.actuatorConditions)
      ..writeByte(11)
      ..write(obj.synced)
      ..writeByte(12)
      ..write(obj.lastUpdated)
      ..writeByte(13)
      ..write(obj.waterVolumeInLiters)
      ..writeByte(14)
      ..write(obj.activeGrowId)
      ..writeByte(15)
      ..write(obj.thresholds)
      ..writeByte(16)
      ..write(obj.autoDoseEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
