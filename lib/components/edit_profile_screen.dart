import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Box<UserModel> usersBox = Hive.box<UserModel>('users');
  late UserModel _user;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    // Отримуємо користувача з Hive або створюємо нового
    _user = usersBox.getAt(0) ?? UserModel(
      name: "Default User",
      email: "default@example.com",
    );
    _nameController = TextEditingController(text: _user.name);
    _emailController = TextEditingController(text: _user.email);
    _selectedAvatar = _user.avatarPath != 'assets/images/default_avatar.png'
        ? File(_user.avatarPath)
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedAvatar = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    _user.name = _nameController.text;
    _user.email = _emailController.text;
    if (_selectedAvatar != null) {
      _user.avatarPath = _selectedAvatar!.path;
    }
    _user.save();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedAvatar != null
                        ? FileImage(_selectedAvatar!)
                        : AssetImage(_user.avatarPath) as ImageProvider,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}