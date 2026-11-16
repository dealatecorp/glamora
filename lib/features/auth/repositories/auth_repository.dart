import '../models/auth_role.dart';
import '../models/auth_session.dart';
import '../../../data/repositories/repositories.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

abstract class AuthRepository {
  Future<AuthSession> loginAdmin({
    required String email,
    required String password,
  });

  Future<AuthSession> loginEmployee({
    required String employeeId,
    required String pin,
  });

  Future<AuthSession?> restoreSession();

  Future<void> logout();
}

class DemoAuthRepository implements AuthRepository {
  static const adminEmail = 'admin@glamora.demo';
  static const adminPassword = 'GLM001';
  static const demoEmployeeId = 'emp_01';
  static const demoEmployeePin = '2468';

  @override
  Future<AuthSession> loginAdmin({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (email.trim().toLowerCase() != adminEmail || password != adminPassword) {
      throw const AuthException('Invalid admin credentials.');
    }

    return AuthSession(
      id: 'admin_01',
      displayName: 'Glamora Admin',
      role: AuthRole.admin,
      email: email.trim(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AuthSession> loginEmployee({
    required String employeeId,
    required String pin,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final employee = DemoData.employees.where(
      (item) => item.id.toLowerCase() == employeeId.trim().toLowerCase(),
    ).firstOrNull;
    if (employee == null ||
        !employee.isActive ||
        DemoData.employeePins[employee.id] != pin) {
      throw const AuthException('Invalid employee credentials.');
    }

    return AuthSession(
      id: employee.id,
      displayName: employee.fullName,
      role: AuthRole.employee,
      employeeId: employee.id,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return null;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
