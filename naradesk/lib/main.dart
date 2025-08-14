import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// 조건부 import: 웹에서는 stub, 다른 플랫폼에서는 실제 dart:io 사용
import 'utils/platform_stub.dart' if (dart.library.io) 'utils/platform_io.dart';

// 조건부 import: 웹에서는 stub, 다른 플랫폼에서는 실제 window_manager 사용
import 'utils/window_manager_stub.dart' if (dart.library.io) 'utils/window_manager_io.dart';

import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_layout_responsive.dart';
import 'services/api_service.dart';
import 'utils/font_theme_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // API 서비스 초기화
  ApiService.setupInterceptors();

  // 웹이 아닌 데스크톱 플랫폼에서만 window manager 초기화
  if (!kIsWeb) {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await windowManager.ensureInitialized();
        
        WindowOptions windowOptions = const WindowOptions(
          size: Size(1920, 1080), // 다시 큰 크기로 설정
          minimumSize: Size(800, 600),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.normal, // 타이틀바 유지
        );
        
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
          // maximize 호출을 약간 지연시켜 안정성 확보
          Future.delayed(const Duration(milliseconds: 100), () async {
            await windowManager.maximize();
          });
          await windowManager.setPreventClose(true); // 종료 확인 활성화
        });
      }
    } catch (e) {
      // 플랫폼이 지원되지 않는 경우 무시
      print('Window manager not supported on this platform: $e');
    }
  }

  runApp(const ProviderScope(child: StudyCafeApp()));
}

class StudyCafeApp extends ConsumerStatefulWidget {
  const StudyCafeApp({super.key});

  @override
  ConsumerState<StudyCafeApp> createState() => _StudyCafeAppState();
}

class _StudyCafeAppState extends ConsumerState<StudyCafeApp> with WindowListener {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // 웹이 아닌 데스크톱에서만 WindowListener 등록
    if (!kIsWeb) {
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          windowManager.addListener(this);
        }
      } catch (e) {
        // 플랫폼이 지원되지 않는 경우 무시
      }
    }
  }

  @override
  void dispose() {
    // 웹이 아닌 데스크톱에서만 WindowListener 해제
    if (!kIsWeb) {
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          windowManager.removeListener(this);
        }
      } catch (e) {
        // 플랫폼이 지원되지 않는 경우 무시
      }
    }
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    final shouldClose = await _showExitConfirmDialog();
    if (shouldClose) {
      // 빠른 종료를 위해 preventClose 해제 후 즉시 종료
      await windowManager.setPreventClose(false);
      if (!kIsWeb) {
        exit(0); // 데스크톱에서만 강제 종료
      } else {
        await windowManager.destroy();
      }
    }
  }

  Future<bool> _showExitConfirmDialog() async {
    final context = navigatorKey.currentContext;
    if (context == null) return true; // 컨텍스트가 없으면 그냥 종료
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부 클릭으로 닫기 방지
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 12),
            Text('앱 종료'),
          ],
        ),
        content: const Text('정말로 앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('종료'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeState = ref.watch(fontSizeProvider);
    final currentFontSize = fontSizeState.currentLevel.baseSize;
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final lightTheme = themeNotifier.lightTheme.copyWith(
      // 폰트크기 설정을 테마에 적용 (라이트 모드 색상)
      textTheme: FontThemeUtils.buildTextTheme(currentFontSize, isDark: false),
    );

    final darkTheme = themeNotifier.darkTheme.copyWith(
      // 폰트크기 설정을 테마에 적용 (다크 모드 색상)
      textTheme: FontThemeUtils.buildTextTheme(currentFontSize, isDark: true),
    );

    return MaterialApp(
      navigatorKey: navigatorKey, // GlobalKey 추가
      title: 'Study Cafe Manager',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeState.themeMode == AppThemeMode.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // 강력한 최소 크기 제약 적용
        return Container(
          constraints: const BoxConstraints(
            minWidth: AppConstants.minAppWidth,
            minHeight: AppConstants.minAppHeight,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 제약 조건이 최소 크기보다 작으면 강제로 최소 크기 적용
              final width = constraints.maxWidth < AppConstants.minAppWidth 
                  ? AppConstants.minAppWidth 
                  : constraints.maxWidth;
              final height = constraints.maxHeight < AppConstants.minAppHeight 
                  ? AppConstants.minAppHeight 
                  : constraints.maxHeight;
              
              return SizedBox(
                width: width,
                height: height,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget child = authState.isAuthenticated 
        ? const MainLayout() 
        : const LoginScreen();

    // 웹이 아닌 모바일에서만 PopScope 적용
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              
              final shouldPop = await _showExitConfirmDialog(context);
              if (shouldPop) {
                // 앱을 완전히 종료
                SystemNavigator.pop();
              }
            },
            child: child,
          );
        }
      } catch (e) {
        // 플랫폼이 지원되지 않는 경우 무시
      }
    }

    // 웹과 데스크톱에서는 그냥 child 반환
    return child;
  }

  Future<bool> _showExitConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 12),
            Text('앱 종료'),
          ],
        ),
        content: const Text('정말로 앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('종료'),
          ),
        ],
      ),
    ) ?? false;
  }
}
