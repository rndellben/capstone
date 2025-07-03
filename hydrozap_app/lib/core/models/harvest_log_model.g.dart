// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'harvest_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      lastUpdated: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HarvestLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.logId)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.growId)
      ..writeByte(3)
      ..write(obj.cropName)
      ..writeByte(4)
      ..write(obj.harvestDate)
      ..writeByte(5)
      ..write(obj.yieldAmount)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.performanceMetrics)
      ..writeByte(8)
      ..write(obj.synced)
      ..writeByte(9)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarvestLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
