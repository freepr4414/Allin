import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_stats.dart';
import '../../providers/font_size_provider.dart';
import '../../utils/responsive.dart';
import '../../utils/responsive_font.dart';
import 'common/chart_data_card.dart';

class DashboardLineChart extends ConsumerStatefulWidget {
  final List<DailyUsage> data;
  final String title;
  final Color lineColor;

  const DashboardLineChart({
    super.key,
    required this.data,
    required this.title,
    this.lineColor = Colors.blue,
  });

  @override
  ConsumerState<DashboardLineChart> createState() => _DashboardLineChartState();
}

class _DashboardLineChartState extends ConsumerState<DashboardLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
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

    final cards = widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final dailyData = entry.value;

      // 전일 대비 증감률 계산
      String changeText = '';
      if (index > 0) {
        final previousData = widget.data[index - 1];
        final change = dailyData.userCount - previousData.userCount;
        final changePercent = previousData.userCount > 0
            ? (change / previousData.userCount * 100)
            : 0.0;

        if (change > 0) {
          changeText = '+${changePercent.toStringAsFixed(1)}%';
        } else if (change < 0) {
          changeText = '${changePercent.toStringAsFixed(1)}%';
        } else {
          changeText = '0.0%';
        }
      }

      return ChartDataCard(
        title: '${dailyData.date.month}/${dailyData.date.day}',
        value: '${dailyData.userCount}명',
        subtitle: changeText.isNotEmpty ? changeText : null,
        indicatorColor: widget.lineColor,
        icon:
            dailyData.userCount >
                (index > 0 ? widget.data[index - 1].userCount : 0)
            ? Icons.trending_up
            : dailyData.userCount <
                  (index > 0 ? widget.data[index - 1].userCount : 0)
            ? Icons.trending_down
            : Icons.trending_flat,
      );
    }).toList();

    return ChartCardLayout.buildCardGrid(context: context, cards: cards);
  }

  Widget _buildChart(BuildContext context) {
    final fontSizeRatio = ref.watch(currentBaseFontSizeProvider) / 16.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: widget.data.isNotEmpty
                  ? widget.data
                            .map((e) => e.userCount)
                            .reduce((a, b) => a > b ? a : b) /
                        5
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
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize:
                            (Theme.of(context).textTheme.bodySmall?.fontSize ??
                                12) *
                            fontSizeRatio,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < widget.data.length) {
                      final date = widget.data[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${date.month}/${date.day}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.fontSize ??
                                        12) *
                                    fontSizeRatio,
                              ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
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
            lineBarsData: [
              LineChartBarData(
                spots: _generateAnimatedSpots(),
                isCurved: true,
                color: widget.lineColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: widget.lineColor,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.lineColor.withValues(alpha: 0.3),
                      widget.lineColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    Theme.of(context).colorScheme.inverseSurface,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    if (touchedSpot.x.toInt() >= 0 &&
                        touchedSpot.x.toInt() < widget.data.length) {
                      final data = widget.data[touchedSpot.x.toInt()];
                      return LineTooltipItem(
                        '${data.date.month}/${data.date.day}\n${touchedSpot.y.round()}명',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
        );
      },
    );
  }

  List<FlSpot> _generateAnimatedSpots() {
    if (widget.data.isEmpty) return [];

    final animationProgress = _animation.value;
    return List.generate(widget.data.length, (index) {
      final progress = (animationProgress * widget.data.length - index).clamp(
        0.0,
        1.0,
      );
      final targetY = widget.data[index].userCount.toDouble();
      final animatedY = targetY * progress;

      return FlSpot(index.toDouble(), animatedY);
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
                '날짜',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ref.getResponsiveFontSize(
                    context,
                    baseFontSize: 12,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                '이용자 수',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ref.getResponsiveFontSize(
                    context,
                    baseFontSize: 12,
                  ),
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                '수익',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ref.getResponsiveFontSize(
                    context,
                    baseFontSize: 12,
                  ),
                ),
              ),
              numeric: true,
            ),
          ],
          rows: widget.data.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${item.date.month}/${item.date.day}',
                    style: TextStyle(
                      fontSize: ref.getResponsiveFontSize(
                        context,
                        baseFontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${item.userCount}명',
                    style: TextStyle(
                      fontSize: ref.getResponsiveFontSize(
                        context,
                        baseFontSize: 11,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '₩${item.revenue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: ref.getResponsiveFontSize(
                        context,
                        baseFontSize: 11,
                      ),
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
