import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';
import '../providers/font_size_provider.dart';
import '../providers/seat_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ui_provider.dart';
import 'theme_color_selector.dart';
import 'theme_mode_selector.dart';

class SidePanel extends ConsumerStatefulWidget {
  final SidePanelType type;
  final VoidCallback? onClose; // 패널 닫기 콜백

  const SidePanel({super.key, required this.type, this.onClose});

  @override
  ConsumerState<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends ConsumerState<SidePanel> {
  bool _isThemeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final isDarkMode = currentThemeMode == AppThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(
                _getIconForType(widget.type),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      widget.type.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // 선택 상태 해제
                  ref.read(selectedSidePanelProvider.notifier).state = null;
                  // 외부 패널 표시 상태 닫기
                  widget.onClose?.call();
                },
                tooltip: '닫기',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // 콘텐츠
          Expanded(
            child: _buildContent(
              context,
              ref,
              widget.type,
              isDarkMode,
              onSurface,
            ),
          ),
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SidePanelType type,
    bool isDarkMode,
    Color onSurface,
  ) {
    switch (type) {
      case SidePanelType.dashboard:
        return _buildDashboard(context, ref, isDarkMode, onSurface);
      case SidePanelType.members:
        return _buildMembers(context, ref, isDarkMode, onSurface);
      case SidePanelType.payments:
        return _buildPayments(context, ref, isDarkMode, onSurface);
      case SidePanelType.statistics:
        return _buildStatistics(context, ref, isDarkMode, onSurface);
      case SidePanelType.settings:
        return _buildSettings(context, ref, isDarkMode, onSurface);
    }
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    Color onSurface,
  ) {
    final seatStats = ref.watch(seatStatisticsProvider);
    final occupiedSeats = ref.watch(occupiedSeatsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌석 현황 카드
          _buildStatCard(
            context,
            '전체 좌석',
            '48석',
            Icons.event_seat,
            Colors.blue,
            onSurface,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            '사용 중',
            '${seatStats[SeatStatus.occupied] ?? 0}석',
            Icons.person,
            Colors.green,
            onSurface,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            '사용 가능',
            '${seatStats[SeatStatus.available] ?? 0}석',
            Icons.event_available,
            Colors.orange,
            onSurface,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            '점검 중',
            '${seatStats[SeatStatus.maintenance] ?? 0}석',
            Icons.build,
            Colors.red,
            onSurface,
          ),

          const SizedBox(height: 24),
          Text(
            '최근 활동',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
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
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      seat.userName ?? '사용자',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: onSurface),
                    ),
                    subtitle: Text(
                      '${seat.type.typeText} • ${seat.remainingTimeText}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Text(
                      seat.startTime?.toString().substring(11, 16) ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMembers(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    Color onSurface,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색 바
          TextField(
            decoration: InputDecoration(
              hintText: '회원 검색...',
              hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.5)),
              prefixIcon: Icon(
                Icons.search,
                color: onSurface.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: onSurface),
          ),
          const SizedBox(height: 16),

          // 회원 목록
          ...List.generate(
            10,
            (index) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    '회${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '회원 ${index + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: onSurface),
                ),
                subtitle: Text(
                  '010-1234-${(5678 + index).toString().padLeft(4, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        '편집',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: onSurface),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        '삭제',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayments(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    Color onSurface,
  ) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
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
                title: Text(
                  '좌석 ${(index + 1).toString().padLeft(2, '0')} 이용료',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: onSurface),
                ),
                subtitle: Text(
                  DateTime.now()
                      .subtract(Duration(hours: index))
                      .toString()
                      .substring(5, 16),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                trailing: Text(
                  '₩ ${(5000 + index * 1000).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    Color onSurface,
  ) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
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
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                day,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: onSurface.withValues(alpha: 0.6),
                                    ),
                              ),
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
                child: _buildStatCard(
                  context,
                  '평균 이용시간',
                  '3.2시간',
                  Icons.access_time,
                  Colors.blue,
                  onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  '일 평균 매출',
                  '₩ 180K',
                  Icons.trending_up,
                  Colors.green,
                  onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '신규 회원',
                  '12명',
                  Icons.person_add,
                  Colors.orange,
                  onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  '재방문율',
                  '68%',
                  Icons.refresh,
                  Colors.purple,
                  onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    Color onSurface,
  ) {
    final currentFontLevel = ref.watch(currentFontSizeLevelProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 일반 설정
          Text(
            '일반 설정',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '언어',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  subtitle: Text(
                    '한국어',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                // 테마 설정 (확장 가능)
                ExpansionTile(
                  leading: Icon(
                    Icons.palette,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '테마',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  subtitle: Consumer(
                    builder: (context, ref, child) {
                      final currentMode = ref.watch(currentThemeModeProvider);
                      final currentColor = ref.watch(currentThemeColorProvider);
                      return Text(
                        '${currentMode.displayName} • ${currentColor.displayName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                  initiallyExpanded: _isThemeExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isThemeExpanded = expanded;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ThemeModeSelector(),
                          SizedBox(height: 16),
                          ThemeColorSelector(),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                // 폰트크기 설정을 별도 섹션으로 분리
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 좌측 아이콘 (중앙 정렬)
                      Icon(
                        Icons.text_fields,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      // 우측 폰트크기 설정 영역
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 첫 번째 줄: "폰트크기" 텍스트
                            Text(
                              '폰트크기',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(color: onSurface),
                            ),
                            const SizedBox(height: 12),
                            // 두 번째 줄: 숫자 버튼들 (1-5)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (index) {
                                final level = FontSizeLevel.values[index];
                                final isSelected = currentFontLevel == level;

                                return GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(fontSizeProvider.notifier)
                                        .setFontSizeLevel(level);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary
                                                  : onSurface.withValues(
                                                      alpha: 0.6,
                                                    ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '알림',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 좌석 설정
          Text(
            '좌석 설정',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.timer,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '기본 이용시간',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  subtitle: Text(
                    '2시간',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.money,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '시간당 요금',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  subtitle: Text(
                    '₩ 2,500',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.auto_delete,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '자동 정리',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 시스템 정보
          Text(
            '시스템 정보',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '버전',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  subtitle: Text(
                    'v1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.update,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '업데이트 확인',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: onSurface),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
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
    Color onSurface,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
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
