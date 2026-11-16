import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/clients/domain/client_rules.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Client management', () {
    late DemoRepository repository;

    setUp(() {
      repository = DemoRepository();
    });

    test('searches clients by email and service history', () async {
      final emailMatches = await repository.searchClients('meher@example.com');
      final serviceMatches = await repository.searchClients('Balayage');

      expect(emailMatches.map((client) => client.id), contains('client_02'));
      expect(serviceMatches.map((client) => client.id), contains('client_02'));
    });

    test('rejects duplicate active mobile numbers', () async {
      expect(
        () => repository.createClient(
          name: 'Duplicate',
          phone: '+91 98765 00123',
        ),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('supports archive, restore, and XP balance changes', () async {
      final client = await repository.createClient(
        name: 'Test Client',
        phone: '+91 90000 90909',
      );

      await repository.updateLoyaltyXp(client.id, 40);
      expect((await repository.getClientById(client.id))!.loyaltyPoints, 40);

      await repository.archiveClient(client.id);
      expect((await repository.getClientById(client.id))!.isArchived, isTrue);

      await repository.restoreClient(client.id);
      expect((await repository.getClientById(client.id))!.isArchived, isFalse);
    });

    test('permanently deletes a client', () async {
      final client = await repository.createClient(
        name: 'Delete Client',
        phone: '+91 90000 90910',
      );

      await repository.deleteClient(client.id);

      expect(await repository.getClientById(client.id), isNull);
      expect(
        (await repository.getClients()).map((client) => client.id),
        isNot(contains(client.id)),
      );
    });

    test(
      'restores a newly created client for a fresh repository instance',
      () async {
        final firstRepository = DemoRepository();
        final created = await firstRepository.createClient(
          name: 'Restarted Client',
          phone: '+91 90000 90999',
        );

        DemoData.clients.removeWhere((client) => client.id == created.id);

        final restartedRepository = DemoRepository();
        final restored = await restartedRepository.getClientById(created.id);

        expect(restored?.fullName, 'Restarted Client');
        DemoData.clients.removeWhere((client) => client.id == created.id);
      },
    );

    test('VIP requires three completed and paid visits', () {
      final appointments = [
        for (var index = 0; index < 3; index++)
          Appointment(
            id: 'appointment_$index',
            clientId: 'client_test',
            clientName: 'Test Client',
            startAt: DateTime(2025, 1, index + 1),
            endAt: DateTime(2025, 1, index + 1, 1),
            status: AppointmentStatus.completed,
            services: const [],
            createdAt: DateTime(2025, 1, index + 1),
          ),
      ];
      final history = ClientHistory(
        appointments: appointments,
        payments: [
          for (var index = 0; index < 3; index++)
            Payment(
              id: 'payment_$index',
              appointmentId: 'appointment_$index',
              clientId: 'client_test',
              amount: 100,
              method: PaymentMethod.card,
              status: PaymentStatus.paid,
              createdAt: DateTime(2025, 1, index + 1),
            ),
        ],
        invoices: const [],
      );

      expect(ClientRules.completedPaidVisitCount(history), 3);
      expect(ClientRules.isVipFromHistory(history), isTrue);
    });
  });
}
