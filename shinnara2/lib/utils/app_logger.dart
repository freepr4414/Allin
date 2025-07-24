import 'package:flutter/foundation.dart';

/// 통일된 로깅 시스템
class AppLogger {
  static const String _prefix = '[StudyCafeApp]';

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
    final reasonString = reason != null ? ' ($reason)' : '';
    info('Navigation: $from → $to$reasonString', 'NAV');
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
