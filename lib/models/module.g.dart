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
      parentId: fields[2] as String?,
      lastOpenedAt: fields[4] as DateTime?,
      iconName: fields[5] as String,
      description: fields[6] as String,
      isProject: fields[7] == null ? false : fields[7] as bool,
      status: fields[8] == null ? 'in_progress' : fields[8] as String,
      repoUrl: fields[9] as String?,
      deadline: fields[10] as DateTime?,
      tasks:
          fields[11] == null ? [] : (fields[11] as List?)?.cast<ProjectTask>(),
    );
  }

  @override
  void write(BinaryWriter writer, Module obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(4)
      ..write(obj.lastOpenedAt)
      ..writeByte(5)
      ..write(obj.iconName)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.isProject)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.repoUrl)
      ..writeByte(10)
      ..write(obj.deadline)
      ..writeByte(11)
      ..write(obj.tasks);
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
