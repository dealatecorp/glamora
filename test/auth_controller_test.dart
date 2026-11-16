import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/features/auth/models/auth_role.dart';
import 'package:saloon_application/features/auth/repositories/auth_repository.dart';
import 'package:saloon_application/features/auth/services/auth_storage.dart';
import 'package:saloon_application/features/auth/state/auth_controller.dart';

void main() {
  group('AuthController demo authentication', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController(repository: DemoAuthRepository());
    });

    test('admin login succeeds with demo credentials', () async {
      await controller.login(
        role: AuthRole.admin,
        email: DemoAuthRepository.adminEmail,
        password: DemoAuthRepository.adminPassword,
      );

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.session, isNotNull);
      expect(controller.session!.role, AuthRole.admin);
    });

    test('employee login succeeds with demo credentials', () async {
      await controller.login(
        role: AuthRole.employee,
        employeeId: DemoAuthRepository.demoEmployeeId,
        pin: DemoAuthRepository.demoEmployeePin,
      );

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.session, isNotNull);
      expect(controller.session!.role, AuthRole.employee);
    });

    test('invalid admin credentials are rejected in demo mode', () async {
      await controller.login(
        role: AuthRole.admin,
        email: 'random@example.com',
        password: 'random-password',
      );

      expect(controller.status, AuthStatus.error);
      expect(controller.session, isNull);
      expect(controller.errorMessage, 'Invalid admin credentials.');
    });

    test(
      'restores the persisted role and session after a new controller is created',
      () async {
        final storage = MemoryAuthStorage();
        final firstController = AuthController(
          repository: DemoAuthRepository(),
          storage: storage,
        );
        await firstController.login(
          role: AuthRole.employee,
          employeeId: DemoAuthRepository.demoEmployeeId,
          pin: DemoAuthRepository.demoEmployeePin,
        );

        final restoredController = AuthController(
          repository: DemoAuthRepository(),
          storage: storage,
        );
        await restoredController.restoreSession();

        expect(restoredController.status, AuthStatus.authenticated);
        expect(restoredController.session?.role, AuthRole.employee);
        expect(
          restoredController.session?.employeeId,
          DemoAuthRepository.demoEmployeeId,
        );
      },
    );

    test('logout clears the persisted session', () async {
      final storage = MemoryAuthStorage();
      final loggedInController = AuthController(
        repository: DemoAuthRepository(),
        storage: storage,
      );
      await loggedInController.login(
        role: AuthRole.admin,
        email: DemoAuthRepository.adminEmail,
        password: DemoAuthRepository.adminPassword,
      );

      await loggedInController.logout(confirm: true);

      final restoredController = AuthController(
        repository: DemoAuthRepository(),
        storage: storage,
      );
      await restoredController.restoreSession();

      expect(loggedInController.status, AuthStatus.unauthenticated);
      expect(loggedInController.session, isNull);
      expect(restoredController.status, AuthStatus.unauthenticated);
      expect(restoredController.session, isNull);
    });
  });
}
