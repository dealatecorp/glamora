import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/auth_role.dart';
import '../repositories/auth_repository.dart';
import '../state/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.role, this.authController});

  final AuthRole role;
  final AuthController? authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isPinVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController? get _controller => widget.authController;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == AuthRole.admin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.espresso,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in',
                  style: AppTextStyles.displaySmall.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? 'Welcome back, admin.'
                      : 'Welcome back, team member.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 112,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _RolePanel(
                        label: 'Admin',
                        description: 'Manage your salon',
                        icon: Icons.admin_panel_settings_outlined,
                        selected: isAdmin,
                        onTap: () {
                          if (!isAdmin) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  role: AuthRole.admin,
                                  authController: _controller,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      _RolePanel(
                        label: 'Employee',
                        description: 'Access your schedule',
                        icon: Icons.badge_outlined,
                        selected: !isAdmin,
                        onTap: () {
                          if (isAdmin) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  role: AuthRole.employee,
                                  authController: _controller,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isAdmin) ...[
                  _TextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email.';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _TextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.mutedTaupe,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Demo: ${DemoAuthRepository.adminEmail} / '
                    '${DemoAuthRepository.adminPassword}',
                    style: AppTextStyles.bodySmall,
                  ),
                ] else ...[
                  _TextField(
                    label: 'Employee ID',
                    controller: _employeeIdController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your Employee ID.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _TextField(
                    label: 'PIN',
                    controller: _pinController,
                    obscureText: !_isPinVisible,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _isPinVisible = !_isPinVisible),
                      icon: Icon(
                        _isPinVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.mutedTaupe,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your PIN.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Demo: ${DemoAuthRepository.demoEmployeeId} / '
                    '${DemoAuthRepository.demoEmployeePin}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Login',
                    isLoading: _isLoading,
                    disabled: _isLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final controller = _controller;
    if (controller == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication is unavailable.';
      });
      return;
    }

    try {
      await controller.login(
        role: widget.role,
        email: _emailController.text,
        password: _passwordController.text,
        employeeId: _employeeIdController.text,
        pin: _pinController.text,
      );

      if (!mounted) return;

      if (controller.status == AuthStatus.authenticated) {
        Navigator.of(context).pushNamedAndRemoveUntil('/app', (route) => false);
        return;
      }

      setState(() {
        _errorMessage = controller.errorMessage ?? 'Authentication failed.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _RolePanel extends StatelessWidget {
  const _RolePanel({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 218,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? AppColors.champagneGold : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.champagneGold : AppColors.mutedTaupe),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: AppTextStyles.labelLarge.copyWith(color: selected ? AppColors.espresso : AppColors.secondary)), const SizedBox(height: 4), Text(description, style: AppTextStyles.caption)])),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.champagneGold, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.champagneGold,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
