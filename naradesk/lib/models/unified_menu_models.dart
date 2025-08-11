import 'package:flutter/material.dart';

/// 5단계 권한 레벨 정의
enum PermissionLevel {
  level1, // 최고 관리자
  level2, // 상급 관리자
  level3, // 중급 관리자
  level4, // 일반 직원
  level5; // 제한된 직원

  /// 권한 레벨 표시명
  String get displayName {
    switch (this) {
      case PermissionLevel.level1:
        return '최고 관리자';
      case PermissionLevel.level2:
        return '상급 관리자';
      case PermissionLevel.level3:
        return '중급 관리자';
      case PermissionLevel.level4:
        return '일반 직원';
      case PermissionLevel.level5:
        return '제한된 직원';
    }
  }

  /// 권한 레벨 설명
  String get description {
    switch (this) {
      case PermissionLevel.level1:
        return '모든 기능에 대한 전체 접근 권한';
      case PermissionLevel.level2:
        return '대부분 기능 접근 가능, 시스템 설정 제한';
      case PermissionLevel.level3:
        return '일반 관리 기능 접근 가능';
      case PermissionLevel.level4:
        return '기본 운영 기능만 접근 가능';
      case PermissionLevel.level5:
        return '읽기 전용 및 기본 기능만 접근';
    }
  }

  /// 권한 레벨을 숫자로 반환 (낮을수록 높은 권한)
  int get numericValue {
    switch (this) {
      case PermissionLevel.level1:
        return 1;
      case PermissionLevel.level2:
        return 2;
      case PermissionLevel.level3:
        return 3;
      case PermissionLevel.level4:
        return 4;
      case PermissionLevel.level5:
        return 5;
    }
  }

  /// 특정 레벨 이상의 권한을 가지고 있는지 확인
  bool hasPermissionLevel(PermissionLevel requiredLevel) {
    return numericValue <= requiredLevel.numericValue;
  }
}

/// 메뉴 표시 타입
enum MenuDisplayType {
  horizontal, // 상단 가로 메뉴
  sidebar, // 좌측 사이드바
  mobile, // 모바일 오버레이
}

/// 통합 메뉴 아이템 모델
class UnifiedMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final IconData? subIcon; // 서브메뉴용 아이콘
  final List<UnifiedMenuItem> children;
  final PermissionLevel requiredLevel;
  final bool isAdminOnly;
  final String? tooltip;

  const UnifiedMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subIcon,
    this.children = const [],
    required this.requiredLevel,
    this.isAdminOnly = false,
    this.tooltip,
  });

  /// 현재 사용자가 이 메뉴에 접근 가능한지 확인
  bool isAccessibleFor(PermissionLevel userLevel) {
    return userLevel.hasPermissionLevel(requiredLevel);
  }

  /// 접근 가능한 하위 메뉴만 필터링
  List<UnifiedMenuItem> getAccessibleChildren(PermissionLevel userLevel) {
    return children.where((child) => child.isAccessibleFor(userLevel)).toList();
  }

  /// 하위 메뉴가 있는지 확인
  bool get hasChildren => children.isNotEmpty;

  /// 복사본 생성
  UnifiedMenuItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    IconData? subIcon,
    List<UnifiedMenuItem>? children,
    PermissionLevel? requiredLevel,
    bool? isAdminOnly,
    String? tooltip,
  }) {
    return UnifiedMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      subIcon: subIcon ?? this.subIcon,
      children: children ?? this.children,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      isAdminOnly: isAdminOnly ?? this.isAdminOnly,
      tooltip: tooltip ?? this.tooltip,
    );
  }
}

/// 중앙화된 메뉴 레지스트리
class MenuRegistry {
  static final List<UnifiedMenuItem> _allMenus = [
    UnifiedMenuItem(
      id: 'dashboard',
      title: '대시보드',
      icon: Icons.dashboard,
      requiredLevel: PermissionLevel.level5,
      tooltip: '전체 현황 및 통계',
      children: [
        UnifiedMenuItem(
          id: 'overview',
          title: '전체 현황',
          icon: Icons.analytics,
          requiredLevel: PermissionLevel.level5,
          tooltip: '실시간 현황 보기',
        ),
        UnifiedMenuItem(
          id: 'reports',
          title: '리포트',
          icon: Icons.assessment,
          requiredLevel: PermissionLevel.level4,
          tooltip: '상세 분석 리포트',
        ),
      ],
    ),
    UnifiedMenuItem(
      id: 'seats',
      title: '좌석 관리',
      icon: Icons.event_seat,
      requiredLevel: PermissionLevel.level5,
      tooltip: '좌석 배치 및 관리',
      children: [
        UnifiedMenuItem(
          id: 'seat_layout',
          title: '좌석 배치도',
          icon: Icons.grid_view,
          requiredLevel: PermissionLevel.level5,
          tooltip: '좌석 배치 현황',
        ),
        UnifiedMenuItem(
          id: 'seat_status',
          title: '좌석 현황',
          icon: Icons.list_alt,
          requiredLevel: PermissionLevel.level4,
          tooltip: '실시간 좌석 상태',
        ),
        UnifiedMenuItem(
          id: 'seat_history',
          title: '이용 내역',
          icon: Icons.history,
          requiredLevel: PermissionLevel.level4,
          tooltip: '좌석 이용 기록',
        ),
      ],
    ),
    UnifiedMenuItem(
      id: 'members',
      title: '회원 관리',
      icon: Icons.people,
      requiredLevel: PermissionLevel.level5,
      tooltip: '회원 정보 관리',
      children: [
        UnifiedMenuItem(
          id: 'member_list',
          title: '회원 목록',
          icon: Icons.person,
          requiredLevel: PermissionLevel.level5,
          tooltip: '전체 회원 조회',
        ),
        UnifiedMenuItem(
          id: 'member_register',
          title: '회원 등록',
          icon: Icons.person_add,
          requiredLevel: PermissionLevel.level3,
          tooltip: '신규 회원 등록',
        ),
        UnifiedMenuItem(
          id: 'member_payments',
          title: '결제 내역',
          icon: Icons.payment,
          requiredLevel: PermissionLevel.level4,
          tooltip: '회원 결제 기록',
        ),
        UnifiedMenuItem(
          id: 'member_logs',
          title: '회원 로그',
          icon: Icons.list_alt,
          requiredLevel: PermissionLevel.level4,
          tooltip: '회원 활동 로그',
        ),
      ],
    ),
    UnifiedMenuItem(
      id: 'settings',
      title: '설정',
      icon: Icons.settings,
      requiredLevel: PermissionLevel.level3,
      tooltip: '시스템 설정',
      children: [
        UnifiedMenuItem(
          id: 'general',
          title: '일반 설정',
          icon: Icons.tune,
          requiredLevel: PermissionLevel.level3,
          tooltip: '기본 시스템 설정',
        ),
        UnifiedMenuItem(
          id: 'seat_config',
          title: '좌석 설정',
          icon: Icons.event_seat,
          requiredLevel: PermissionLevel.level2,
          tooltip: '좌석 관련 설정',
        ),
        UnifiedMenuItem(
          id: 'notification',
          title: '알림 설정',
          icon: Icons.notifications,
          requiredLevel: PermissionLevel.level3,
          tooltip: '알림 및 메시지 설정',
        ),
      ],
    ),
    UnifiedMenuItem(
      id: 'admin',
      title: '관리자 기능',
      icon: Icons.admin_panel_settings,
      requiredLevel: PermissionLevel.level2,
      isAdminOnly: true,
      tooltip: '고급 관리 기능',
      children: [
        UnifiedMenuItem(
          id: 'seat_layout_editor',
          title: '좌석 배치도 편집',
          icon: Icons.edit,
          requiredLevel: PermissionLevel.level2,
          tooltip: '좌석 배치 편집기',
        ),
        UnifiedMenuItem(
          id: 'system_settings',
          title: '시스템 설정',
          icon: Icons.settings_applications,
          requiredLevel: PermissionLevel.level1,
          tooltip: '고급 시스템 설정',
        ),
        UnifiedMenuItem(
          id: 'user_management',
          title: '사용자 관리',
          icon: Icons.manage_accounts,
          requiredLevel: PermissionLevel.level1,
          tooltip: '사용자 및 권한 관리',
        ),
        UnifiedMenuItem(
          id: 'server_test',
          title: '서버통신테스트',
          icon: Icons.network_check,
          requiredLevel: PermissionLevel.level2,
          tooltip: 'WebSocket 서버 연결 테스트',
        ),
      ],
    ),
  ];

  /// 모든 메뉴 반환
  static List<UnifiedMenuItem> get allMenus => List.unmodifiable(_allMenus);

  /// 특정 권한 레벨로 접근 가능한 메뉴 반환
  static List<UnifiedMenuItem> getAccessibleMenus(PermissionLevel userLevel) {
    return _allMenus
        .where((menu) => menu.isAccessibleFor(userLevel))
        .map(
          (menu) =>
              menu.copyWith(children: menu.getAccessibleChildren(userLevel)),
        )
        .toList();
  }

  /// 메뉴 ID로 메뉴 찾기
  static UnifiedMenuItem? findById(String id) {
    for (final menu in _allMenus) {
      if (menu.id == id) return menu;

      for (final child in menu.children) {
        if (child.id == id) return child;
      }
    }
    return null;
  }

  /// 특정 메뉴에 접근 가능한지 확인
  static bool canAccessMenu(String menuId, PermissionLevel userLevel) {
    final menu = findById(menuId);
    return menu?.isAccessibleFor(userLevel) ?? true;
  }

  /// 권한 레벨별 접근 가능한 메뉴 ID 목록
  static List<String> getAccessibleMenuIds(PermissionLevel userLevel) {
    final List<String> accessibleIds = [];

    for (final menu in _allMenus) {
      if (menu.isAccessibleFor(userLevel)) {
        accessibleIds.add(menu.id);
        for (final child in menu.children) {
          if (child.isAccessibleFor(userLevel)) {
            accessibleIds.add(child.id);
          }
        }
      }
    }

    return accessibleIds;
  }
}
