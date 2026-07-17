import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 36, // Зменшено висоту для компактності
        child: TextField(
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search",
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            filled: true,
            fillColor: AppColors.cardBackground, // Темний фон[cite: 7, 10]
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white30),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // Зменшено радіус
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}