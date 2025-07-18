// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_change_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileChangeLogAdapter extends TypeAdapter<ProfileChangeLog> {
  @override
  final int typeId = 12;

  @override
  ProfileChangeLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileChangeLog(
      id: fields[0] as String,
      profileId: fields[1] as String,
      userId: fields[2] as String,
      userName: fields[3] as String,
      timestamp: fields[4] as DateTime,
      changedFields: (fields[5] as Map).cast<String, dynamic>(),
      previousValues: (fields[6] as Map).cast<String, dynamic>(),
      newValues: (fields[7] as Map).cast<String, dynamic>(),
      changeType: fields[8] as String,
      synced: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileChangeLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.changedFields)
      ..writeByte(6)
      ..write(obj.previousValues)
      ..writeByte(7)
      ..write(obj.newValues)
      ..writeByte(8)
      ..write(obj.changeType)
      ..writeByte(9)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileChangeLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
} 