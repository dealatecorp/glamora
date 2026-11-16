import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_radius.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = disabled || isLoading ? null : onPressed;

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled
              ? AppColors.border
              : AppColors.champagneGold,
          foregroundColor: AppColors.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.buttonText,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.buttonText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
