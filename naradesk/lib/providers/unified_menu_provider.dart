import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import 'auth_provider.dart';

/// 현재 사용자의 권한 레벨 Provider
final currentPermissionLevelProvider = Provider<PermissionLevel>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.permissionLevel ?? PermissionLevel.level5;
});

/// 권한 기반으로 필터링된 메뉴 Provider
final permissionFilteredMenusProvider = Provider<List<UnifiedMenuItem>>((ref) {
  final userPermissionLevel = ref.watch(currentPermissionLevelProvider);
  return MenuRegistry.getAccessibleMenus(userPermissionLevel);
});

/// 특정 메뉴 접근 권한 확인 Provider (메뉴 ID를 인자로 받음)
final menuAccessProvider = Provider.family<bool, String>((ref, menuId) {
  final userPermissionLevel = ref.watch(currentPermissionLevelProvider);
  return MenuRegistry.canAccessMenu(menuId, userPermissionLevel);
});

/// 접근 가능한 메뉴 ID 목록 Provider
final accessibleMenuIdsProvider = Provider<List<String>>((ref) {
  final userPermissionLevel = ref.watch(currentPermissionLevelProvider);
  return MenuRegistry.getAccessibleMenuIds(userPermissionLevel);
});

/// 권한 레벨별 UI 상태 Provider들
class PermissionUIProviders {
  /// 최고 관리자 권한인지 확인
  static final isSuperAdminProvider = Provider<bool>((ref) {
    final level = ref.watch(currentPermissionLevelProvider);
    return level == PermissionLevel.level1;
  });

  /// 관리자급 권한인지 확인 (level1, level2)
  static final isAdminLevelProvider = Provider<bool>((ref) {
    final level = ref.watch(currentPermissionLevelProvider);
    return level.numericValue <= 2;
  });

  /// 중급 이상 권한인지 확인 (level1, level2, level3)
  static final isManagerLevelProvider = Provider<bool>((ref) {
    final level = ref.watch(currentPermissionLevelProvider);
    return level.numericValue <= 3;
  });

  /// 읽기 전용 사용자인지 확인 (level5)
  static final isReadOnlyUserProvider = Provider<bool>((ref) {
    final level = ref.watch(currentPermissionLevelProvider);
    return level == PermissionLevel.level5;
  });

  /// 현재 사용자 정보 및 권한 요약 Provider
  static final userPermissionSummaryProvider = Provider<Map<String, dynamic>>((ref) {
    final authState = ref.watch(authProvider);
    final level = ref.watch(currentPermissionLevelProvider);
    final accessibleMenus = ref.watch(accessibleMenuIdsProvider);

    return {
      'user': authState.user,
      'permissionLevel': level,
      'permissionName': level.displayName,
      'permissionDescription': level.description,
      'accessibleMenuCount': accessibleMenus.length,
      'totalMenuCount': MenuRegistry.allMenus.fold<int>(
        0,
        (count, menu) => count + 1 + menu.children.length,
      ),
    };
  });
}
