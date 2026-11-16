import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/appointments/domain/appointment_scheduler.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  AppointmentDraftService draft({
    required String employeeId,
    int duration = 60,
    String serviceId = 'svc_test',
  }) {
    return AppointmentDraftService(
      service: Service(
        id: serviceId,
        name: 'Test service',
        description: '',
        durationMinutes: duration,
        price: 100,
        category: ServiceCategory.hair,
        isActive: true,
        createdAt: DateTime(2025),
        assignedEmployeeIds: [employeeId],
      ),
      employeeId: employeeId,
      employeeName: employeeId,
    );
  }

  test('rejects appointments outside salon hours and during breaks', () {
    final early = AppointmentScheduler.checkAvailability(
      startAt: DateTime(2026, 9, 20, 8),
      services: [draft(employeeId: 'emp_01')],
      appointments: const [],
    );
    final breakOverlap = AppointmentScheduler.checkAvailability(
      startAt: DateTime(2026, 9, 20, 12, 30),
      services: [draft(employeeId: 'emp_01')],
      appointments: const [],
    );

    expect(early.isAvailable, isFalse);
    expect(breakOverlap.isAvailable, isFalse);
  });

  test(
    'prevents conflicts for the same employee but allows another employee',
    () {
      final existing = Appointment(
        id: 'existing',
        clientId: 'client',
        clientName: 'Client',
        startAt: DateTime(2026, 9, 20, 10),
        endAt: DateTime(2026, 9, 20, 11),
        status: AppointmentStatus.confirmed,
        services: [
          AppointmentService(
            id: 'snapshot',
            serviceId: 'svc_test',
            serviceName: 'Test service',
            durationMinutes: 60,
            price: 100,
            employeeId: 'emp_01',
            employeeName: 'Employee 1',
          ),
        ],
        createdAt: DateTime(2026),
      );

      final conflict = AppointmentScheduler.checkAvailability(
        startAt: DateTime(2026, 9, 20, 10, 30),
        services: [draft(employeeId: 'emp_01')],
        appointments: [existing],
      );
      final available = AppointmentScheduler.checkAvailability(
        startAt: DateTime(2026, 9, 20, 10, 30),
        services: [draft(employeeId: 'emp_02')],
        appointments: [existing],
      );

      expect(conflict.isAvailable, isFalse);
      expect(available.isAvailable, isTrue);
    },
  );

  test(
    'calculates multi-service duration and repository status transitions',
    () async {
      final repository = DemoRepository();
      final services = [
        AppointmentService(
          id: 'booking_1',
          serviceId: 'svc_01',
          serviceName: 'Signature Cut & Finish',
          durationMinutes: 60,
          price: 1800,
          employeeId: 'emp_01',
          employeeName: 'Aarohi Mehta',
        ),
      ];
      final appointment = await repository.createAppointment(
        clientId: 'client_03',
        clientName: 'Aditi Shah',
        startAt: DateTime(2026, 9, 20, 15),
        services: services,
        reminder: null,
      );

      expect(appointment.endAt, DateTime(2026, 9, 20, 16));
      expect(
        (await repository.completeAppointment(appointment.id)).status,
        AppointmentStatus.completed,
      );
      expect(
        (await repository.markNoShow('appt_02')).status,
        AppointmentStatus.noShow,
      );
      expect(
        (await repository.cancelAppointment(
          id: 'appt_01',
          reason: 'Client requested',
          cancelledBy: 'admin',
        )).cancellationReason,
        'Client requested',
      );
    },
  );
}
