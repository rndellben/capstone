// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_sync_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingSyncItemAdapter extends TypeAdapter<PendingSyncItem> {
  @override
  final int typeId = 10;

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
      createdAt: fields[4] as DateTime?,
      syncFailed: fields[5] as bool,
      syncAttempts: fields[6] as int,
      lastSyncAttempt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingSyncItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemType)
      ..writeByte(2)
      ..write(obj.operation)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.syncFailed)
      ..writeByte(6)
      ..write(obj.syncAttempts)
      ..writeByte(7)
      ..write(obj.lastSyncAttempt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSyncItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
