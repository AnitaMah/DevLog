import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/submodule.dart';
import 'package:dev_log/models/user_model.dart';

class DatabaseHelper {
  static const String _modulesBox = 'modules';
  static const String _userBox = 'userBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ModuleAdapter());
    Hive.registerAdapter(SubmoduleAdapter());
    Hive.registerAdapter(UserModelAdapter());
    await Hive.openBox<Module>(_modulesBox);
    await Hive.openBox<UserModel>(_userBox);
  }

  // --- Modules ---
  static Box<Module> get _modules => Hive.box<Module>(_modulesBox);

  static List<Module> getAllModules() {
    return _modules.values.toList();
  }

  static Future<void> addModule(Module module) async {
    if (!_modules.values.any((m) => m.name == module.name)) {
      await _modules.add(module);
    }
  }

  static Future<void> deleteModule(String moduleId) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    await module.delete();
  }

  // --- Submodules ---
  static Future<void> addSubmodule(String moduleId, Submodule submodule) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    if (!module.submodules.any((s) => s.name == submodule.name)) {
      module.submodules.add(submodule);
      await module.save();
    }
  }

  static Future<void> deleteSubmodule(String moduleId, String submoduleId) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    module.submodules.removeWhere((s) => s.id == submoduleId);
    await module.save();
  }

  // --- Files ---
  static Future<void> addFileToModule(String moduleId, String fileName) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    if (!module.files.contains(fileName)) {
      module.files.add(fileName);
      await module.save();
    }
  }

  static Future<void> addFileToSubmodule(String moduleId, String submoduleId, String fileName) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    final submodule = module.submodules.firstWhere((s) => s.id == submoduleId);
    if (!submodule.files.contains(fileName)) {
      submodule.files.add(fileName);
      await module.save();
    }
  }
}
