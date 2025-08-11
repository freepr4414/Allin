import 'package:flutter/foundation.dart';

/// 통일된 로깅 시스템
class AppLogger {
  static const String _prefix = '[StudyCafeApp]';
  
  // 로그 출력 제어 설정
  static const bool _enableNavigation = false;  // 네비게이션 로그 활성화 여부
  static const bool _enableScreenInfo = false;  // 화면 정보 로그 활성화 여부
  static const bool _enableSeatLayoutInfo = false;  // 좌석 배치도 정보 로그 활성화 여부

  /// 디버그 로그 (개발용)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagString = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagString DEBUG: $message');
    }
  }

  /// 정보 로그
  static void info(String message, [String? tag]) {
    final tagString = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagString INFO: $message');
  }

  /// 경고 로그
  static void warning(String message, [String? tag]) {
    final tagString = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagString WARNING: $message');
  }

  /// 에러 로그
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    final tagString = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagString ERROR: $message');

    if (error != null) {
      debugPrint('$_prefix$tagString ERROR Details: $error');
    }

    if (stackTrace != null && kDebugMode) {
      debugPrint('$_prefix$tagString Stack Trace: $stackTrace');
    }
  }

  /// 네비게이션 로그
  static void navigation(String from, String to, [String? reason]) {
    if (kDebugMode && _enableNavigation) {
      final reasonString = reason != null ? ' ($reason)' : '';
      info('Navigation: $from → $to$reasonString', 'NAV');
    }
  }
  
  /// 화면 정보 로그
  static void screenInfo(String message) {
    if (kDebugMode && _enableScreenInfo) {
      debug(message, 'SCREEN');
    }
  }
  
  /// 좌석 배치도 정보 로그
  static void seatLayoutInfo(String message) {
    if (kDebugMode && _enableSeatLayoutInfo) {
      debug(message, 'SEAT');
    }
  }

  /// 권한 관련 로그
  static void permission(String action, String permission, bool granted) {
    final status = granted ? 'GRANTED' : 'DENIED';
    info('Permission $action: $permission - $status', 'PERMISSION');
  }

  /// 사용자 액션 로그
  static void userAction(String action, [Map<String, dynamic>? data]) {
    final dataString = data != null ? ' ${data.toString()}' : '';
    info('User Action: $action$dataString', 'USER');
  }
}
