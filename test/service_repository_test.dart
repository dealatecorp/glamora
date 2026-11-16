import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  group('Service management', () {
    late DemoRepository repository;

    setUp(() {
      repository = DemoRepository();
    });

    test('searches by service name and category', () async {
      final nameMatches = await repository.searchServices('Balayage');
      final categoryMatches = await repository.searchServices('Nails');

      expect(nameMatches.map((service) => service.id), contains('svc_02'));
      expect(categoryMatches.map((service) => service.id), contains('svc_05'));
    });

    test('category filter returns only matching active services', () async {
      final services = await repository.getServicesByCategory(
        ServiceCategory.hair,
      );

      expect(services, isNotEmpty);
      expect(
        services.every((service) => service.category == ServiceCategory.hair),
        isTrue,
      );
      expect(services.every((service) => service.isActive), isTrue);
    });

    test('creates service with capabilities and validates fields', () async {
      final service = await repository.createService(
        name: 'Test Ritual',
        category: ServiceCategory.wellness,
        durationMinutes: 30,
        price: 500,
        description: 'A test service.',
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      );

      expect(service.assignedEmployeeIds, containsAll(['emp_01', 'emp_03']));
      expect(
        (await repository.getServiceById(service.id))!.category,
        ServiceCategory.wellness,
      );
      expect(
        () => repository.createService(
          name: '',
          category: ServiceCategory.face,
          durationMinutes: 0,
          price: -1,
          description: '',
          assignedEmployeeIds: const [],
        ),
        throwsA(isA<RepositoryException>()),
      );
    });

    test(
      'archive removes service from active catalogue and restore returns it',
      () async {
        await repository.archiveService('svc_01');
        expect(
          (await repository.getServices()).any(
            (service) => service.id == 'svc_01',
          ),
          isFalse,
        );
        expect(
          (await repository.getServices(
            includeArchived: true,
          )).any((service) => service.id == 'svc_01'),
          isTrue,
        );

        await repository.restoreService('svc_01');
        expect(
          (await repository.getServices()).any(
            (service) => service.id == 'svc_01',
          ),
          isTrue,
        );
      },
    );

    test('editing service does not rewrite appointment snapshots', () async {
      final originalSnapshot = DemoData.appointments
          .expand((appointment) => appointment.services)
          .firstWhere((service) => service.serviceId == 'svc_01');

      await repository.updateService(
        id: 'svc_01',
        name: 'Renamed Cut',
        category: ServiceCategory.hair,
        durationMinutes: 90,
        price: 2600,
        description: 'Updated catalogue entry.',
        assignedEmployeeIds: const ['emp_01'],
      );

      expect(originalSnapshot.historicalServiceName, 'Signature Cut & Finish');
      expect(originalSnapshot.historicalPrice, 1800);
    });
  });
}
