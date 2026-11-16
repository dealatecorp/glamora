import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';
import 'package:saloon_application/core/widgets/app_card.dart';
import 'package:saloon_application/core/widgets/empty_state.dart';
import 'package:saloon_application/core/widgets/primary_button.dart';
import 'package:saloon_application/core/widgets/search_field.dart';
import 'package:saloon_application/features/auth/models/auth_role.dart';
import 'package:saloon_application/features/auth/models/auth_session.dart';
import 'package:saloon_application/features/auth/state/auth_controller.dart';
import 'package:saloon_application/features/auth/screens/role_selection_screen.dart';
import 'package:saloon_application/features/home/admin_home_screen.dart';
import 'package:saloon_application/features/home/employee_home_screen.dart';
import 'package:saloon_application/features/home/dashboard_repository.dart';
import 'package:saloon_application/features/more/more_screen.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/clients/screens/client_list_screen.dart';
import 'package:saloon_application/features/clients/screens/client_form_screen.dart';
import 'package:saloon_application/features/services/screens/service_list_screen.dart';
import 'package:saloon_application/features/services/screens/service_form_screen.dart';
import 'package:saloon_application/features/appointments/screens/appointment_list_screen.dart';
import 'package:saloon_application/features/appointments/screens/appointment_booking_screen.dart';
import 'package:saloon_application/features/appointments/screens/appointment_details_screen.dart';
import 'package:saloon_application/features/payments/screens/payment_list_screen.dart';
import 'package:saloon_application/features/employees/screens/employee_list_screen.dart';
import 'package:saloon_application/features/employees/screens/employee_details_screen.dart';
import 'package:saloon_application/features/inventory/screens/inventory_list_screen.dart';
import 'package:saloon_application/features/inventory/screens/inventory_form_screen.dart';
import 'package:saloon_application/features/reports/screens/revenue_screen.dart';
import 'package:saloon_application/features/reports/screens/reports_screen.dart';
import 'package:saloon_application/features/more/screens/customer_qr_screen.dart';
import 'package:saloon_application/features/more/screens/studio_screens.dart';
import 'package:saloon_application/models/salon_models.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.session, this.authController});

  final AuthSession? session;
  final AuthController? authController;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.calendar_month_rounded, label: 'Appointments'),
    _NavItem(icon: Icons.people_alt_rounded, label: 'Clients'),
    _NavItem(icon: Icons.cut_rounded, label: 'Services'),
    _NavItem(icon: Icons.more_horiz_rounded, label: 'More'),
  ];

  List<Widget> _screens() {
    final session = widget.session;
    final dashboardRepository = DemoDashboardRepository();
    return [
      if (session?.isEmployee ?? false)
        EmployeeHomeScreen(
          session: session!,
          repository: dashboardRepository,
          onOpenTodayAppointments: _openEmployeeAppointments,
          onOpenNextAppointment: _openEmployeeNextAppointment,
          onOpenAssignedServices: _openEmployeeServices,
          onOpenPendingPayments: _openPendingPayments,
          onBookAppointment: _openAppointmentBooking,
          onAddClient: _openClientForm,
          onAddService: _openServiceForm,
          onAddProduct: _openProductForm,
        )
      else
        AdminHomeScreen(
          session: session ?? _fallbackSession,
          repository: dashboardRepository,
          onOpenRevenue: session?.isAdmin == true ? _openRevenue : null,
          onOpenPendingPayments: session?.isAdmin == true
              ? _openPendingPayments
              : null,
          onOpenClients: _openClients,
          onOpenVipClients: _openVipClients,
          onBookAppointment: session?.isAdmin == true
              ? _openAppointmentBooking
              : null,
          onAddClient: session?.isAdmin == true ? _openClientForm : null,
          onAddService: session?.isAdmin == true ? _openServiceForm : null,
          onAddProduct: session?.isAdmin == true ? _openProductForm : null,
        ),
      AppointmentListScreen(session: session, repository: DemoRepository()),
      ClientListScreen(session: session, repository: DemoRepository()),
      ServiceListScreen(session: session, repository: DemoRepository()),
      MoreScreen(
        session: session ?? _fallbackSession,
        onLogout: _logoutAndReturnToAuth,
        onOpenPayments: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentListScreen(
              session: session ?? _fallbackSession,
              repository: DemoRepository(),
            ),
          ),
        ),
        onOpenEmployees: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmployeeListScreen(repository: DemoRepository()),
          ),
        ),
        onOpenOwnEmployee: session?.isEmployee == true
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmployeeDetailsScreen(
                    employeeId: session!.employeeId!,
                    repository: DemoRepository(),
                    session: session,
                  ),
                ),
              )
            : null,
        onOpenInventory: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InventoryListScreen(
              repository: DemoRepository(),
              session: session ?? _fallbackSession,
            ),
          ),
        ),
        onOpenRevenue: session?.isAdmin == true
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RevenueScreen(repository: DemoRepository()),
                ),
              )
            : null,
        onOpenReports: session?.isAdmin == true
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportsScreen(repository: DemoRepository()),
                ),
              )
            : null,
        onOpenServices: session?.isAdmin == true ? _openServices : null,
        onOpenBusinessProfile: _openBusinessProfile,
        onOpenBusinessHours: _openBusinessHours,
        onOpenBreaks: _openBreaks,
        onOpenApplicationSettings: _openApplicationSettings,
        onOpenCustomerQr: _openCustomerQr,
      ),
    ];
  }

  void _openAppointmentBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentBookingScreen(
          repository: DemoRepository(),
          session: widget.session,
        ),
      ),
    );
  }

  void _openClientForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(repository: DemoRepository()),
      ),
    );
  }

  void _openServiceForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceFormScreen(repository: DemoRepository()),
      ),
    );
  }

  void _openProductForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormScreen(
          repository: DemoRepository(),
          performedBy: widget.session?.displayName ?? 'Salon User',
        ),
      ),
    );
  }

  void _openRevenue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RevenueScreen(repository: DemoRepository()),
      ),
    );
  }

  void _openPendingPayments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentListScreen(
          session: widget.session ?? _fallbackSession,
          repository: DemoRepository(),
          initialFilter: 'Pending',
        ),
      ),
    );
  }

  void _openClients() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientListScreen(
          session: widget.session,
          repository: DemoRepository(),
        ),
      ),
    );
  }

  void _openVipClients() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientListScreen(
          session: widget.session,
          repository: DemoRepository(),
          initialShowVipOnly: true,
        ),
      ),
    );
  }

  void _openServices() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceListScreen(
          session: widget.session,
          repository: DemoRepository(),
        ),
      ),
    );
  }

  void _openEmployeeAppointments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentListScreen(
          session: widget.session,
          repository: DemoRepository(),
        ),
      ),
    );
  }

  Future<void> _openEmployeeNextAppointment() async {
    final employeeId = widget.session?.employeeId;
    if (employeeId == null) return;

    final appointments = await DemoRepository().getAppointments();
    if (!mounted) return;
    final now = DateTime.now();
    final upcoming =
        appointments
            .where(
              (appointment) =>
                  appointment.startAt.isAfter(now) &&
                  appointment.status != AppointmentStatus.cancelled &&
                  appointment.status != AppointmentStatus.completed &&
                  appointment.status != AppointmentStatus.noShow &&
                  appointment.services.any(
                    (service) => service.employeeId == employeeId,
                  ),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (upcoming.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          content: EmptyState(title: 'No upcoming appointment.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsScreen(
          appointmentId: upcoming.first.id,
          repository: DemoRepository(),
          session: widget.session,
        ),
      ),
    );
  }

  void _openEmployeeServices() {
    final employeeId = widget.session?.employeeId;
    if (employeeId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceListScreen(
          session: widget.session,
          repository: DemoRepository(),
          employeeId: employeeId,
        ),
      ),
    );
  }

  void _openBusinessProfile() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BusinessProfileScreen(repository: DemoRepository()),
    ),
  );

  void _openBusinessHours() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BusinessHoursScreen(repository: DemoRepository()),
    ),
  );

  void _openBreaks() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SalonBreaksScreen(repository: DemoRepository()),
    ),
  );

  void _openApplicationSettings() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ApplicationSettingsScreen(repository: DemoRepository()),
    ),
  );

  void _openCustomerQr() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CustomerQrScreen(
        repository: DemoRepository(),
        session: widget.session ?? _fallbackSession,
      ),
    ),
  );

  Future<void> _logoutAndReturnToAuth() async {
    final controller = widget.authController;
    if (controller == null) return;

    await controller.logout(confirm: true);
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(controller: controller),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _screens()),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (value) => setState(() => _selectedIndex = value),
          items: _items
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

final _fallbackSession = AuthSession(
  id: 'demo',
  displayName: 'Salon User',
  role: AuthRole.admin,
  createdAt: DateTime(2024),
);

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.displaySmall),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coming in next module', style: AppTextStyles.titleLarge),
                const SizedBox(height: 10),
                Text(
                  'This foundation screen is ready for the next workflow prompt.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Review roadmap', onPressed: () {}),
              ],
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.center,
            child: SearchField(hintText: 'Search $title'),
          ),
        ],
      ),
    );
  }
}
