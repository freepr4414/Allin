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
    required this.createdAt,
    required this.updatedAt,
  });

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
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Manager(managerId: $managerId, managerName: $managerName, role: $role)';
  }
}
