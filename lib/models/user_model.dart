import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Цей файл буде згенеровано автоматично [2]

@HiveType(typeId: 1) // Використовуємо ID 1, оскільки ID 0 зазвичай для модулів
class UserModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String avatarPath;

  UserModel({
    required this.name,
    required this.email,
    this.avatarPath = 'assets/images/default_avatar.png',
  });
}