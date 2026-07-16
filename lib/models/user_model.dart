import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String name; // Змінне поле

  @HiveField(1)
  String email; // Змінне поле

  @HiveField(2)
  String avatarPath; // Змінне поле

  UserModel({
    required this.name,
    required this.email,
    this.avatarPath = 'assets/images/default_avatar.png',
  });
}