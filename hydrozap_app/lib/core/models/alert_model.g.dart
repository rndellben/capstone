// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      lastUpdated: fields[7] as DateTime?,
      sensorData: (fields[8] as Map?)?.cast<String, dynamic>(),
      suggestedAction: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Alert obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.alertId)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.alertType)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.synced)
      ..writeByte(7)
      ..write(obj.lastUpdated)
      ..writeByte(8)
      ..write(obj.sensorData)
      ..writeByte(9)
      ..write(obj.suggestedAction);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
