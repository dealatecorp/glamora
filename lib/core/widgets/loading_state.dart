import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message = 'Loading salon details',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.champagneGold),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
