import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ui_provider.dart';
import '../utils/responsive.dart';
import '../widgets/horizontal_navigation_menu.dart';
import '../widgets/navigation_menu.dart';
import '../widgets/side_panel.dart';

class ResponsiveLayout extends ConsumerStatefulWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

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
              _buildHeader(),
              // 메인 콘텐츠
              Expanded(child: widget.child),
              // 하단 푸터
              _buildFooter(),
            ],
          ),

          // 좌측 사이드바 오버레이 (모바일 - 전체 화면)
          if (_isLeftSidebarOpen) _buildMobileSidebarOverlay(),

          // 우측 사이드바 오버레이
          if (_isRightSidebarOpen) _buildMobileRightSidebarOverlay(),
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
              _buildHeader(),
              // 메인 콘텐츠
              Expanded(child: widget.child),
              // 하단 푸터
              _buildFooter(),
            ],
          ),

          // 좌측 사이드바 오버레이 (태블릿 - 적당한 크기)
          if (_isLeftSidebarOpen) _buildTabletSidebarOverlay(),

          // 우측 사이드바 오버레이
          if (_isRightSidebarOpen) _buildTabletRightSidebarOverlay(),
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
                      Expanded(child: widget.child),
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
      child: Responsive.isDesktop(context) ? _buildDesktopHeader() : _buildMobileTabletHeader(),
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.getResponsivePadding(context)),
      child: Row(
        children: [
          // 로고/타이틀 (호버 효과 추가)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // TODO: 홈페이지로 이동 또는 새로고침
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('홈으로 이동')));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Study Cafe Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 40), // 로고와 메뉴 사이 간격
          // 가로 메뉴 (중앙)
          Expanded(
            child: HorizontalNavigationMenu(
              onDropdownChanged: (dropdownId) {
                setState(() {
                  _isDropdownOpen = dropdownId != null;
                });
              },
              onDropdownContentChanged: (content) {
                setState(() {
                  _dropdownContent = content;
                });
              },
              onRegisterCloseCallback: (closeCallback) {
                _closeMenuDropdown = closeCallback;
              },
            ),
          ),

          // 우측 액션 버튼들 (호버 효과 추가)
          Row(
            children: [
              _buildHoverIconButton(
                icon: Icons.notifications,
                tooltip: '알림',
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('알림 기능')));
                },
              ),
              _buildHoverIconButton(
                icon: Icons.settings,
                tooltip: '설정',
                onPressed: () {
                  setState(() {
                    _isRightSidebarOpen = !_isRightSidebarOpen;
                  });
                },
              ),
              _buildHoverIconButton(
                icon: Icons.account_circle,
                tooltip: '계정',
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('계정 메뉴')));
                },
              ),
            ],
          ),
        ],
      ),
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
  Widget _buildMobileSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isLeftSidebarOpen = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withValues(alpha: 0.5),
        child: Row(
          children: [
            // 사이드바 (85% 너비)
            GestureDetector(
              onTap: () {}, // 사이드바 클릭 시 닫히지 않도록
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85, // 85% 너비
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: NavigationMenu(
                  onMenuItemSelected: () => setState(() => _isLeftSidebarOpen = false),
                ),
              ),
            ),
            // 빈 공간 (탭하면 닫기)
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  // 모바일 우측 사이드바 오버레이
  Widget _buildMobileRightSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isRightSidebarOpen = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withValues(alpha: 0.5),
        child: Row(
          children: [
            // 빈 공간 (탭하면 닫기)
            Expanded(child: Container()),
            // 사이드바
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: SidePanel(type: SidePanelType.settings),
            ),
          ],
        ),
      ),
    );
  }

  // 태블릿 사이드바 오버레이 (고정 너비)
  Widget _buildTabletSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isLeftSidebarOpen = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withValues(alpha: 0.3),
        child: Row(
          children: [
            // 사이드바 (고정 너비)
            GestureDetector(
              onTap: () {}, // 사이드바 클릭 시 닫히지 않도록
              child: Container(
                width: 320, // 태블릿에서 적당한 크기
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: NavigationMenu(
                  onMenuItemSelected: () => setState(() => _isLeftSidebarOpen = false),
                ),
              ),
            ),
            // 빈 공간 (탭하면 닫기)
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  // 태블릿 우측 사이드바 오버레이
  Widget _buildTabletRightSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isRightSidebarOpen = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withValues(alpha: 0.3),
        child: Row(
          children: [
            // 빈 공간 (탭하면 닫기)
            Expanded(child: Container()),
            // 사이드바
            Container(
              width: 320,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: SidePanel(type: SidePanelType.settings),
            ),
          ],
        ),
      ),
    );
  }

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

  // 호버 효과가 있는 아이콘 버튼 위젯
  Widget _buildHoverIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            hoverColor: Colors.white.withValues(alpha: 0.1),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
