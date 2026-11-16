import 'package:flutter/material.dart';
import 'package:saloon_application/features/auth/models/auth_session.dart';
import 'admin_home_screen.dart';
import 'dashboard_repository.dart';

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({
    super.key,
    required this.session,
    required this.repository,
    this.onOpenTodayAppointments,
    this.onOpenNextAppointment,
    this.onOpenAssignedServices,
    this.onOpenPendingPayments,
    this.onBookAppointment,
    this.onAddClient,
    this.onAddService,
    this.onAddProduct,
  });

  final AuthSession session;
  final DashboardRepository repository;
  final VoidCallback? onOpenTodayAppointments;
  final VoidCallback? onOpenNextAppointment;
  final VoidCallback? onOpenAssignedServices;
  final VoidCallback? onOpenPendingPayments;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onAddClient;
  final VoidCallback? onAddService;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      session: session,
      future: repository.getDashboard(
        AuthRoleView.employee,
        employeeId: session.employeeId,
      ),
      isAdmin: false,
      onTodayAppointments: onOpenTodayAppointments,
      onNextAppointment: onOpenNextAppointment,
      onAssignedServices: onOpenAssignedServices,
      onOpenPendingPayments: onOpenPendingPayments,
      onBookAppointment: onBookAppointment,
      onAddClient: onAddClient,
      onAddService: onAddService,
      onAddProduct: onAddProduct,
    );
  }
}
