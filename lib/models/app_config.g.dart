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
      theme: fields[0] as String? ?? 'system',
      language: fields[1] as String? ?? 'zh_CN',
      autoStartup: fields[2] as bool? ?? false,
      enableNotifications: fields[3] as bool? ?? true,
      availableSubjects: (fields[4] as List?)?.cast<String>() ?? const [],
      availableTags: (fields[5] as List?)?.cast<String>() ?? const [],
      scaleFactor: fields[6] as double? ?? 100.0,
      columnCount: fields[7] as int? ?? 3,
    );
  }

  @override
  void write(BinaryWriter writer, AppConfig obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.columnCount);
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
