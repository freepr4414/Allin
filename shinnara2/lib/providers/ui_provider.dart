import 'package:flutter_riverpod/flutter_riverpod.dart';

// UI 상태 관리

// 사이드 패널 타입
enum SidePanelType {
  dashboard, // 대시보드
  members, // 회원 관리
  payments, // 결제 관리
  statistics, // 통계
  settings, // 설정
}

extension SidePanelTypeExtension on SidePanelType {
  String get title {
    switch (this) {
      case SidePanelType.dashboard:
        return '대시보드';
      case SidePanelType.members:
        return '회원 관리';
      case SidePanelType.payments:
        return '결제 관리';
      case SidePanelType.statistics:
        return '통계';
      case SidePanelType.settings:
        return '설정';
    }
  }

  String get description {
    switch (this) {
      case SidePanelType.dashboard:
        return '전체 현황을 한눈에 확인하세요';
      case SidePanelType.members:
        return '회원 정보를 관리하세요';
      case SidePanelType.payments:
        return '결제 내역을 확인하세요';
      case SidePanelType.statistics:
        return '상세한 통계를 확인하세요';
      case SidePanelType.settings:
        return '시스템 설정을 관리하세요';
    }
  }
}

// 메뉴 아이템 타입
enum MenuItemType {
  dashboard,
  seatManagement,
  userManagement,
  paymentManagement,
  statistics,
  settings,
  notifications,
}

extension MenuItemTypeExtension on MenuItemType {
  String get title {
    switch (this) {
      case MenuItemType.dashboard:
        return '대시보드';
      case MenuItemType.seatManagement:
        return '좌석 관리';
      case MenuItemType.userManagement:
        return '회원 관리';
      case MenuItemType.paymentManagement:
        return '결제 관리';
      case MenuItemType.statistics:
        return '통계';
      case MenuItemType.settings:
        return '설정';
      case MenuItemType.notifications:
        return '알림';
    }
  }
}

// 선택된 사이드 패널 상태
final selectedSidePanelProvider = StateProvider<SidePanelType?>((ref) => null);

// 네비게이션 메뉴 표시 상태
final showNavigationMenuProvider = StateProvider<bool>((ref) => false);

// 선택된 메뉴 아이템
final selectedMenuItemProvider = StateProvider<MenuItemType?>((ref) => null);

// 알림 개수
final notificationCountProvider = StateProvider<int>((ref) => 3);

// 로딩 상태
final isLoadingProvider = StateProvider<bool>((ref) => false);
