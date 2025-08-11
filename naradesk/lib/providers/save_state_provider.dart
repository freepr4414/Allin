import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_seat_layout.dart';
import '../services/seat_layout_storage_service.dart';

/// 저장 상태 열거형
enum SaveStatus {
  idle,      // 대기 상태
  saving,    // 저장 중
  success,   // 저장 성공
  error,     // 저장 실패
}

/// 저장 상태 데이터
class SaveState {
  final SaveStatus status;
  final String? errorMessage;
  final DateTime? lastSavedTime;

  const SaveState({
    this.status = SaveStatus.idle,
    this.errorMessage,
    this.lastSavedTime,
  });

  SaveState copyWith({
    SaveStatus? status,
    String? errorMessage,
    DateTime? lastSavedTime,
  }) {
    return SaveState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSavedTime: lastSavedTime ?? this.lastSavedTime,
    );
  }
}

/// 저장 상태 관리 클래스
class SaveStateNotifier extends StateNotifier<SaveState> {
  SaveStateNotifier() : super(const SaveState());

  /// 좌석 배치도 저장
  Future<bool> saveSeatLayout(SavedSeatLayout layout, {BuildContext? context}) async {
    state = state.copyWith(status: SaveStatus.saving);
    
    try {
      final success = await SeatLayoutStorageService.saveSeatLayout(layout, context: context);
      
      if (success) {
        state = state.copyWith(
          status: SaveStatus.success,
          lastSavedTime: layout.savedAt,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          status: SaveStatus.error,
          errorMessage: '저장에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: SaveStatus.error,
        errorMessage: '저장 중 오류가 발생했습니다: $e',
      );
      return false;
    }
  }

  /// 저장된 배치도 로드
  Future<SavedSeatLayout?> loadSeatLayout({BuildContext? context}) async {
    try {
      final layout = await SeatLayoutStorageService.loadSeatLayout(context: context);
      if (layout != null) {
        state = state.copyWith(lastSavedTime: layout.savedAt);
      }
      return layout;
    } catch (e) {
      state = state.copyWith(
        status: SaveStatus.error,
        errorMessage: '로드 중 오류가 발생했습니다: $e',
      );
      return null;
    }
  }

  /// 상태 초기화
  void resetStatus() {
    state = state.copyWith(status: SaveStatus.idle, errorMessage: null);
  }
}

/// 저장 상태 Provider
final saveStateProvider = StateNotifierProvider<SaveStateNotifier, SaveState>(
  (ref) => SaveStateNotifier(),
);
