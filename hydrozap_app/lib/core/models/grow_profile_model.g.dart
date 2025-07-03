// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grow_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      id: (fields[0] as String?) ?? '',
      name: (fields[1] as String?) ?? '',
      userId: (fields[2] as String?) ?? '',
      growDurationDays: (fields[3] as int?) ?? 0,
      isActive: (fields[4] as bool?) ?? false,
      plantProfileId: (fields[5] as String?) ?? '',
      optimalConditions: fields[6] as StageConditions,
      createdAt: fields[7] as DateTime,
      synced: (fields[8] as bool?) ?? false,
      lastUpdated: fields[9] as DateTime?,
      mode: (fields[10] as String?) ?? 'simple',
    );
  }

  @override
  void write(BinaryWriter writer, GrowProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.growDurationDays)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.plantProfileId)
      ..writeByte(6)
      ..write(obj.optimalConditions)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.synced)
      ..writeByte(9)
      ..write(obj.lastUpdated)
      ..writeByte(10)
      ..write(obj.mode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrowProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.stage1)
      ..writeByte(1)
      ..write(obj.stage2);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutrientScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.days)
      ..writeByte(1)
      ..write(obj.nutrients);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StageConditionsAdapter extends TypeAdapter<StageConditions> {
  @override
  final int typeId = 5;

  @override
  StageConditions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StageConditions(
      transplanting: fields[0] as OptimalConditions,
      vegetative: fields[1] as OptimalConditions,
      maturation: fields[2] as OptimalConditions,
    );
  }

  @override
  void write(BinaryWriter writer, StageConditions obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.transplanting)
      ..writeByte(1)
      ..write(obj.vegetative)
      ..writeByte(2)
      ..write(obj.maturation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageConditionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OptimalConditionsAdapter extends TypeAdapter<OptimalConditions> {
  @override
  final int typeId = 6;

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
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.temperature)
      ..writeByte(1)
      ..write(obj.humidity)
      ..writeByte(2)
      ..write(obj.phRange)
      ..writeByte(3)
      ..write(obj.ecRange)
      ..writeByte(4)
      ..write(obj.tdsRange);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimalConditionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RangeAdapter extends TypeAdapter<Range> {
  @override
  final int typeId = 11;

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
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.min)
      ..writeByte(1)
      ..write(obj.max);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
