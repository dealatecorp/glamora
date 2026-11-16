import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';
import 'package:saloon_application/core/widgets/app_card.dart';
import 'package:saloon_application/core/widgets/empty_state.dart';
import 'package:saloon_application/core/widgets/loading_state.dart';
import 'package:saloon_application/core/widgets/section_header.dart';
import 'package:saloon_application/core/widgets/status_pill.dart';
import 'package:saloon_application/features/auth/models/auth_session.dart';
import 'package:saloon_application/models/salon_models.dart';
import 'dashboard_repository.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({
    super.key,
    required this.session,
    required this.repository,
    this.onOpenRevenue,
    this.onOpenPendingPayments,
    this.onOpenClients,
    this.onOpenVipClients,
    this.onBookAppointment,
    this.onAddClient,
    this.onAddService,
    this.onAddProduct,
  });

  final AuthSession session;
  final DashboardRepository repository;
  final VoidCallback? onOpenRevenue;
  final VoidCallback? onOpenPendingPayments;
  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenVipClients;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onAddClient;
  final VoidCallback? onAddService;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      session: session,
      future: repository.getDashboard(AuthRoleView.admin),
      isAdmin: true,
      onOpenRevenue: onOpenRevenue,
      onOpenPendingPayments: onOpenPendingPayments,
      onOpenClients: onOpenClients,
      onOpenVipClients: onOpenVipClients,
      onBookAppointment: onBookAppointment,
      onAddClient: onAddClient,
      onAddService: onAddService,
      onAddProduct: onAddProduct,
    );
  }
}

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.session,
    required this.future,
    required this.isAdmin,
    this.onTodayAppointments,
    this.onNextAppointment,
    this.onAssignedServices,
    this.onOpenRevenue,
    this.onOpenPendingPayments,
    this.onOpenClients,
    this.onOpenVipClients,
    this.onBookAppointment,
    this.onAddClient,
    this.onAddService,
    this.onAddProduct,
  });

  final AuthSession session;
  final Future<DashboardSnapshot> future;
  final bool isAdmin;
  final VoidCallback? onTodayAppointments;
  final VoidCallback? onNextAppointment;
  final VoidCallback? onAssignedServices;
  final VoidCallback? onOpenRevenue;
  final VoidCallback? onOpenPendingPayments;
  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenVipClients;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onAddClient;
  final VoidCallback? onAddService;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<DashboardSnapshot>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState(message: 'Preparing today’s dashboard');
            }
            if (snapshot.hasError) {
              return EmptyState(
                title: 'Unable to load today’s dashboard',
                subtitle: 'Please try again in a moment.',
                actionLabel: 'Try again',
                onAction: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => DashboardScaffold(
                      session: session,
                      future: future,
                      isAdmin: isAdmin,
                      onTodayAppointments: onTodayAppointments,
                      onNextAppointment: onNextAppointment,
                      onAssignedServices: onAssignedServices,
                      onOpenRevenue: onOpenRevenue,
                      onOpenPendingPayments: onOpenPendingPayments,
                      onOpenClients: onOpenClients,
                      onOpenVipClients: onOpenVipClients,
                      onBookAppointment: onBookAppointment,
                      onAddClient: onAddClient,
                      onAddService: onAddService,
                      onAddProduct: onAddProduct,
                    ),
                  ),
                ),
              );
            }
            final data = snapshot.data!;
            return _DashboardContent(
              session: session,
              data: data,
              isAdmin: isAdmin,
              onTodayAppointments: onTodayAppointments,
              onNextAppointment: onNextAppointment,
              onAssignedServices: onAssignedServices,
              onOpenRevenue: onOpenRevenue,
              onOpenPendingPayments: onOpenPendingPayments,
              onOpenClients: onOpenClients,
              onOpenVipClients: onOpenVipClients,
              onBookAppointment: onBookAppointment,
              onAddClient: onAddClient,
              onAddService: onAddService,
              onAddProduct: onAddProduct,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.session,
    required this.data,
    required this.isAdmin,
    this.onTodayAppointments,
    this.onNextAppointment,
    this.onAssignedServices,
    this.onOpenRevenue,
    this.onOpenPendingPayments,
    this.onOpenClients,
    this.onOpenVipClients,
    this.onBookAppointment,
    this.onAddClient,
    this.onAddService,
    this.onAddProduct,
  });

  final AuthSession session;
  final DashboardSnapshot data;
  final bool isAdmin;
  final VoidCallback? onTodayAppointments;
  final VoidCallback? onNextAppointment;
  final VoidCallback? onAssignedServices;
  final VoidCallback? onOpenRevenue;
  final VoidCallback? onOpenPendingPayments;
  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenVipClients;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onAddClient;
  final VoidCallback? onAddService;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final todayAppointmentsKey = GlobalKey();
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning, ${session.displayName.split(' ').first}',
            style: AppTextStyles.displaySmall,
          ),
          const SizedBox(height: 6),
          Text('Glamora', style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(
            '$date · ${isAdmin ? 'Admin overview' : 'Your studio day'}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 22),
          Text(
            isAdmin ? 'Today at a glance' : 'Your day at a glance',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            data: data,
            isAdmin: isAdmin,
            onTodayAppointments:
                onTodayAppointments ??
                () {
                  final target = todayAppointmentsKey.currentContext;
                  if (target != null) {
                    Scrollable.ensureVisible(
                      target,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  }
                },
            onNextAppointment: onNextAppointment,
            onAssignedServices: onAssignedServices,
            onOpenRevenue: onOpenRevenue,
            onOpenPendingPayments: onOpenPendingPayments,
            onOpenClients: onOpenClients,
            onOpenVipClients: onOpenVipClients,
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 12),
          _ActionGrid(
            isAdmin: isAdmin,
            onBookAppointment: onBookAppointment,
            onAddClient: onAddClient,
            onAddService: onAddService,
            onAddProduct: onAddProduct,
          ),
          const SizedBox(height: 24),
          KeyedSubtree(
            key: todayAppointmentsKey,
            child: SectionHeader(
              title: isAdmin ? 'Today’s appointments' : 'Upcoming appointment',
            ),
          ),
          const SizedBox(height: 12),
          if (data.appointments.isEmpty)
            const AppCard(child: EmptyState(title: 'No appointments today'))
          else
            ...data.appointments
                .take(isAdmin ? 3 : 1)
                .map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AppointmentPreview(appointment: appointment),
                  ),
                ),
          if (isAdmin) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    color: AppColors.champagneGold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The studio is on track for a focused, full day.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.data,
    required this.isAdmin,
    this.onTodayAppointments,
    this.onNextAppointment,
    this.onAssignedServices,
    this.onOpenRevenue,
    this.onOpenPendingPayments,
    this.onOpenClients,
    this.onOpenVipClients,
  });

  final DashboardSnapshot data;
  final bool isAdmin;
  final VoidCallback? onTodayAppointments;
  final VoidCallback? onNextAppointment;
  final VoidCallback? onAssignedServices;
  final VoidCallback? onOpenRevenue;
  final VoidCallback? onOpenPendingPayments;
  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenVipClients;

  @override
  Widget build(BuildContext context) {
    final metrics = isAdmin
        ? [
            (
              'Today’s appointments',
              '${data.appointments.length + 7}',
              Icons.calendar_today_rounded,
            ),
            (
              'Today’s revenue',
              '₹${data.todayRevenue.toStringAsFixed(0)}',
              Icons.payments_rounded,
            ),
            (
              'Pending payments',
              '₹${data.pendingPayments.toStringAsFixed(0)}',
              Icons.account_balance_wallet_rounded,
            ),
            ('Total clients', '${data.totalClients}', Icons.people_alt_rounded),
            ('VIP clients', '${data.vipClients}', Icons.star_rounded),
          ]
        : [
            ('Today’s appointments', '5', Icons.calendar_today_rounded),
            (
              'Next appointment',
              data.nextAppointment == null
                  ? 'None'
                  : _time(data.nextAppointment!.startAt),
              Icons.schedule_rounded,
            ),
            (
              'Assigned services',
              '${data.assignedServices}',
              Icons.cut_rounded,
            ),
            ('Pending payments', '2', Icons.account_balance_wallet_rounded),
          ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics
          .map(
            (metric) => SizedBox(
              width:
                  (MediaQuery.sizeOf(context).width - 50) /
                  (isAdmin && metrics.length == 5 ? 2 : 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: switch (metric.$1) {
                  'Today’s appointments' => onTodayAppointments,
                  'Next appointment' => onNextAppointment,
                  'Assigned services' => onAssignedServices,
                  'Today’s revenue' => onOpenRevenue,
                  'Pending payments' => onOpenPendingPayments,
                  'Total clients' => onOpenClients,
                  'VIP clients' => onOpenVipClients,
                  _ => null,
                },
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(metric.$3, color: AppColors.champagneGold, size: 20),
                      const SizedBox(height: 12),
                      Text(metric.$1, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 5),
                      Text(metric.$2, style: AppTextStyles.headlineMedium),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.isAdmin,
    this.onBookAppointment,
    this.onAddClient,
    this.onAddService,
    this.onAddProduct,
  });

  final bool isAdmin;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onAddClient;
  final VoidCallback? onAddService;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final actions = isAdmin
        ? [
            ('Book appointment', Icons.calendar_month_rounded),
            ('Add client', Icons.person_add_alt_1_rounded),
            ('Add service', Icons.cut_rounded),
            ('Add product', Icons.inventory_2_rounded),
          ]
        : [
            ('Book appointment', Icons.calendar_month_rounded),
            ('Add client', Icons.person_add_alt_1_rounded),
            ('Add service', Icons.cut_rounded),
            ('Add product', Icons.inventory_2_rounded),
          ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (action) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 50) / 2,
              child: OutlinedButton.icon(
                onPressed: switch (action.$1) {
                  'Book appointment' => onBookAppointment,
                  'Add client' => onAddClient,
                  'Add service' => onAddService,
                  'Add product' => onAddProduct,
                  _ => null,
                },
                icon: Icon(action.$2, size: 19),
                label: Text(action.$1),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AppointmentPreview extends StatelessWidget {
  const _AppointmentPreview({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.champagneGold,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.clientName, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${_time(appointment.startAt)} · ${appointment.services.first.serviceName}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          StatusPill(
            label: appointment.status.name,
            color: AppColors.cream,
            appointmentStatus: appointment.status,
          ),
        ],
      ),
    );
  }
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
