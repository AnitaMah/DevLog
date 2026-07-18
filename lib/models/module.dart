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
  final List<Submodule> submodules;

  @HiveField(3)
  final List<String> files;

  @HiveField(4)
  DateTime lastOpenedAt;

  Module({
    required this.id,
    required this.name,
    List<Submodule>? submodules,
    List<String>? files,
    DateTime? lastOpenedAt,
  })  : submodules = submodules ?? [],
        files = files ?? [],
        lastOpenedAt = lastOpenedAt ?? DateTime.now();

  void updateLastOpenedAt() {
    lastOpenedAt = DateTime.now();
    save();
  }
}
