import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import '../models/unified_route_registry.dart';
import '../utils/app_logger.dart';

// 현재 활성화된 화면을 관리하는 프로바이더
final currentScreenProvider = StateNotifierProvider<CurrentScreenNotifier, String>((ref) {
  return CurrentScreenNotifier();
});

class CurrentScreenNotifier extends StateNotifier<String> {
  CurrentScreenNotifier() : super('seat_layout'); // 기본 화면을 좌석 배치도로 설정

  void navigateTo(String screenId) {
    // 라우트가 존재하는지 확인
    final route = RouteRegistry.findById(screenId);
    if (route != null) {
      AppLogger.navigation(state, screenId);
      state = screenId;
    } else {
      // 라우트가 없으면 기본 화면으로 이동
      AppLogger.warning('Route $screenId not found, redirecting to default route', 'NAVIGATION');
      AppLogger.navigation(screenId, 'seat_layout', 'route not found');
      state = 'seat_layout';
    }
  }

  void navigateToDefault(PermissionLevel userLevel) {
    final defaultRoute = RouteRegistry.getDefaultRoute(userLevel);
    AppLogger.navigation(state, defaultRoute, 'navigating to default for ${userLevel.displayName}');
    state = defaultRoute;
  }

  void reset() {
    state = 'seat_layout';
  }

  // 권한 기반 네비게이션
  void navigateWithPermission(String screenId, PermissionLevel userLevel) {
    if (RouteRegistry.canAccessRoute(screenId, userLevel)) {
      navigateTo(screenId);
    } else {
      // 권한이 없으면 기본 화면으로 이동
      AppLogger.permission('access denied', screenId, false);
      AppLogger.warning('User does not have permission to access $screenId', 'PERMISSION');
      navigateToDefault(userLevel);
    }
  }
}
