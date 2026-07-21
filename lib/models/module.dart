import 'package:hive/hive.dart';
import 'submodule.dart';

part 'module.g.dart';

@HiveType(typeId: 0)
class Module extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? parentId; // Додано для підтримки ієрархії

  @HiveField(3)
  final List<Submodule> submodules;

  @HiveField(4)
  final List<String> files;

  Module({
    required this.id,
    required this.name,
    this.parentId,
    List<Submodule>? submodules,
    List<String>? files,
  })  : submodules = submodules ?? [],
        files = files ?? [];
}
