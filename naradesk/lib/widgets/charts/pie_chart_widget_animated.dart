import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/responsive.dart';
import 'common/chart_data_card.dart';

class DashboardPieChart extends ConsumerStatefulWidget {
  final Map<String, int> data;
  final String title;
  final List<Color> colors;

  const DashboardPieChart({
    super.key,
    required this.data,
    required this.title,
    this.colors = const [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ],
  });

  @override
  ConsumerState<DashboardPieChart> createState() => _DashboardPieChartState();
}

class _DashboardPieChartState extends ConsumerState<DashboardPieChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    // 약간의 지연 후 애니메이션 시작
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold(0, (sum, value) => sum + value);

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 60), // 고정값으로 큰 간격 설정
          // 반응형 레이아웃: 데스크톱은 카드, 태블릿/모바일은 DataTable
          ChartCardLayout.shouldUseCardLayout(context)
              ? _buildDesktopLayout(context, total)
              : _buildMobileLayout(context, total),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int total) {
    return Column(
      children: [
        // 그래프를 Row에 배치 (하나씩)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 200,
                  tablet: 250,
                  desktop: 300,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬 추가
                  children: [
                    // 파이 차트 - 고정 크기로 제한
                    SizedBox(
                      width: 300, // 파이차트 고정 너비
                      child: _buildChart(context, total),
                    ),
                    SizedBox(width: 60), // 간격 더 늘림 (40 → 60)
                    // 범례 - 고정 너비로 제한
                    SizedBox(
                      width: 200, // 범례 고정 너비
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildLegendItems(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsiveMargin(context)),
        // 카드 레이아웃 (Wrap으로 줄바꿈)
        _buildCardLayout(context),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, int total) {
    final isMobile = Responsive.isMobile(context); // Responsive 클래스의 모바일 감지 사용

    return Column(
      children: [
        // 실제 모바일에서는 세로 배치, 태블릿에서는 가로 배치
        if (isMobile) ...[
          // 모바일: 파이차트
          SizedBox(
            height: 180, // 모바일에서 높이 줄임
            child: _buildChart(context, total),
          ),
          SizedBox(height: 40), // 모바일 간격 고정값
          // 모바일: 범례를 Wrap으로 가로 배치
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _buildLegendItems(context),
          ),
        ] else ...[
          // 태블릿: 가로 배치 유지
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildChart(context, total)),
                SizedBox(width: 50), // 태블릿 간격 고정값
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegendItems(context),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: Responsive.getResponsiveMargin(context)),
        // 모바일/태블릿에서는 데이터테이블
        _buildDesktopDataTable(context),
      ],
    );
  }

  Widget _buildCardLayout(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final total = widget.data.values.fold(0, (sum, value) => sum + value);
    final entries = widget.data.entries.toList();

    final cards = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      final color = widget.colors[index % widget.colors.length];
      final percentage = total > 0 ? (dataEntry.value / total * 100) : 0.0;

      return ChartDataCard(
        title: dataEntry.key,
        value: '${dataEntry.value}',
        subtitle: '${percentage.toStringAsFixed(1)}%',
        indicatorColor: color,
      );
    }).toList();

    return ChartCardLayout.buildCardGrid(context: context, cards: cards);
  }

  Widget _buildChart(BuildContext context, int total) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            sections: _generateAnimatedSections(total),
          ),
          swapAnimationDuration: const Duration(milliseconds: 150),
          swapAnimationCurve: Curves.linear,
        );
      },
    );
  }

  List<Widget> _buildLegendItems(BuildContext context) {
    final entries = widget.data.entries.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 450;

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final color = widget.colors[index % widget.colors.length];
      final total = widget.data.values.fold(0, (sum, value) => sum + value);
      final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: isVerySmall ? 3 : 2),
        child: Row(
          mainAxisSize: isVerySmall ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Container(
              width: isVerySmall ? 12 : 16,
              height: isVerySmall ? 12 : 16,
              decoration: BoxDecoration(
                color: _touchedIndex == index
                    ? color.withValues(alpha: 0.8)
                    : color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isVerySmall ? 6 : 8),
            if (isVerySmall) ...[
              // 매우 좁은 화면에서는 이름과 퍼센티지를 함께 표시
              Text(
                '${entry.key} (${percentage.toStringAsFixed(0)}%)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: _touchedIndex == index
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              // 일반 화면에서는 기존 방식
              Expanded(
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: _touchedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  List<PieChartSectionData> _generateAnimatedSections(int total) {
    if (widget.data.isEmpty) return [];

    final entries = widget.data.entries.toList();
    final animationProgress = _animation.value;

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final color = widget.colors[index % widget.colors.length];
      final isTouched = index == _touchedIndex;
      final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

      // 애니메이션 진행률에 따른 실제 표시값 계산
      final animatedValue = entry.value * animationProgress;
      final animatedPercentage = percentage * animationProgress;

      return PieChartSectionData(
        color: isTouched ? color.withValues(alpha: 0.8) : color,
        value: animatedValue.toDouble(),
        title: animatedPercentage > 5
            ? '${animatedPercentage.toStringAsFixed(1)}%'
            : '',
        radius: isTouched ? 65 : 60,
        titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  Widget _buildDesktopDataTable(BuildContext context) {
    final total = widget.data.values.fold(0, (sum, value) => sum + value);
    final entries = widget.data.entries.toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Theme(
          data: Theme.of(context).copyWith(
            // DataTable 호버 효과를 위한 테마 설정
            hoverColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            dataRowColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.hovered)) {
                return Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1);
              }
              return null;
            }),
            dataRowMinHeight: 32,
            dataRowMaxHeight: 48,
            horizontalMargin: 12,
            columnSpacing: 16,
            showBottomBorder: true,
            columns: [
              DataColumn(
                label: Text(
                  '구분',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  '수량',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  '비율',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
            ],
            rows: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final dataEntry = entry.value;
              final color = widget.colors[index % widget.colors.length];
              final percentage = total > 0
                  ? (dataEntry.value / total * 100)
                  : 0.0;

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dataEntry.key,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      '${dataEntry.value}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
