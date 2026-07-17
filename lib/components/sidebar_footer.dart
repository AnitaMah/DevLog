import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/edit_profile_screen.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserModel>('userBox').listenable(),
      builder: (context, Box<UserModel> box, _) {
        // Виправлено: перевіряємо, чи є дані, перш ніж викликати getAt(0)
        final user = box.isNotEmpty 
            ? box.getAt(0) 
            : UserModel(name: "User", email: "", avatarPath: 'assets/images/default_avatar.png');
        
        final hasCustomAvatar = user!.avatarPath != 'assets/images/default_avatar.png';
        final file = File(user.avatarPath);
        final fileExists = hasCustomAvatar && file.existsSync();

        return InkWell(
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const EditProfileScreen())
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.cardBackground,
                  // Перевіряємо, чи файл фізично існує перед відображенням
                  backgroundImage: fileExists ? FileImage(file) : null,
                  child: !fileExists 
                      ? const Icon(Icons.person, color: Colors.white) 
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    user.name, 
                    style: AppTextStyles.cardTitle, 
                    overflow: TextOverflow.ellipsis
                  ),
                ),
                const Icon(Icons.settings, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}