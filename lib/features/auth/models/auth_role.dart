enum AuthRole { admin, employee }

extension AuthRoleX on AuthRole {
  String get label {
    switch (this) {
      case AuthRole.admin:
        return 'Admin';
      case AuthRole.employee:
        return 'Employee';
    }
  }

  String get description {
    switch (this) {
      case AuthRole.admin:
        return 'Manage your salon, team, finances and operations.';
      case AuthRole.employee:
        return 'Manage appointments, clients and assigned services.';
    }
  }
}
