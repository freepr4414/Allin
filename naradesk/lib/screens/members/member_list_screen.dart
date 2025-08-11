import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/member.dart';
import '../../providers/member_provider.dart';
import '../../utils/responsive.dart';
import '../../utils/responsive_font.dart';

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
    final filtered = _filterMembers(members);
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return Padding(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, members.length, onSurface),
          SizedBox(height: Responsive.getResponsivePadding(context)),
          _filters(context, onSurface),
          SizedBox(height: Responsive.getResponsivePadding(context)),
          Expanded(
            child: !Responsive.isMobile(context)
                ? _dataTable(filtered, onSurface)
                : _mobileList(filtered, onSurface),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, int total, Color onSurface) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '회원관리',
        style: TextStyle(
          fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 24),
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
      ),
      SizedBox(height: Responsive.getResponsivePadding(context) * 0.5),
      Text(
        '전체 회원 수: $total명',
        style: TextStyle(
          fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 16),
          color: onSurface.withOpacity(0.7),
        ),
      ),
    ],
  );

  Widget _filters(BuildContext context, Color onSurface) => Wrap(
    spacing: 16,
    runSpacing: 12,
    children: [
      SizedBox(
        width: 200,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '이름, 이메일, 전화번호 검색',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
      DropdownButton<MembershipType?>(
        value: _selectedMembershipType,
        hint: const Text('등급 필터'),
        items: [
          const DropdownMenuItem<MembershipType?>(
            value: null,
            child: Text('모든 등급'),
          ),
          ...MembershipType.values.map(
            (type) =>
                DropdownMenuItem(value: type, child: Text(type.displayName)),
          ),
        ],
        onChanged: (value) => setState(() => _selectedMembershipType = value),
      ),
      DropdownButton<MemberStatus?>(
        value: _selectedStatus,
        hint: const Text('상태 필터'),
        items: [
          const DropdownMenuItem<MemberStatus?>(
            value: null,
            child: Text('모든 상태'),
          ),
          ...MemberStatus.values.map(
            (status) => DropdownMenuItem(
              value: status,
              child: Text(status.displayName),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _selectedStatus = value),
      ),
    ],
  );

  Widget _dataTable(List<Member> members, Color onSurface) {
    // 기존 Responsive -> 폰트 레벨 반영 버전
    final headingFontSize = ref.getResponsiveFontSize(
      context,
      baseFontSize: 14,
    );
    final dataFontSize = ref.getResponsiveFontSize(context, baseFontSize: 13);

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          dataTextStyle: TextStyle(color: onSurface, fontSize: dataFontSize),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: onSurface,
            fontSize: headingFontSize,
          ),
        ),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 900,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: onSurface,
          fontSize: headingFontSize,
        ),
        dataTextStyle: TextStyle(color: onSurface, fontSize: dataFontSize),
        columns: [
          _col('이름', onSurface),
          _col('이메일', onSurface, size: ColumnSize.L),
          _col('전화번호', onSurface),
          _col('등급', onSurface, size: ColumnSize.S),
          _col('상태', onSurface, size: ColumnSize.S),
          _col('가입일', onSurface),
          _col('총 이용시간', onSurface, size: ColumnSize.S),
        ],
        rows: members.map(_dataRow).toList(),
      ),
    );
  }

  DataColumn2 _col(
    String label,
    Color onSurface, {
    ColumnSize size = ColumnSize.M,
  }) => DataColumn2(label: Text(label), size: size);

  DataRow2 _dataRow(Member member) {
    final dataFontSize = ref.getResponsiveFontSize(context, baseFontSize: 13);

    Text styled(String text) =>
        Text(text, style: TextStyle(fontSize: dataFontSize));

    return DataRow2(
      cells: [
        DataCell(styled(member.name)),
        DataCell(styled(member.email)),
        DataCell(styled(member.phone)),
        DataCell(
          _badge(
            member.membershipType.displayName,
            _getMembershipTypeColor(member.membershipType),
          ),
        ),
        DataCell(
          _badge(member.status.displayName, _getStatusColor(member.status)),
        ),
        DataCell(
          styled(DateFormat('yyyy-MM-dd').format(member.registrationDate)),
        ),
        DataCell(styled('${member.totalHours}시간')),
      ],
    );
  }

  Widget _mobileList(List<Member> members, Color onSurface) => ListView.builder(
    itemCount: members.length,
    itemBuilder: (context, index) {
      final m = members[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    m.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        baseFontSize: 16,
                      ),
                    ),
                  ),
                  _badge(m.status.displayName, _getStatusColor(m.status)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                m.email,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    baseFontSize: 14,
                  ),
                  color: onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.phone,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    baseFontSize: 14,
                  ),
                  color: onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _badge(
                    m.membershipType.displayName,
                    _getMembershipTypeColor(m.membershipType),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(m.registrationDate),
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        baseFontSize: 12,
                      ),
                      color: onSurface.withOpacity(0.5),
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

  Widget _badge(String text, Color color) {
    final badgeFontSize = ref.getResponsiveFontSize(context, baseFontSize: 12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: badgeFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getMembershipTypeColor(MembershipType type) {
    switch (type) {
      case MembershipType.basic:
        return Colors.grey;
      case MembershipType.premium:
        return Colors.amber;
      case MembershipType.vip:
        return Colors.indigo;
    }
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return Colors.green;
      case MemberStatus.inactive:
        return Colors.grey;
      case MemberStatus.suspended:
        return Colors.red;
    }
  }

  List<Member> _filterMembers(List<Member> members) {
    return members.where((member) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          member.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          member.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          member.phone.contains(_searchQuery);

      final matchesMembershipType =
          _selectedMembershipType == null ||
          member.membershipType == _selectedMembershipType;

      final matchesStatus =
          _selectedStatus == null || member.status == _selectedStatus;

      return matchesSearch && matchesMembershipType && matchesStatus;
    }).toList();
  }
}
