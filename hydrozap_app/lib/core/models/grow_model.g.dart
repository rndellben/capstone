// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grow_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      lastUpdated: fields[6] as DateTime?,
      status: fields[7] as String,
      harvestDate: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Grow obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.growId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.deviceId)
      ..writeByte(3)
      ..write(obj.profileId)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.synced)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.harvestDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
