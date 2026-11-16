import 'auth_role.dart';

class AuthSession {
  const AuthSession({
    required this.id,
    required this.displayName,
    required this.role,
    this.email,
    this.employeeId,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final AuthRole role;
  final String? email;
  final String? employeeId;
  final DateTime createdAt;

  bool get isAdmin => role == AuthRole.admin;
  bool get isEmployee => role == AuthRole.employee;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'role': role.name,
      'email': email,
      'employeeId': employeeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String? ?? AuthRole.admin.name;

    return AuthSession(
      id: json['id'] as String? ?? 'unknown',
      displayName: json['displayName'] as String? ?? 'Salon User',
      role: AuthRole.values.firstWhere(
        (value) => value.name == roleName,
        orElse: () => AuthRole.admin,
      ),
      email: json['email'] as String?,
      employeeId: json['employeeId'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
