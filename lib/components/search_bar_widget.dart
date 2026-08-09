import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const SearchBarWidget({super.key, this.onChanged, this.focusNode});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 36, // Зменшено висоту для компактності
        child: TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          onChanged: (value) {
            widget.onChanged?.call(value);
            setState(() {});
          },
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Search modules and notes",
            hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            filled: true,
            fillColor: AppColors.cardBackground, // Темний фон[cite: 7, 10]
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textDisabled),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, size: 14, color: AppColors.textDisabled),
                    onPressed: _clear,
                  ),
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
