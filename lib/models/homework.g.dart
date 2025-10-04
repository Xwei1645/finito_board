// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homework.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HomeworkAdapter extends TypeAdapter<Homework> {
  @override
  final int typeId = 0;

  @override
  Homework read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Homework(
      uuid: fields[0] as String,
      content: fields[1] as String,
      dueDate: fields[2] as DateTime,
      subjectUuid: fields[3] as String,
      tagUuids: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Homework obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.subjectUuid)
      ..writeByte(4)
      ..write(obj.tagUuids)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
