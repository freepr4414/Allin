import 'package:flutter/material.dart';

/// 차트 데이터를 카드 형태로 표시하는 공통 위젯
class ChartDataCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? indicatorColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const ChartDataCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.indicatorColor,
    this.icon,
    this.onTap,
    this.width = 160,
    this.height = 120,
  });

  @override
  State<ChartDataCard> createState() => _ChartDataCardState();
}

class _ChartDataCardState extends State<ChartDataCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isHovered
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: _isHovered ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 상단: 인디케이터 색상 + 아이콘 (있을 경우)
                      if (widget.indicatorColor != null || widget.icon != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.indicatorColor != null)
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: widget.indicatorColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (widget.indicatorColor != null && widget.icon != null)
                              const SizedBox(width: 6),
                            if (widget.icon != null)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      (widget.indicatorColor ??
                                              Theme.of(context).colorScheme.primary)
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: 20, // 크기 증가
                                  color:
                                      widget.indicatorColor ??
                                      Theme.of(context).colorScheme.primary, // 인디케이터 색상 사용
                                ),
                              ),
                          ],
                        ),
                      if (widget.indicatorColor != null || widget.icon != null)
                        const SizedBox(height: 8),

                      // 제목
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // 값
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // 부제목 (있을 경우)
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 카드 레이아웃을 위한 유틸리티 클래스
class ChartCardLayout {
  /// Wrap을 사용한 반응형 카드 레이아웃 생성
  static Widget buildCardGrid({
    required BuildContext context,
    required List<Widget> cards,
    double spacing = 12,
    double runSpacing = 12,
    WrapAlignment alignment = WrapAlignment.start,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: cards,
    );
  }

  /// 반응형 조건 확인
  static bool shouldUseCardLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 데스크톱에서만 카드 사용, 태블릿/모바일은 DataTable 사용
    return screenWidth >= 1200; // 데스크톱(1200px 이상)에서만 카드 레이아웃
  }
}
