import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_stats.dart';
import '../../utils/responsive.dart';
import 'common/chart_data_card.dart';

class DashboardBarChart extends ConsumerStatefulWidget {
  final List<HourlyUsage> data;
  final String title;
  final Color barColor;

  const DashboardBarChart({
    super.key,
    required this.data,
    required this.title,
    this.barColor = Colors.green,
  });

  @override
  ConsumerState<DashboardBarChart> createState() => _DashboardBarChartState();
}

class _DashboardBarChartState extends ConsumerState<DashboardBarChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          SizedBox(
            height: Responsive.getResponsiveMargin(context) * 1.5,
          ), // 간격 1.5배 증가
          // 반응형 레이아웃: 데스크톱은 카드, 태블릿/모바일은 DataTable
          ChartCardLayout.shouldUseCardLayout(context)
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
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
                child: _buildChart(context),
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

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
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
                child: _buildChart(context),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsiveMargin(context)),
        _buildDataTable(context),
      ],
    );
  }

  Widget _buildCardLayout(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final total = widget.data.fold<double>(
      0,
      (sum, data) => sum + data.userCount,
    );

    final cards = widget.data.map((hourlyData) {
      final percentage = total > 0 ? (hourlyData.userCount / total * 100) : 0.0;

      // 사용량에 따른 아이콘 결정
      IconData icon;
      if (percentage > 8) {
        icon = Icons.schedule; // 피크 시간
      } else if (percentage > 4) {
        icon = Icons.access_time; // 보통 시간
      } else {
        icon = Icons.access_time_outlined; // 한가한 시간
      }

      return ChartDataCard(
        title: '${hourlyData.hour.toString().padLeft(2, '0')}:00',
        value: '${hourlyData.userCount}명',
        subtitle: '${percentage.toStringAsFixed(1)}%',
        indicatorColor: widget.barColor,
        icon: icon,
      );
    }).toList();

    return ChartCardLayout.buildCardGrid(context: context, cards: cards);
  }

  Widget _buildChart(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: widget.data.isNotEmpty
                ? widget.data
                          .map((e) => e.userCount)
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() *
                      1.2
                : 50,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    Theme.of(context).colorScheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  // group.x가 실제 시간 값
                  final hour = group.x.toInt();
                  final hourlyData = widget.data.firstWhere(
                    (data) => data.hour == hour,
                    orElse: () => widget.data.first,
                  );

                  // 애니메이션 진행률에 따른 실제 표시값 계산
                  final dataIndex = widget.data.indexWhere(
                    (data) => data.hour == hour,
                  );
                  final barProgress =
                      (_animation.value * 1.5 - (dataIndex * 0.1)).clamp(
                        0.0,
                        1.0,
                      );
                  final currentDisplayValue =
                      (hourlyData.userCount * barProgress).round();

                  return BarTooltipItem(
                    '${hour.toString().padLeft(2, '0')}:00\n$currentDisplayValue명',
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                });
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final hour = value.toInt();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        hour.toString().padLeft(2, '0'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  },
                  reservedSize: 28,
                  interval: widget.data.length > 12 ? 2 : 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: widget.data.isNotEmpty
                      ? (widget.data
                                    .map((e) => e.userCount)
                                    .reduce((a, b) => a > b ? a : b) /
                                5)
                            .roundToDouble()
                      : 10,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            barGroups: _generateAnimatedBarGroups(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: widget.data.isNotEmpty
                  ? (widget.data
                                .map((e) => e.userCount)
                                .reduce((a, b) => a > b ? a : b) /
                            5)
                        .roundToDouble()
                  : 10,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<BarChartGroupData> _generateAnimatedBarGroups() {
    if (widget.data.isEmpty) return [];

    final animationProgress = _animation.value;
    return List.generate(widget.data.length, (index) {
      final hourlyData = widget.data[index];
      final isTouched = index == _touchedIndex;

      // 각 바가 순차적으로 애니메이션되도록 설정
      final barProgress = (animationProgress * 1.5 - (index * 0.1)).clamp(
        0.0,
        1.0,
      );
      final animatedValue = hourlyData.userCount * barProgress;

      return BarChartGroupData(
        x: hourlyData.hour, // 실제 시간 값 사용
        barRods: [
          BarChartRodData(
            toY: animatedValue,
            color: isTouched
                ? widget.barColor.withValues(alpha: 0.8)
                : widget.barColor,
            width: isTouched ? 20 : 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: widget.data
                  .map((e) => e.userCount)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble(),
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [widget.barColor, widget.barColor.withValues(alpha: 0.7)],
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    });
  }

  Widget _buildDataTable(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox.shrink();
    }

    // 태블릿/모바일에서는 항상 DataTable 사용
    return _buildDesktopDataTable(context);
  }

  Widget _buildDesktopDataTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
            return null; // 기본 색상 사용
          }),
          dataRowMinHeight: 32,
          dataRowMaxHeight: 48,
          horizontalMargin: 12,
          columnSpacing: 24,
          columns: [
            DataColumn(
              label: Text(
                '시간',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                '이용자 수',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                '점유율',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
          ],
          rows: widget.data.map((item) {
            final totalUsers = widget.data.fold<double>(
              0,
              (sum, data) => sum + data.userCount,
            );
            final percentage = totalUsers > 0
                ? (item.userCount / totalUsers * 100)
                : 0.0;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${item.hour.toString().padLeft(2, '0')}:00',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                DataCell(
                  Text(
                    '${item.userCount}명',
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
    );
  }
}
