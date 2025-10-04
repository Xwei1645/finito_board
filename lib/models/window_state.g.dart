// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WindowStateAdapter extends TypeAdapter<WindowState> {
  @override
  final int typeId = 3;

  @override
  WindowState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WindowState(
      x: fields[0] as double,
      y: fields[1] as double,
      width: fields[2] as double,
      height: fields[3] as double,
      isMaximized: fields[4] as bool,
      isMinimized: fields[5] as bool,
      isFullScreen: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WindowState obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.isMaximized)
      ..writeByte(5)
      ..write(obj.isMinimized)
      ..writeByte(6)
      ..write(obj.isFullScreen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
