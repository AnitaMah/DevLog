import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Контролер для зчитування тексту з клавіатури
  final _nameController = TextEditingController();
  final Box<UserModel> _userBox = Hive.box<UserModel>('userBox');

  @override
  void initState() {
    super.initState();
    // Попередньо заповнюємо поле поточним ім'ям з Hive
    final currentUser = _userBox.get('currentUser');
    if (currentUser != null) {
      _nameController.text = currentUser.name;
    }
  }

  void _saveProfile() {
    // Збереження введеного імені в Hive
    _userBox.put('currentUser', UserModel(
      name: _nameController.text,
      email: "anita@42.fr", 
    ));
    Navigator.pop(context); // Повернення на головний екран
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Edit Profile"), backgroundColor: AppColors.sidebarBackground),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              autofocus: true, // Автоматично відкриває клавіатуру
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Enter your name",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentPurple)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text("Save Name"),
            ),
          ],
        ),
      ),
    );
  }
}
