// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModuleAdapter extends TypeAdapter<Module> {
  @override
  final int typeId = 0;

  @override
  Module read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Module(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      notesCount: fields[3] as int,
      iconName: fields[4] as String,
      parentId: fields[5] as String?,
      filePath: fields[6] as String?,
      progress: fields[7] as double,
      lastOpenedAt: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Module obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.notesCount)
      ..writeByte(4)
      ..write(obj.iconName)
      ..writeByte(5)
      ..write(obj.parentId)
      ..writeByte(6)
      ..write(obj.filePath)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.lastOpenedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
