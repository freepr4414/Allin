import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/responsive.dart';

/// 회원 활동/접속 로그 화면 (임시 플레이스홀더)
/// TODO: 백엔드 API 연동 후 실제 로그 데이터 표시 (검색/필터/페이지네이션)
class MemberLogScreen extends ConsumerStatefulWidget {
  const MemberLogScreen({super.key});

  @override
  ConsumerState<MemberLogScreen> createState() => _MemberLogScreenState();
}

class _MemberLogScreenState extends ConsumerState<MemberLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    // 임시 더미 로그 데이터
    final logs =
        List.generate(
              30,
              (i) => _DummyLog(
                id: i + 1,
                memberName: '회원${(i % 8) + 1}',
                action: i % 3 == 0
                    ? '로그인'
                    : i % 3 == 1
                    ? '좌석입실'
                    : '좌석퇴실',
                timestamp: DateTime.now().subtract(Duration(minutes: i * 7)),
                meta: i % 2 == 0
                    ? 'IP: 192.168.0.${i % 15 + 2}'
                    : 'Device: DESK',
              ),
            )
            .where(
              (l) =>
                  _searchQuery.isEmpty || l.memberName.contains(_searchQuery),
            )
            .toList();

    return Padding(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, onSurface, logs.length),
          SizedBox(height: Responsive.getResponsivePadding(context)),
          _searchBar(onSurface),
          SizedBox(height: Responsive.getResponsivePadding(context)),
          Expanded(child: _logTable(context, logs, onSurface)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Color onSurface, int total) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: Responsive.getResponsivePadding(context),
      vertical: Responsive.getResponsiveMargin(context),
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: Responsive.getResponsiveMargin(context)),
        Text(
          '회원 로그',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const Spacer(),
        Text(
          '총 $total건',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );

  Widget _searchBar(Color onSurface) => TextField(
    controller: _searchController,
    decoration: InputDecoration(
      hintText: '회원명 검색...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
            )
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    style: TextStyle(color: onSurface),
    onChanged: (v) => setState(() => _searchQuery = v.trim()),
  );

  Widget _logTable(
    BuildContext context,
    List<_DummyLog> logs,
    Color onSurface,
  ) {
    if (Responsive.isMobile(context)) {
      return ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Card(
            margin: EdgeInsets.only(
              bottom: Responsive.getResponsiveMargin(context),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .1),
                child: Text(
                  '${log.id}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                '${log.memberName} • ${log.action}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: onSurface),
              ),
              subtitle: Text(
                '${_fmt(log.timestamp)}\n${log.meta}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: .6),
                ),
              ),
              isThreeLine: true,
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primary.withValues(alpha: .05),
          ),
          columns: [
            const DataColumn(label: Text('ID')),
            const DataColumn(label: Text('회원명')),
            const DataColumn(label: Text('행동')),
            const DataColumn(label: Text('시간')),
            const DataColumn(label: Text('메타 정보')),
          ],
          rows: logs
              .map(
                (log) => DataRow(
                  cells: [
                    DataCell(Text('${log.id}')),
                    DataCell(Text(log.memberName)),
                    DataCell(Text(log.action)),
                    DataCell(Text(_fmt(log.timestamp))),
                    DataCell(Text(log.meta)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DummyLog {
  final int id;
  final String memberName;
  final String action;
  final DateTime timestamp;
  final String meta;
  _DummyLog({
    required this.id,
    required this.memberName,
    required this.action,
    required this.timestamp,
    required this.meta,
  });
}
