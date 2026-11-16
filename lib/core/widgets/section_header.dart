import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.trailing,
  });

  final String title;
  final String? action;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final actionLabel = action ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineMedium),
        action != null
            ? GestureDetector(
                onTap: () {},
                child: Text(
                  actionLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.champagneGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : (trailing ?? const SizedBox.shrink()),
      ],
    );
  }
}
