<<<<<<< HEAD
class Manager {
  final String managerId;
  final String password;
  final String managerName;
  final String? email;
  final String? phone;
  final String? role;
  final DateTime createdAt;
  final DateTime updatedAt;

  Manager({
    required this.managerId,
    required this.password,
    required this.managerName,
    this.email,
    this.phone,
    this.role,
=======
/// 관리자 정보 모델
/// 백엔드 manager_table과 매핑되는 데이터 모델입니다.
class Manager {
  final String managerId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Manager({
    required this.managerId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
    required this.createdAt,
    required this.updatedAt,
  });

<<<<<<< HEAD
  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      managerId: json['manager_id']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      managerName: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manager_id': managerId,
      'password': password,
      'manager_name': managerName,
=======
  /// JSON에서 Manager 객체 생성
  factory Manager.fromJson(Map<String, dynamic> json) {
    // role 필드는 숫자나 문자열로 올 수 있으므로 안전하게 처리
    String roleValue;
    final roleData = json['role'];
    if (roleData is int) {
      roleValue = roleData.toString();
    } else if (roleData is String) {
      roleValue = roleData;
    } else {
      roleValue = '1'; // 기본값
    }

    return Manager(
      managerId: json['manager_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: roleValue,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Manager 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'manager_id': managerId,
      'name': name,
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
<<<<<<< HEAD
    return 'Manager(managerId: $managerId, managerName: $managerName, role: $role)';
=======
    return 'Manager(managerId: $managerId, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manager && other.managerId == managerId;
  }

  @override
  int get hashCode => managerId.hashCode;
}

/// 로그인 요청 모델
class LoginRequest {
  final String managerId;
  final String password;

  const LoginRequest({
    required this.managerId,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'manager_id': managerId,
      'password': password,
    };
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
  }
}
