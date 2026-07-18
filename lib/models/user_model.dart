import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String avatarPath;

  UserModel({
    required this.name,
    required this.email,
    this.avatarPath = 'assets/images/default_avatar.png',
  });
}
