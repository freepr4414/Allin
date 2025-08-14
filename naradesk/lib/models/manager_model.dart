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
    required this.createdAt,
    required this.updatedAt,
  });

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
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
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
  }
}
