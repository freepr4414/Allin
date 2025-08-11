import 'package:flutter/material.dart';

import '../screens/admin/server_test_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/members/member_list_screen.dart';
import '../screens/members/member_log_screen.dart';
import '../screens/members/payment_list_screen.dart';
import '../screens/seat/seat_layout_screen.dart';
import '../screens/seat_layout_editor.dart';
import 'unified_menu_models.dart';

/// 페이지 라우트 정의
class RouteDefinition {
  final String id;
  final String title;
  final Widget Function() builder;
  final PermissionLevel requiredLevel;
  final String? description;

  const RouteDefinition({
    required this.id,
    required this.title,
    required this.builder,
    required this.requiredLevel,
    this.description,
  });

  /// 현재 사용자가 이 페이지에 접근 가능한지 확인
  bool isAccessibleFor(PermissionLevel userLevel) {
    return userLevel.hasPermissionLevel(requiredLevel);
  }
}

/// 중앙화된 라우트 레지스트리
class RouteRegistry {
  static final Map<String, RouteDefinition> _routes = {
    // 대시보드 관련
    'overview': RouteDefinition(
      id: 'overview',
      title: '전체 현황',
      builder: () => const DashboardScreen(),
      requiredLevel: PermissionLevel.level5,
      description: '실시간 현황 및 통계 대시보드',
    ),
    'reports': RouteDefinition(
      id: 'reports',
      title: '리포트',
      builder: () => const DashboardScreen(),
      requiredLevel: PermissionLevel.level4,
      description: '상세 분석 리포트',
    ),

    // 좌석 관리 관련
    'seat_layout': RouteDefinition(
      id: 'seat_layout',
      title: '좌석 배치도',
      builder: () => const SeatLayoutScreen(),
      requiredLevel: PermissionLevel.level5,
      description: '좌석 배치 현황 및 관리',
    ),
    'seat_status': RouteDefinition(
      id: 'seat_status',
      title: '좌석 현황',
      builder: () => const SeatLayoutScreen(),
      requiredLevel: PermissionLevel.level4,
      description: '실시간 좌석 상태 조회',
    ),
    'seat_history': RouteDefinition(
      id: 'seat_history',
      title: '이용 내역',
      builder: () => const SeatLayoutScreen(),
      requiredLevel: PermissionLevel.level4,
      description: '좌석 이용 기록 조회',
    ),

    // 회원 관리 관련
    'member_list': RouteDefinition(
      id: 'member_list',
      title: '회원 목록',
      builder: () => const MemberListScreen(),
      requiredLevel: PermissionLevel.level5,
      description: '전체 회원 정보 조회',
    ),
    'member_register': RouteDefinition(
      id: 'member_register',
      title: '회원 등록',
      builder: () =>
          const _PlaceholderScreen(title: '회원 등록', subtitle: '신규 회원 등록 화면입니다.'),
      requiredLevel: PermissionLevel.level3,
      description: '신규 회원 등록',
    ),
    'member_payments': RouteDefinition(
      id: 'member_payments',
      title: '결제 내역',
      builder: () => const PaymentListScreen(),
      requiredLevel: PermissionLevel.level4,
      description: '회원 결제 기록 조회',
    ),
    'member_logs': RouteDefinition(
      id: 'member_logs',
      title: '회원 로그',
      builder: () => const MemberLogScreen(),
      requiredLevel: PermissionLevel.level4,
      description: '회원 활동/접속 로그 조회',
    ),

    // 설정 관련
    'general': RouteDefinition(
      id: 'general',
      title: '일반 설정',
      builder: () => const _PlaceholderScreen(
        title: '일반 설정',
        subtitle: '기본 시스템 설정을 관리합니다.',
      ),
      requiredLevel: PermissionLevel.level3,
      description: '기본 시스템 설정',
    ),
    'seat_config': RouteDefinition(
      id: 'seat_config',
      title: '좌석 설정',
      builder: () => const _PlaceholderScreen(
        title: '좌석 설정',
        subtitle: '좌석 관련 설정을 관리합니다.',
      ),
      requiredLevel: PermissionLevel.level2,
      description: '좌석 관련 설정',
    ),
    'notification': RouteDefinition(
      id: 'notification',
      title: '알림 설정',
      builder: () => const _PlaceholderScreen(
        title: '알림 설정',
        subtitle: '알림 및 메시지 설정을 관리합니다.',
      ),
      requiredLevel: PermissionLevel.level3,
      description: '알림 및 메시지 설정',
    ),

    // 관리자 기능 관련
    'seat_layout_editor': RouteDefinition(
      id: 'seat_layout_editor',
      title: '좌석 배치도 편집',
      builder: () => const SeatLayoutEditor(),
      requiredLevel: PermissionLevel.level2,
      description: '좌석 배치 편집 도구',
    ),
    'system_settings': RouteDefinition(
      id: 'system_settings',
      title: '시스템 설정',
      builder: () => const _PlaceholderScreen(
        title: '시스템 설정',
        subtitle: '고급 시스템 설정을 관리합니다.',
      ),
      requiredLevel: PermissionLevel.level1,
      description: '고급 시스템 설정',
    ),
    'user_management': RouteDefinition(
      id: 'user_management',
      title: '사용자 관리',
      builder: () => const _PlaceholderScreen(
        title: '사용자 관리',
        subtitle: '사용자 및 권한을 관리합니다.',
      ),
      requiredLevel: PermissionLevel.level1,
      description: '사용자 및 권한 관리',
    ),
    'server_test': RouteDefinition(
      id: 'server_test',
      title: '서버통신테스트',
      builder: () => const ServerTestScreen(),
      requiredLevel: PermissionLevel.level2,
      description: 'WebSocket 서버 연결 테스트 및 통신 상태 확인',
    ),
  };

  /// 모든 라우트 반환
  static Map<String, RouteDefinition> get allRoutes =>
      Map.unmodifiable(_routes);

  /// 라우트 ID로 라우트 찾기
  static RouteDefinition? findById(String id) {
    return _routes[id];
  }

  /// 특정 권한 레벨로 접근 가능한 라우트 반환
  static Map<String, RouteDefinition> getAccessibleRoutes(
    PermissionLevel userLevel,
  ) {
    return Map.fromEntries(
      _routes.entries.where((entry) => entry.value.isAccessibleFor(userLevel)),
    );
  }

  /// 특정 라우트에 접근 가능한지 확인
  static bool canAccessRoute(String routeId, PermissionLevel userLevel) {
    final route = findById(routeId);
    return route?.isAccessibleFor(userLevel) ?? true;
  }

  /// 권한에 따른 기본 라우트 반환
  static String getDefaultRoute(PermissionLevel userLevel) {
    // 권한별 기본 페이지 설정
    switch (userLevel) {
      case PermissionLevel.level1:
      case PermissionLevel.level2:
        return 'overview'; // 관리자는 대시보드부터
      case PermissionLevel.level3:
      case PermissionLevel.level4:
      case PermissionLevel.level5:
        return 'seat_layout'; // 일반 사용자는 좌석 배치도부터
    }
  }

  /// 페이지 빌더 반환
  static Widget buildPage(String routeId, PermissionLevel userLevel) {
    final route = findById(routeId);

    if (route == null) {
      return _PlaceholderScreen(
        title: '페이지를 찾을 수 없음',
        subtitle: '요청하신 페이지($routeId)를 찾을 수 없습니다.',
        isError: true,
      );
    }

    if (!route.isAccessibleFor(userLevel)) {
      return _PlaceholderScreen(
        title: '접근 권한 없음',
        subtitle:
            '이 페이지에 접근할 권한이 없습니다.\n필요 권한: ${route.requiredLevel.displayName}',
        isError: true,
      );
    }

    return route.builder();
  }

  /// 라우트 추가/업데이트 (동적 라우트 지원)
  static void registerRoute(String id, RouteDefinition route) {
    _routes[id] = route;
  }

  /// 라우트 제거
  static void unregisterRoute(String id) {
    _routes.remove(id);
  }
}

/// 플레이스홀더 화면 위젯
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isError;

  const _PlaceholderScreen({
    required this.title,
    required this.subtitle,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError
                  ? Colors.red.withValues(alpha: 0.3)
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.construction,
                size: 64,
                color: isError ? Colors.red : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isError
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (!isError) ...[
                const SizedBox(height: 24),
                Text(
                  '구현 예정',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
