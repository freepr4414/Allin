class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const User({required this.id, required this.name, required this.email, required this.role});
}

enum UserRole { admin, manager, staff }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return '관리자';
      case UserRole.manager:
        return '매니저';
      case UserRole.staff:
        return '직원';
    }
  }
}
