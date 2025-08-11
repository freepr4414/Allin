import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/unified_menu_models.dart';
import '../../providers/auth_provider.dart';
import '../../styles/app_styles.dart';

/// 권한 기반 위젯 표시/숨김 제어
class PermissionWidget extends ConsumerWidget {
  final PermissionLevel required;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;
  final String? feature;

  const PermissionWidget({
    super.key,
    required this.required,
    required this.child,
    this.fallback,
    this.showFallback = true,
    this.feature,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userLevel = authState.user?.permissionLevel ?? PermissionLevel.level5;

    if (userLevel.hasPermissionLevel(required)) {
      return child;
    } else if (showFallback) {
      return fallback ?? _buildDefaultFallback(context);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDefaultFallback(BuildContext context) {
    final featureName = feature ?? '이 기능';
    return Container(
      padding: AppStyles.defaultPadding,
      decoration: AppStyles.cardDecorationWithTheme(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.accessDenied,
            style: AppStyles.titleTextStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.permissionDeniedForFeature(featureName),
            style: AppStyles.bodyTextStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.permissionRequired}: ${required.displayName}',
            style: AppStyles.captionTextStyle(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 권한 확인용 빌더 위젯
class PermissionBuilder extends ConsumerWidget {
  final Widget Function(
    BuildContext context,
    bool hasPermission,
    PermissionLevel userLevel,
  )
  builder;
  final PermissionLevel required;

  const PermissionBuilder({
    super.key,
    required this.builder,
    required this.required,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userLevel = authState.user?.permissionLevel ?? PermissionLevel.level5;
    final hasPermission = userLevel.hasPermissionLevel(required);

    return builder(context, hasPermission, userLevel);
  }
}

/// 권한별 스타일 적용 위젯
class PermissionStyledWidget extends ConsumerWidget {
  final Widget child;
  final Map<PermissionLevel, BoxDecoration>? decorations;
  final Map<PermissionLevel, Color>? colors;
  final EdgeInsets? padding;

  const PermissionStyledWidget({
    super.key,
    required this.child,
    this.decorations,
    this.colors,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userLevel = authState.user?.permissionLevel ?? PermissionLevel.level5;

    final decoration = decorations?[userLevel];
    final color = colors?[userLevel];

    return Container(
      decoration:
          decoration ??
          (color != null
              ? AppStyles.cardDecorationWithColor(color)
              : AppStyles.cardDecorationWithTheme(context)),
      padding: padding ?? AppStyles.defaultPadding,
      child: child,
    );
  }
}

/// 관리자 전용 위젯
class AdminOnlyWidget extends PermissionWidget {
  const AdminOnlyWidget({
    super.key,
    required super.child,
    super.fallback,
    super.showFallback,
    super.feature,
  }) : super(required: PermissionLevel.level2);
}

/// 최고 관리자 전용 위젯
class SuperAdminOnlyWidget extends PermissionWidget {
  const SuperAdminOnlyWidget({
    super.key,
    required super.child,
    super.fallback,
    super.showFallback,
    super.feature,
  }) : super(required: PermissionLevel.level1);
}

/// 권한 레벨 표시 배지
class PermissionBadge extends ConsumerWidget {
  final bool showLevel;
  final bool showName;
  final EdgeInsets? padding;

  const PermissionBadge({
    super.key,
    this.showLevel = true,
    this.showName = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userLevel = authState.user?.permissionLevel ?? PermissionLevel.level5;

    String text = '';
    if (showLevel && showName) {
      text = 'Lv.${userLevel.numericValue} ${userLevel.displayName}';
    } else if (showLevel) {
      text = 'Lv.${userLevel.numericValue}';
    } else if (showName) {
      text = userLevel.displayName;
    }

    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPermissionColor(userLevel),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getPermissionColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.level1:
        return Colors.red;
      case PermissionLevel.level2:
        return Colors.orange;
      case PermissionLevel.level3:
        return Colors.blue;
      case PermissionLevel.level4:
        return Colors.green;
      case PermissionLevel.level5:
        return Colors.grey;
    }
  }
}

/// 권한 체크 믹신
mixin PermissionCheckMixin {
  bool hasPermission(PermissionLevel userLevel, PermissionLevel required) {
    return userLevel.hasPermissionLevel(required);
  }

  bool isAdmin(PermissionLevel userLevel) {
    return hasPermission(userLevel, PermissionLevel.level2);
  }

  bool isSuperAdmin(PermissionLevel userLevel) {
    return hasPermission(userLevel, PermissionLevel.level1);
  }

  bool canAccessFeature(PermissionLevel userLevel, String featureId) {
    // 기능별 권한 매핑 (필요에 따라 확장)
    final featurePermissions = {
      'seat_layout_editor': PermissionLevel.level2,
      'system_settings': PermissionLevel.level1,
      'user_management': PermissionLevel.level1,
      'member_register': PermissionLevel.level3,
      'reports': PermissionLevel.level4,
      // 더 많은 기능 추가 가능
    };

    final required = featurePermissions[featureId] ?? PermissionLevel.level5;
    return hasPermission(userLevel, required);
  }
}
