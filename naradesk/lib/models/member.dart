class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime registrationDate;
  final MembershipType membershipType;
  final MemberStatus status;
  final int totalHours;
  final double totalPayment;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.registrationDate,
    required this.membershipType,
    required this.status,
    required this.totalHours,
    required this.totalPayment,
  });

  Member copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? registrationDate,
    MembershipType? membershipType,
    MemberStatus? status,
    int? totalHours,
    double? totalPayment,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      registrationDate: registrationDate ?? this.registrationDate,
      membershipType: membershipType ?? this.membershipType,
      status: status ?? this.status,
      totalHours: totalHours ?? this.totalHours,
      totalPayment: totalPayment ?? this.totalPayment,
    );
  }
}

enum MembershipType {
  basic('기본 회원'),
  premium('프리미엄'),
  vip('VIP');

  const MembershipType(this.displayName);
  final String displayName;
}

enum MemberStatus {
  active('활성'),
  inactive('비활성'),
  suspended('정지');

  const MemberStatus(this.displayName);
  final String displayName;
}
