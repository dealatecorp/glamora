import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/auth_role.dart';
import '../state/auth_controller.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Welcome to',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text('Glamora', style: AppTextStyles.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Choose the role you are signing in as.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 28),
              ...AuthRole.values.map(
                (role) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _RoleCard(
                    title: role.label,
                    subtitle: role.description,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                            role: role,
                            authController: controller,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: () {},
                disabled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                title == 'Admin'
                    ? Icons.admin_panel_settings_rounded
                    : Icons.badge_rounded,
                color: AppColors.champagneGold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 6),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedTaupe,
            ),
          ],
        ),
      ),
    );
  }
}
