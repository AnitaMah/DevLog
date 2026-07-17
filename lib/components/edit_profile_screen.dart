import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Box<UserModel> usersBox = Hive.box<UserModel>('userBox');
  late UserModel _user;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    
    // БЕЗПЕЧНА ІНІЦІАЛІЗАЦІЯ:
    // Перевіряємо, чи є вже дані в базі. Якщо немає — створюємо дефолтний об'єкт.
    if (usersBox.isNotEmpty) {
      _user = usersBox.getAt(0)!;
    } else {
      _user = UserModel(name: "User", email: "user@example.com");
      // Одразу додаємо до боксу, щоб гарантувати наявність індексу 0
      usersBox.add(_user);
    }

    _nameController = TextEditingController(text: _user.name);
    _emailController = TextEditingController(text: _user.email);
    
    // Перевіряємо, чи файл існує за шляхом
    _selectedAvatar = (_user.avatarPath.isNotEmpty && _user.avatarPath != 'assets/images/default_avatar.png') 
        ? File(_user.avatarPath) 
        : null;
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedAvatar = File(pickedFile.path));
  }

  void _saveProfile() {
    _user.name = _nameController.text;
    _user.email = _emailController.text;
    if (_selectedAvatar != null) _user.avatarPath = _selectedAvatar!.path;
    
    // Використовуємо .save(), оскільки UserModel наслідується від HiveObject
    _user.save();
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.cardBackground,
                backgroundImage: _selectedAvatar != null ? FileImage(_selectedAvatar!) : null,
                child: _selectedAvatar == null ? const Icon(Icons.person, size: 50, color: Colors.white30) : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildTextField(_nameController, "Name"),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(_emailController, "Email"),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
