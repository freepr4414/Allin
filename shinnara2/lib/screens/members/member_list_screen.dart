import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/member.dart';
import '../../providers/member_provider.dart';
import '../../utils/responsive.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MembershipType? _selectedMembershipType;
  MemberStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(memberProvider);
    final filteredMembers = _filterMembers(members);

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이지 헤더
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getResponsivePadding(context),
              vertical: Responsive.getResponsiveMargin(context),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                  size: Responsive.getResponsiveValue(context, mobile: 20, tablet: 24, desktop: 28),
                ),
                SizedBox(width: Responsive.getResponsiveMargin(context)),
                Text(
                  '회원 관리',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '총 ${members.length}명',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getResponsivePadding(context)),

          // 검색 및 필터 섹션
          _buildSearchAndFilters(context),

          SizedBox(height: Responsive.getResponsivePadding(context)),

          // 회원 테이블
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Responsive.isMobile(context)
                  ? _buildMobileList(filteredMembers)
                  : _buildDataTable(filteredMembers),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // 검색 필드
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '이름, 이메일, 전화번호로 검색...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          if (!Responsive.isMobile(context)) ...[
            SizedBox(height: Responsive.getResponsiveMargin(context)),
            // 필터 드롭다운들
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MembershipType?>(
                    value: _selectedMembershipType,
                    decoration: InputDecoration(
                      labelText: '회원등급',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem<MembershipType?>(value: null, child: Text('전체')),
                      ...MembershipType.values.map(
                        (type) => DropdownMenuItem(value: type, child: Text(type.displayName)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMembershipType = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: Responsive.getResponsiveMargin(context)),
                Expanded(
                  child: DropdownButtonFormField<MemberStatus?>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: '상태',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem<MemberStatus?>(value: null, child: Text('전체')),
                      ...MemberStatus.values.map(
                        (status) =>
                            DropdownMenuItem(value: status, child: Text(status.displayName)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Member> members) {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 800,
      columns: [
        DataColumn2(
          label: Text(
            '이름',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
            ),
          ),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text(
            '이메일',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
            ),
          ),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text(
            '전화번호',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
            ),
          ),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text(
            '등급',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
            ),
          ),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text(
            '상태',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
            ),
          ),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text(
            '가입일',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
            ),
          ),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text(
            '총 이용시간',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
            ),
          ),
          size: ColumnSize.S,
        ),
      ],
      rows: members.map((member) {
        return DataRow2(
          cells: [
            DataCell(
              Text(
                member.name,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 13),
                ),
              ),
            ),
            DataCell(
              Text(
                member.email,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 13),
                ),
              ),
            ),
            DataCell(
              Text(
                member.phone,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 13),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMembershipTypeColor(member.membershipType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getMembershipTypeColor(member.membershipType).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  member.membershipType.displayName,
                  style: TextStyle(
                    color: _getMembershipTypeColor(member.membershipType),
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 11),
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(member.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(member.status).withValues(alpha: 0.3)),
                ),
                child: Text(
                  member.status.displayName,
                  style: TextStyle(
                    color: _getStatusColor(member.status),
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 11),
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                DateFormat('yyyy.MM.dd').format(member.registrationDate),
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 13),
                ),
              ),
            ),
            DataCell(
              Text(
                '${member.totalHours}시간',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 13),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileList(List<Member> members) {
    return ListView.builder(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: EdgeInsets.only(bottom: Responsive.getResponsiveMargin(context)),
          child: Padding(
            padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(member.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(member.status).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        member.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(member.status),
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.getResponsiveMargin(context) / 2),
                Text(
                  member.email,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  member.phone,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 14),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: Responsive.getResponsiveMargin(context) / 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMembershipTypeColor(
                          member.membershipType,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getMembershipTypeColor(
                            member.membershipType,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        member.membershipType.displayName,
                        style: TextStyle(
                          color: _getMembershipTypeColor(member.membershipType),
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 11),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${member.totalHours}시간',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 12),
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Member> _filterMembers(List<Member> members) {
    var filtered = members;

    // 검색어 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (member) =>
                member.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                member.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                member.phone.contains(_searchQuery),
          )
          .toList();
    }

    // 회원등급 필터
    if (_selectedMembershipType != null) {
      filtered = filtered
          .where((member) => member.membershipType == _selectedMembershipType)
          .toList();
    }

    // 상태 필터
    if (_selectedStatus != null) {
      filtered = filtered.where((member) => member.status == _selectedStatus).toList();
    }

    return filtered;
  }

  Color _getMembershipTypeColor(MembershipType type) {
    switch (type) {
      case MembershipType.basic:
        return Colors.grey;
      case MembershipType.premium:
        return Colors.blue;
      case MembershipType.vip:
        return Colors.purple;
    }
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return Colors.green;
      case MemberStatus.inactive:
        return Colors.orange;
      case MemberStatus.suspended:
        return Colors.red;
    }
  }
}
