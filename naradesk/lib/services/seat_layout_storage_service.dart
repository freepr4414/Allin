import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/saved_seat_layout.dart';

/// 좌석 배치도 저장/로드 서비스
class SeatLayoutStorageService {
  static const String _storageKey = 'saved_seat_layout';
  
  /// 에러 팝업 표시 함수
  static void _showErrorPopup(BuildContext? context, String message) {
    if (context == null) {
      debugPrint('에러 팝업 표시 불가 - Context가 null: $message');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Text('오류 발생'),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
  
  /// 성공 팝업 표시 함수
  static void _showSuccessPopup(BuildContext? context, String message) {
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text('완료'),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
  
  /// 좌석 배치도 저장
  static Future<bool> saveSeatLayout(SavedSeatLayout layout, {BuildContext? context}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = layout.toJsonString();
      final success = await prefs.setString(_storageKey, jsonString);
      
      // Context가 여전히 유효한지 확인 후 팝업 표시
      if (success && context != null && context.mounted) {
        _showSuccessPopup(context, '좌석 배치도가 성공적으로 저장되었습니다.');
      }
      
      return success;
    } catch (e) {
      debugPrint('좌석 배치도 저장 실패: $e');
      // Context가 여전히 유효한지 확인 후 팝업 표시
      if (context != null && context.mounted) {
        _showErrorPopup(context, '좌석 배치도 저장에 실패했습니다.\n오류: $e');
      }
      return false;
    }
  }

  /// 저장된 좌석 배치도 로드
  static Future<SavedSeatLayout?> loadSeatLayout({BuildContext? context}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      
      return SavedSeatLayout.fromJsonString(jsonString);
    } catch (e) {
      debugPrint('좌석 배치도 로드 실패: $e');
      // Context가 여전히 유효한지 확인 후 팝업 표시
      if (context != null && context.mounted) {
        _showErrorPopup(context, '좌석 배치도 로드에 실패했습니다.\n오류: $e');
      }
      return null;
    }
  }

  /// 저장된 배치도 존재 여부 확인
  static Future<bool> hasSavedLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      return jsonString != null && jsonString.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 저장된 배치도 삭제
  static Future<bool> clearSavedLayout({BuildContext? context}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_storageKey);
      
      // Context가 여전히 유효한지 확인 후 팝업 표시
      if (success && context != null && context.mounted) {
        _showSuccessPopup(context, '저장된 좌석 배치도가 삭제되었습니다.');
      }
      
      return success;
    } catch (e) {
      debugPrint('좌석 배치도 삭제 실패: $e');
      // Context가 여전히 유효한지 확인 후 팝업 표시
      if (context != null && context.mounted) {
        _showErrorPopup(context, '좌석 배치도 삭제에 실패했습니다.\n오류: $e');
      }
      return false;
    }
  }

  /// 저장 시간 가져오기
  static Future<DateTime?> getLastSavedTime() async {
    try {
      final layout = await loadSeatLayout();
      return layout?.savedAt;
    } catch (e) {
      return null;
    }
  }
}
