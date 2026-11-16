import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'clients, appointments, and services stay shared and persistent',
    () async {
      SharedPreferences.setMockInitialValues({});
      final adminRepository = DemoRepository();
      final employeeRepository = DemoRepository();

      final client = await adminRepository.createClient(
        name: 'Shared Demo Client',
        phone: '+91 90000 12345',
        email: 'shared.demo@example.com',
      );
      expect(
        (await employeeRepository.getClientById(client.id))?.fullName,
        'Shared Demo Client',
      );

      final appointment = await employeeRepository.createAppointment(
        clientId: client.id,
        clientName: client.fullName,
        startAt: DateTime(2026, 9, 23, 10),
        services: const [
          AppointmentService(
            id: 'shared_booking_service',
            serviceId: 'svc_01',
            serviceName: 'Signature Cut & Finish',
            durationMinutes: 60,
            price: 1800,
            employeeId: 'emp_01',
            employeeName: 'Aarohi Mehta',
          ),
        ],
      );
      expect(
        (await adminRepository.getAppointmentById(appointment.id))?.clientId,
        client.id,
      );

      final adminServices = await adminRepository.getServices();
      final employeeCatalog = await employeeRepository.getServices();
      final serviceIds = adminServices.map((service) => service.id).toSet();
      final employeeServices = employeeCatalog.where(
        (service) => service.assignedEmployeeIds.contains('emp_01'),
      );
      expect(employeeCatalog.map((service) => service.id).toSet(), serviceIds);
      expect(employeeServices, isNotEmpty);
      expect(
        employeeServices.every((service) => serviceIds.contains(service.id)),
        isTrue,
      );

      DemoData.appointments.removeWhere((item) => item.id == appointment.id);
      final restartedRepository = DemoRepository();
      expect(
        (await restartedRepository.getAppointmentById(
          appointment.id,
        ))?.clientId,
        client.id,
      );
    },
  );
}
