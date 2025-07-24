import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import '../providers/unified_menu_provider.dart';

/// 권한 기반 UI 컨트롤 위젯들
class PermissionBasedWidgets {
  /// 권한이 있을 때만 표시되는 위젯
  static Widget showIfHasPermission({
    required WidgetRef ref,
    required String menuId,
    required Widget child,
    Widget? fallback,
  }) {
    final hasAccess = ref.watch(menuAccessProvider(menuId));
    return hasAccess ? child : (fallback ?? const SizedBox.shrink());
  }

  /// 권한에 따라 다른 위젯을 표시
  static Widget showByPermissionLevel({
    required WidgetRef ref,
    Widget? superAdmin, // Level 1
    Widget? admin, // Level 2
    Widget? manager, // Level 3
    Widget? staff, // Level 4
    Widget? readOnly, // Level 5
    Widget? fallback,
  }) {
    final level = ref.watch(currentPermissionLevelProvider);

    switch (level) {
      case PermissionLevel.level1:
        return superAdmin ?? fallback ?? const SizedBox.shrink();
      case PermissionLevel.level2:
        return admin ?? fallback ?? const SizedBox.shrink();
      case PermissionLevel.level3:
        return manager ?? fallback ?? const SizedBox.shrink();
      case PermissionLevel.level4:
        return staff ?? fallback ?? const SizedBox.shrink();
      case PermissionLevel.level5:
        return readOnly ?? fallback ?? const SizedBox.shrink();
    }
  }

  /// 권한 정보를 표시하는 위젯
  static Widget permissionBadge(WidgetRef ref) {
    final summary = ref.watch(PermissionUIProviders.userPermissionSummaryProvider);
    final level = summary['permissionLevel'] as PermissionLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPermissionColor(level).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPermissionColor(level).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPermissionIcon(level), size: 14, color: _getPermissionColor(level)),
          const SizedBox(width: 4),
          Text(
            summary['permissionName'] as String,
            style: TextStyle(
              fontSize: 12,
              color: _getPermissionColor(level),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 권한별 색상
  static Color _getPermissionColor(PermissionLevel level) {
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

  /// 권한별 아이콘
  static IconData _getPermissionIcon(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.level1:
        return Icons.admin_panel_settings;
      case PermissionLevel.level2:
        return Icons.manage_accounts;
      case PermissionLevel.level3:
        return Icons.supervisor_account;
      case PermissionLevel.level4:
        return Icons.person;
      case PermissionLevel.level5:
        return Icons.visibility;
    }
  }
}

/// 권한 기반 버튼 위젯
class PermissionButton extends ConsumerWidget {
  final String requiredMenuId;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final String? disabledTooltip;

  const PermissionButton({
    super.key,
    required this.requiredMenuId,
    required this.onPressed,
    required this.child,
    this.style,
    this.disabledTooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(menuAccessProvider(requiredMenuId));

    if (!hasAccess) {
      return Tooltip(
        message: disabledTooltip ?? '접근 권한이 없습니다',
        child: ElevatedButton(onPressed: null, style: style, child: child),
      );
    }

    return ElevatedButton(onPressed: onPressed, style: style, child: child);
  }
}
