import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hintText = 'Search',
    this.controller,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedTaupe),
      ),
    );
  }
}
