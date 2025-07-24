import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// 통일된 애니메이션 시스템
class AppAnimations {
  // ============ 기본 애니메이션 곡선 ============
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // ============ 기본 애니메이션 생성 메서드 ============

  /// 페이드 인 애니메이션
  static Animation<double> fadeIn(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = easeInOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// 페이드 아웃 애니메이션
  static Animation<double> fadeOut(
    AnimationController controller, {
    double begin = 1.0,
    double end = 0.0,
    Curve curve = easeInOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// 스케일 애니메이션
  static Animation<double> scale(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = bounceOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// 슬라이드 애니메이션
  static Animation<Offset> slide(
    AnimationController controller, {
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = easeInOut,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// 회전 애니메이션
  static Animation<double> rotation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = easeInOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// 색상 애니메이션
  static Animation<Color?> color(
    AnimationController controller, {
    required Color begin,
    required Color end,
    Curve curve = easeInOut,
  }) {
    return ColorTween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// 크기 애니메이션
  static Animation<Size?> size(
    AnimationController controller, {
    required Size begin,
    required Size end,
    Curve curve = easeInOut,
  }) {
    return SizeTween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }
}

/// 애니메이션 빌더 위젯
class AppAnimatedBuilder extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final AnimationType type;
  final bool autoStart;
  final bool repeat;
  final Curve curve;
  final VoidCallback? onComplete;

  const AppAnimatedBuilder({
    super.key,
    required this.child,
    this.duration = AppConstants.normalAnimation,
    this.type = AnimationType.fadeIn,
    this.autoStart = true,
    this.repeat = false,
    this.curve = AppAnimations.easeInOut,
    this.onComplete,
  });

  @override
  State<AppAnimatedBuilder> createState() => _AppAnimatedBuilderState();
}

class _AppAnimatedBuilderState extends State<AppAnimatedBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    switch (widget.type) {
      case AnimationType.fadeIn:
        _animation = AppAnimations.fadeIn(_controller, curve: widget.curve);
        break;
      case AnimationType.fadeOut:
        _animation = AppAnimations.fadeOut(_controller, curve: widget.curve);
        break;
      case AnimationType.scale:
        _animation = AppAnimations.scale(_controller, curve: widget.curve);
        break;
      case AnimationType.rotation:
        _animation = AppAnimations.rotation(_controller, curve: widget.curve);
        break;
    }

    if (widget.onComplete != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete!();
        }
      });
    }

    if (widget.repeat) {
      _controller.repeat();
    } else if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        switch (widget.type) {
          case AnimationType.fadeIn:
          case AnimationType.fadeOut:
            return Opacity(opacity: _animation.value, child: child);
          case AnimationType.scale:
            return Transform.scale(scale: _animation.value, child: child);
          case AnimationType.rotation:
            return Transform.rotate(angle: _animation.value * 2 * 3.14159, child: child);
        }
      },
    );
  }
}

/// 애니메이션 타입 열거형
enum AnimationType { fadeIn, fadeOut, scale, rotation }

/// 호버 애니메이션 위젯
class HoverAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleValue;
  final double? elevation;
  final Color? hoverColor;
  final VoidCallback? onTap;
  final VoidCallback? onHover;

  const HoverAnimatedWidget({
    super.key,
    required this.child,
    this.duration = AppConstants.fastAnimation,
    this.scaleValue = 1.05,
    this.elevation,
    this.hoverColor,
    this.onTap,
    this.onHover,
  });

  @override
  State<HoverAnimatedWidget> createState() => _HoverAnimatedWidgetState();
}

class _HoverAnimatedWidgetState extends State<HoverAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(parent: _controller, curve: AppAnimations.easeInOut));
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) * 2,
    ).animate(CurvedAnimation(parent: _controller, curve: AppAnimations.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
      widget.onHover?.call();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: widget.hoverColor != null
                    ? BoxDecoration(
                        color: _isHovered ? widget.hoverColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: widget.elevation != null
                    ? Material(
                        elevation: _elevationAnimation.value,
                        borderRadius: BorderRadius.circular(8),
                        child: child,
                      )
                    : child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 로딩 애니메이션 위젯
class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;

  const LoadingAnimation({
    super.key,
    this.size = 24.0,
    this.color,
    this.duration = const Duration(seconds: 1),
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Icon(
        Icons.refresh,
        size: widget.size,
        color: widget.color ?? Theme.of(context).primaryColor,
      ),
      builder: (context, child) {
        return Transform.rotate(angle: _controller.value * 2 * 3.14159, child: child);
      },
    );
  }
}
