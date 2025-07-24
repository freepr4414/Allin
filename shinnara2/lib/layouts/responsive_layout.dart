import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../providers/ui_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/members/member_list_screen.dart';
import '../screens/members/payment_list_screen.dart';
import '../screens/seat/seat_layout_screen.dart';
import '../utils/responsive.dart';
import '../widgets/side_panel.dart';
import 'components/header/desktop_header.dart';
import 'components/header/mobile_header.dart';
import 'components/sidebar/sidebar_overlay.dart';

class ResponsiveLayout extends ConsumerStatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  ConsumerState<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends ConsumerState<ResponsiveLayout> {
  bool _isLeftSidebarOpen = false;
  bool _isRightSidebarOpen = false;
  bool _isDropdownOpen = false;
  Widget? _dropdownContent;
  VoidCallback? _closeMenuDropdown;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return _buildMobileLayout();
    } else if (Responsive.isTablet(context)) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // 기본 레이아웃
          Column(
            children: [
              // 상단 헤더
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF3498DB), const Color(0xFF2980B9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MobileHeader(
                  onToggleLeftSidebar: () =>
                      setState(() => _isLeftSidebarOpen = !_isLeftSidebarOpen),
                  onToggleRightSidebar: () =>
                      setState(() => _isRightSidebarOpen = !_isRightSidebarOpen),
                ),
              ),
              // 메인 콘텐츠
              Expanded(child: _getCurrentScreen()),
              // 하단 푸터
              _buildFooter(),
            ],
          ),

          // 사이드바 오버레이
          SidebarOverlay(
            isLeftVisible: _isLeftSidebarOpen,
            isRightVisible: _isRightSidebarOpen,
            onToggleLeft: () => setState(() => _isLeftSidebarOpen = false),
            onToggleRight: () => setState(() => _isRightSidebarOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // 기본 레이아웃
          Column(
            children: [
              // 상단 헤더
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF3498DB), const Color(0xFF2980B9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MobileHeader(
                  onToggleLeftSidebar: () =>
                      setState(() => _isLeftSidebarOpen = !_isLeftSidebarOpen),
                  onToggleRightSidebar: () =>
                      setState(() => _isRightSidebarOpen = !_isRightSidebarOpen),
                ),
              ),
              // 메인 콘텐츠
              Expanded(child: _getCurrentScreen()),
              // 하단 푸터
              _buildFooter(),
            ],
          ),

          // 사이드바 오버레이
          SidebarOverlay(
            isLeftVisible: _isLeftSidebarOpen,
            isRightVisible: _isRightSidebarOpen,
            onToggleLeft: () => setState(() => _isLeftSidebarOpen = false),
            onToggleRight: () => setState(() => _isRightSidebarOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GestureDetector(
        onTap: () {
          if (_isDropdownOpen) {
            _closeMenuDropdown?.call(); // 메뉴의 드롭다운 상태도 초기화
            setState(() {
              _isDropdownOpen = false;
              _dropdownContent = null;
            });
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // 기본 레이아웃 (헤더 + 메인 콘텐츠 + 푸터)
            Column(
              children: [
                // 상단 헤더 (메뉴 포함)
                _buildHeader(),
                // 메인 영역
                Expanded(
                  child: Row(
                    children: [
                      // 중앙 콘텐츠 (좌측 사이드바 제거)
                      Expanded(child: _getCurrentScreen()),
                      // 우측 사이드바 (조건부 표시)
                      if (_isRightSidebarOpen) SizedBox(width: 300, child: _buildRightSidebar()),
                    ],
                  ),
                ),
                // 하단 푸터
                _buildFooter(),
              ],
            ),
            // 드롭다운 오버레이 (헤더 바로 아래에 위치)
            if (_isDropdownOpen)
              Positioned(
                top: Responsive.getResponsiveValue(
                  context,
                  mobile: 55,
                  tablet: 65,
                  desktop: 75,
                ), // 헤더보다 5px 위로 올림
                left: 0,
                right: 0,
                child: _buildDropdownArea(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: Responsive.getResponsiveValue(
        context,
        mobile: 60,
        tablet: 70,
        desktop: 80, // 데스크탑도 1단으로 통일
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Responsive.isDesktop(context)
          ? DesktopHeader(
              onToggleRightSidebar: () =>
                  setState(() => _isRightSidebarOpen = !_isRightSidebarOpen),
              onDropdownChanged: (dropdownId) =>
                  setState(() => _isDropdownOpen = dropdownId != null),
              onDropdownContentChanged: (content) => setState(() => _dropdownContent = content),
              onRegisterCloseCallback: (closeCallback) => _closeMenuDropdown = closeCallback,
            )
          : _buildMobileTabletHeader(),
    );
  }

  Widget _buildMobileTabletHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.getResponsivePadding(context)),
      child: Row(
        children: [
          // 메뉴 버튼 (모바일/태블릿)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLeftSidebarOpen = !_isLeftSidebarOpen;
              });
            },
          ),

          const SizedBox(width: 16),

          // 로고/타이틀
          Text(
            'Study Cafe Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 20),
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // 우측 액션 버튼들
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isRightSidebarOpen = !_isRightSidebarOpen;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SidePanel(type: SidePanelType.settings),
    );
  }

  // 모바일 사이드바 오버레이 (전체 화면)
  Widget _buildFooter() {
    return Container(
      height: Responsive.getResponsiveValue(context, mobile: 40, tablet: 50, desktop: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Center(
        child: Text(
          '© 2025 Study Cafe Manager - 하단 영역 (차후 사용)',
          style: TextStyle(
            fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 12),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownArea() {
    if (_dropdownContent == null) return const SizedBox.shrink();

    return _dropdownContent!;
  }

  // 현재 화면 반환
  Widget _getCurrentScreen() {
    final currentScreen = ref.watch(currentScreenProvider);

    switch (currentScreen) {
      case 'overview':
      case 'reports':
        return const DashboardScreen();
      case 'seat_layout':
      case 'seat_status':
      case 'seat_history':
        return const SeatLayoutScreen();
      case 'member_list':
        return const MemberListScreen();
      case 'member_register':
        return const Center(
          child: Text(
            '회원 등록 화면\n(구현 예정)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      case 'member_payments':
        return const PaymentListScreen();
      case 'general':
      case 'seat_config':
      case 'notification':
        return const Center(
          child: Text(
            '설정 화면\n(구현 예정)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      default:
        return const SeatLayoutScreen(); // 기본 화면
    }
  }
}
