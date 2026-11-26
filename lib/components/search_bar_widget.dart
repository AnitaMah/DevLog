import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A glass-surfaced search field, matching the Home quick-capture bar's
/// look (see [GlassPanel] in `home_content.dart`) rather than a flat
/// Material text field.
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: SizedBox(
          height: 44,
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textDisabled),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 14, color: AppColors.textDisabled),
                      onPressed: _clear,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
