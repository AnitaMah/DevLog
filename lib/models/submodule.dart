import 'package:hive/hive.dart';

part 'submodule.g.dart';

@HiveType(typeId: 2)
class Submodule extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> files;

  Submodule({
    required this.id,
    required this.name,
    List<String>? files,
  }) : files = files ?? [];
}
