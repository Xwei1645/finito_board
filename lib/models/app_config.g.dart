// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppConfigAdapter extends TypeAdapter<AppConfig> {
  @override
  final int typeId = 2;

  @override
  AppConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppConfig(
      theme: fields[0] as String,
      language: fields[1] as String,
      autoStartup: fields[2] as bool,
      enableNotifications: fields[3] as bool,
      availableSubjects: (fields[4] as List).cast<String>(),
      availableTags: (fields[5] as List).cast<String>(),
      scaleFactor: fields[6] as double,
      columnCount: fields[7] as int,
      alwaysOnBottom: fields[8] as bool,
      backgroundOpacity: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AppConfig obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.autoStartup)
      ..writeByte(3)
      ..write(obj.enableNotifications)
      ..writeByte(4)
      ..write(obj.availableSubjects)
      ..writeByte(5)
      ..write(obj.availableTags)
      ..writeByte(6)
      ..write(obj.scaleFactor)
      ..writeByte(7)
      ..write(obj.columnCount)
      ..writeByte(8)
      ..write(obj.alwaysOnBottom)
      ..writeByte(9)
      ..write(obj.backgroundOpacity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
