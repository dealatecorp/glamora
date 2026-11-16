import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/models/salon_models.dart';
import 'package:saloon_application/features/reports/domain/revenue_service.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.appointments,
    required this.todayRevenue,
    required this.pendingPayments,
    required this.totalClients,
    required this.vipClients,
    required this.assignedServices,
  });

  final List<Appointment> appointments;
  final double todayRevenue;
  final double pendingPayments;
  final int totalClients;
  final int vipClients;
  final int assignedServices;

  Appointment? get nextAppointment {
    final now = DateTime.now();
    final upcoming =
        appointments
            .where((appointment) => appointment.startAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}

abstract class DashboardRepository {
  Future<DashboardSnapshot> getDashboard(
    AuthRoleView role, {
    String? employeeId,
  });
}

enum AuthRoleView { admin, employee }

class DemoDashboardRepository implements DashboardRepository {
  DemoDashboardRepository({DemoRepository? repository})
    : _repository = repository ?? DemoRepository();

  final DemoRepository _repository;

  @override
  Future<DashboardSnapshot> getDashboard(
    AuthRoleView role, {
    String? employeeId,
  }) async {
    final allAppointments = await _repository.getAppointments();
    final appointments = role == AuthRoleView.employee && employeeId != null
        ? allAppointments
              .where(
                (appointment) => appointment.services.any(
                  (service) => service.employeeId == employeeId,
                ),
              )
              .where(
                (appointment) =>
                    appointment.status != AppointmentStatus.cancelled &&
                    appointment.status != AppointmentStatus.noShow,
              )
              .toList()
        : allAppointments;
    final clients = await _repository.getClients();
    final services = await _repository.getServices();

    final now = DateTime.now();
    final revenue = await RevenueService(_repository).summary(
      RevenueFilter(start: DateTime(now.year, now.month, now.day), end: now),
    );

    final assignedServices = employeeId == null
        ? 0
        : services
              .where((service) => service.assignedEmployeeIds.contains(employeeId))
              .length;

    return DashboardSnapshot(
      appointments: appointments,
      todayRevenue: revenue.received,
      pendingPayments: revenue.pending,
      totalClients: clients.length < 248 ? 248 : clients.length,
      vipClients: 36,
      assignedServices: role == AuthRoleView.employee
          ? assignedServices
          : services.length,
    );
  }
}
