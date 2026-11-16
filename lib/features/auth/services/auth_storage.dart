import '../models/auth_session.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthStorage {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> loadSession();
  Future<void> clearSession();
}

class SharedPreferencesAuthStorage implements AuthStorage {
  static const _sessionKey = 'glamora.auth_session';
  Future<SharedPreferences>? _preferences;

  Future<SharedPreferences> get _prefs =>
      _preferences ??= SharedPreferences.getInstance();

  @override
  Future<void> saveSession(AuthSession session) async {
    final preferences = await _prefs;
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<AuthSession?> loadSession() async {
    final preferences = await _prefs;
    final value = preferences.getString(_sessionKey);
    if (value == null || value.isEmpty) return null;

    try {
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic>) return null;
      return AuthSession.fromJson(json);
    } on FormatException {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    final preferences = await _prefs;
    await preferences.remove(_sessionKey);
  }
}

class MemoryAuthStorage implements AuthStorage {
  AuthSession? _session;

  @override
  Future<void> saveSession(AuthSession session) async {
    _session = session;
  }

  @override
  Future<AuthSession?> loadSession() async {
    return _session;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }
}
