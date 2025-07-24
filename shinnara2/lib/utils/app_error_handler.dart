import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../utils/app_logger.dart';

/// 통일된 에러 핸들링 시스템
class AppErrorHandler {
  /// 성공 메시지 표시
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
    AppLogger.info('Success message shown: $message', 'UI');
  }

  /// 정보 메시지 표시
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
    AppLogger.info('Info message shown: $message', 'UI');
  }

  /// 경고 메시지 표시
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
    AppLogger.warning('Warning message shown: $message', 'UI');
  }

  /// 에러 메시지 표시
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
    AppLogger.error('Error message shown: $message', 'UI', error, stackTrace);
  }

  /// 공통 SnackBar 표시
  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: AppConstants.snackBarDuration),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onAction)
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        ),
      ),
    );
  }

  /// 확인 다이얼로그 표시
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    IconData? icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            title: Row(
              children: [
                if (icon != null) ...[Icon(icon, color: confirmColor), const SizedBox(width: 12)],
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText ?? AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: confirmColor != null
                    ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                    : null,
                child: Text(confirmText ?? AppStrings.confirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 에러 다이얼로그 표시
  static Future<void> showErrorDialog(
    BuildContext context, {
    String? title,
    required String message,
    String? buttonText,
    VoidCallback? onRetry,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Text(title ?? AppStrings.error),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text(AppStrings.retry),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText ?? AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  /// 로딩 다이얼로그 표시
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message ?? AppStrings.loading),
          ],
        ),
      ),
    );
  }

  /// 로딩 다이얼로그 숨기기
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// 권한 거부 메시지 표시
  static void showPermissionDenied(BuildContext context, String feature) {
    showWarning(
      context,
      AppStrings.permissionDeniedForFeature(feature),
      duration: const Duration(seconds: AppConstants.longSnackBarDuration),
    );
  }

  /// 네트워크 에러 처리
  static void handleNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    showError(
      context,
      AppStrings.networkError,
      actionLabel: onRetry != null ? AppStrings.retry : null,
      onAction: onRetry,
      duration: const Duration(seconds: AppConstants.longSnackBarDuration),
    );
  }

  /// 서버 에러 처리
  static void handleServerError(BuildContext context, {VoidCallback? onRetry}) {
    showError(
      context,
      AppStrings.serverError,
      actionLabel: onRetry != null ? AppStrings.retry : null,
      onAction: onRetry,
      duration: const Duration(seconds: AppConstants.longSnackBarDuration),
    );
  }

  /// 일반적인 에러 처리
  static void handleGenericError(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    StackTrace? stackTrace,
  }) {
    String message;

    if (error.toString().contains('network')) {
      message = AppStrings.networkError;
    } else if (error.toString().contains('server')) {
      message = AppStrings.serverError;
    } else {
      message = AppStrings.unexpectedError;
    }

    showError(
      context,
      message,
      actionLabel: onRetry != null ? AppStrings.retry : null,
      onAction: onRetry,
      error: error,
      stackTrace: stackTrace,
      duration: const Duration(seconds: AppConstants.longSnackBarDuration),
    );
  }
}
