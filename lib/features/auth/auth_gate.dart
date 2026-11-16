import 'package:flutter/material.dart';

import '../../navigation/app_shell.dart';
import 'models/auth_role.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'state/auth_controller.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleStateChange);
    widget.controller.restoreSession();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleStateChange);
    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.controller.status;

    if (status == AuthStatus.initial || status == AuthStatus.loading) {
      return const _LoadingScreen();
    }

    if (status == AuthStatus.authenticated &&
        widget.controller.session != null) {
      return AppShell(
        session: widget.controller.session,
        authController: widget.controller,
      );
    }

    if (widget.controller.session == null &&
        status == AuthStatus.unauthenticated) {
      return RoleSelectionScreen(controller: widget.controller);
    }

    return LoginScreen(
      role: widget.controller.session?.role ?? AuthRole.admin,
      authController: widget.controller,
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
