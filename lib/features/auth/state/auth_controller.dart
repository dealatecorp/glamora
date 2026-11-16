import 'package:flutter/foundation.dart';

import '../models/auth_role.dart';
import '../models/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  AuthController({required this._repository, AuthStorage? storage})
    : _storage = storage ?? MemoryAuthStorage();

  final AuthRepository _repository;
  final AuthStorage _storage;

  AuthStatus _status = AuthStatus.initial;
  AuthSession? _session;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _session != null;

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final storedSession = await _storage.loadSession();
      if (storedSession == null) {
        _session = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final freshSession = await _repository.restoreSession();
      if (freshSession == null) {
        _session = storedSession;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }

      _session = freshSession;
      _status = AuthStatus.authenticated;
      await _storage.saveSession(_session!);
      notifyListeners();
    } catch (_) {
      _session = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Your session could not be restored.';
      notifyListeners();
    }
  }

  Future<void> login({
    required AuthRole role,
    String? email,
    String? password,
    String? employeeId,
    String? pin,
  }) async {
    final isValid = _validate(role, email, password, employeeId, pin);
    if (!isValid) {
      _status = AuthStatus.error;
      notifyListeners();
      return;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (role == AuthRole.admin) {
        final nextSession = await _repository.loginAdmin(
          email: email!.trim(),
          password: password!,
        );
        _session = nextSession;
        await _storage.saveSession(nextSession);
      } else {
        final nextSession = await _repository.loginEmployee(
          employeeId: employeeId!.trim(),
          pin: pin!,
        );
        _session = nextSession;
        await _storage.saveSession(nextSession);
      }

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    } on AuthException catch (exception) {
      _session = null;
      _status = AuthStatus.error;
      _errorMessage = exception.message;
      notifyListeners();
    } catch (_) {
      _session = null;
      _status = AuthStatus.error;
      _errorMessage = 'Something went wrong while logging in.';
      notifyListeners();
    }
  }

  Future<void> logout({bool confirm = false}) async {
    if (!confirm) {
      await _storage.clearSession();
      _status = AuthStatus.unauthenticated;
      _session = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _repository.logout();
      await _storage.clearSession();
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Unable to log out right now.';
      notifyListeners();
      return;
    }

    _session = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  bool _validate(
    AuthRole role,
    String? email,
    String? password,
    String? employeeId,
    String? pin,
  ) {
    if (role == AuthRole.admin) {
      if (email == null || email.trim().isEmpty) {
        _errorMessage = 'Please enter your email.';
        return false;
      }
      if (!email.contains('@')) {
        _errorMessage = 'Please enter a valid email.';
        return false;
      }
      if (password == null || password.isEmpty) {
        _errorMessage = 'Please enter your password.';
        return false;
      }
    }

    if (role == AuthRole.employee) {
      if (employeeId == null || employeeId.trim().isEmpty) {
        _errorMessage = 'Please enter your Employee ID.';
        return false;
      }
      if (pin == null || pin.isEmpty) {
        _errorMessage = 'Please enter your PIN.';
        return false;
      }
    }

    _errorMessage = null;
    return true;
  }
}
