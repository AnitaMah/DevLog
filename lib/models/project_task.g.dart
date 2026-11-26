// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectTaskAdapter extends TypeAdapter<ProjectTask> {
  @override
  final int typeId = 3;

  @override
  ProjectTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectTask(
      title: fields[0] as String,
      done: fields[1] as bool,
      dueDate: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectTask obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.done)
      ..writeByte(2)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
