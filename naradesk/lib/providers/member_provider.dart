import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member.dart';

final memberProvider = StateNotifierProvider<MemberNotifier, List<Member>>((ref) {
  return MemberNotifier();
});

class MemberNotifier extends StateNotifier<List<Member>> {
  MemberNotifier() : super([]) {
    _loadSampleData();
  }

  void _loadSampleData() {
    final sampleMembers = [
      Member(
        id: '1',
        name: '김철수',
        email: 'kim@example.com',
        phone: '010-1234-5678',
        registrationDate: DateTime.now().subtract(const Duration(days: 30)),
        membershipType: MembershipType.premium,
        status: MemberStatus.active,
        totalHours: 120,
        totalPayment: 480000,
      ),
      Member(
        id: '2',
        name: '박영희',
        email: 'park@example.com',
        phone: '010-2345-6789',
        registrationDate: DateTime.now().subtract(const Duration(days: 15)),
        membershipType: MembershipType.basic,
        status: MemberStatus.active,
        totalHours: 80,
        totalPayment: 240000,
      ),
      Member(
        id: '3',
        name: '이민수',
        email: 'lee@example.com',
        phone: '010-3456-7890',
        registrationDate: DateTime.now().subtract(const Duration(days: 60)),
        membershipType: MembershipType.vip,
        status: MemberStatus.inactive,
        totalHours: 200,
        totalPayment: 800000,
      ),
      Member(
        id: '4',
        name: '정수연',
        email: 'jung@example.com',
        phone: '010-4567-8901',
        registrationDate: DateTime.now().subtract(const Duration(days: 7)),
        membershipType: MembershipType.basic,
        status: MemberStatus.active,
        totalHours: 40,
        totalPayment: 120000,
      ),
      Member(
        id: '5',
        name: '최현우',
        email: 'choi@example.com',
        phone: '010-5678-9012',
        registrationDate: DateTime.now().subtract(const Duration(days: 45)),
        membershipType: MembershipType.premium,
        status: MemberStatus.suspended,
        totalHours: 160,
        totalPayment: 640000,
      ),
    ];

    state = sampleMembers;
  }

  void addMember(Member member) {
    state = [...state, member];
  }

  void updateMember(String id, Member updatedMember) {
    state = [
      for (final member in state)
        if (member.id == id) updatedMember else member,
    ];
  }

  void deleteMember(String id) {
    state = state.where((member) => member.id != id).toList();
  }

  List<Member> getActiveMembers() {
    return state.where((member) => member.status == MemberStatus.active).toList();
  }

  List<Member> searchMembers(String query) {
    if (query.isEmpty) return state;

    return state
        .where(
          (member) =>
              member.name.toLowerCase().contains(query.toLowerCase()) ||
              member.email.toLowerCase().contains(query.toLowerCase()) ||
              member.phone.contains(query),
        )
        .toList();
  }
}
