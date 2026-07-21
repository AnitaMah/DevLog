import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/module.dart';
import '../models/submodule.dart';
import '../models/user_model.dart';

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
    await _modules.add(module);
  }

  static Future<void> deleteModule(String moduleId) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    await module.delete();
  }

  // --- Submodules ---
  static Future<void> addSubmodule(String moduleId, Submodule submodule) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    module.submodules.add(submodule);
    await module.save();
  }

  // --- Files ---
  static Future<void> addFileToModule(String moduleId, String fileName) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    module.files.add(fileName);
    await module.save();
  }

  static Future<void> addFileToSubmodule(String moduleId, String submoduleId, String fileName) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    final submodule = module.submodules.firstWhere((s) => s.id == submoduleId);
    submodule.files.add(fileName);
    await module.save();
  }
}
