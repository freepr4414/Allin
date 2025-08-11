import 'unified_menu_models.dart';

enum UserType {
  admin,
  staff,
  member,
  guest;

  String get displayName {
    switch (this) {
      case UserType.admin:
        return '관리자';
      case UserType.staff:
        return '직원';
      case UserType.member:
        return '회원';
      case UserType.guest:
        return '게스트';
    }
  }
}

enum UserStatus {
  active,
  inactive,
  suspended,
  deleted;

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return '활성';
      case UserStatus.inactive:
        return '비활성';
      case UserStatus.suspended:
        return '정지';
      case UserStatus.deleted:
        return '삭제';
    }
  }
}

class User {
  final String id;
  final String username;
  final String name;
  final String? email;
  final String? phone;
  final UserType type;
  final UserStatus status;
  final PermissionLevel permissionLevel; // 추가: 5단계 권한 레벨
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    this.phone,
    required this.type,
    required this.status,
    required this.permissionLevel,
    this.createdAt,
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? phone,
    UserType? type,
    UserStatus? status,
    PermissionLevel? permissionLevel,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      status: status ?? this.status,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, name: $name, type: $type, status: $status, permissionLevel: $permissionLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
