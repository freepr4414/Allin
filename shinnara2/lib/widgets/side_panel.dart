import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';
import '../providers/seat_provider.dart';
import '../providers/ui_provider.dart';

class SidePanel extends ConsumerWidget {
  final SidePanelType type;

  const SidePanel({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(_getIconForType(type), color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      type.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(selectedSidePanelProvider.notifier).state = null;
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // 콘텐츠
          Expanded(child: _buildContent(context, ref, type)),
        ],
      ),
    );
  }

  IconData _getIconForType(SidePanelType type) {
    switch (type) {
      case SidePanelType.dashboard:
        return Icons.dashboard;
      case SidePanelType.members:
        return Icons.people;
      case SidePanelType.payments:
        return Icons.payment;
      case SidePanelType.statistics:
        return Icons.bar_chart;
      case SidePanelType.settings:
        return Icons.settings;
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SidePanelType type) {
    switch (type) {
      case SidePanelType.dashboard:
        return _buildDashboard(context, ref);
      case SidePanelType.members:
        return _buildMembers(context, ref);
      case SidePanelType.payments:
        return _buildPayments(context, ref);
      case SidePanelType.statistics:
        return _buildStatistics(context, ref);
      case SidePanelType.settings:
        return _buildSettings(context, ref);
    }
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref) {
    final seatStats = ref.watch(seatStatisticsProvider);
    final occupiedSeats = ref.watch(occupiedSeatsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌석 현황 카드
          _buildStatCard(context, '전체 좌석', '48석', Icons.event_seat, Colors.blue),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            '사용 중',
            '${seatStats[SeatStatus.occupied] ?? 0}석',
            Icons.person,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            '사용 가능',
            '${seatStats[SeatStatus.available] ?? 0}석',
            Icons.event_available,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            '점검 중',
            '${seatStats[SeatStatus.maintenance] ?? 0}석',
            Icons.build,
            Colors.red,
          ),

          const SizedBox(height: 24),
          Text(
            '최근 활동',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 현재 사용 중인 좌석 목록
          ...occupiedSeats
              .take(5)
              .map(
                (seat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      child: Text(
                        seat.number,
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(seat.userName ?? '사용자'),
                    subtitle: Text('${seat.type.typeText} • ${seat.remainingTimeText}'),
                    trailing: Text(
                      seat.startTime?.toString().substring(11, 16) ?? '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMembers(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색 바
          TextField(
            decoration: InputDecoration(
              hintText: '회원 검색...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // 회원 목록
          ...List.generate(
            10,
            (index) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    '회${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('회원 ${index + 1}'),
                subtitle: Text('010-1234-${(5678 + index).toString().padLeft(4, '0')}'),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('편집')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayments(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 오늘의 매출
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 매출',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₩ 245,000',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '최근 결제 내역',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 결제 내역 목록
          ...List.generate(
            8,
            (index) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.payment, color: Colors.green),
                ),
                title: Text('좌석 ${(index + 1).toString().padLeft(2, '0')} 이용료'),
                subtitle: Text(
                  DateTime.now().subtract(Duration(hours: index)).toString().substring(5, 16),
                ),
                trailing: Text(
                  '₩ ${(5000 + index * 1000).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이용률 그래프 (간단한 표현)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주간 이용률',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['월', '화', '수', '목', '금', '토', '일']
                        .map(
                          (day) => Column(
                            children: [
                              Container(
                                height: 80,
                                width: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(day, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 통계 카드들
          Row(
            children: [
              Expanded(
                child: _buildStatCard(context, '평균 이용시간', '3.2시간', Icons.access_time, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  '일 평균 매출',
                  '₩ 180K',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(context, '신규 회원', '12명', Icons.person_add, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, '재방문율', '68%', Icons.refresh, Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 일반 설정
          Text(
            '일반 설정',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('언어'),
                  subtitle: const Text('한국어'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('테마'),
                  subtitle: const Text('라이트 모드'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('알림'),
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 좌석 설정
          Text(
            '좌석 설정',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('기본 이용시간'),
                  subtitle: const Text('2시간'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.money),
                  title: const Text('시간당 요금'),
                  subtitle: const Text('₩ 2,500'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_delete),
                  title: const Text('자동 정리'),
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 시스템 정보
          Text(
            '시스템 정보',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('버전'),
                  subtitle: const Text('v1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('업데이트 확인'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
