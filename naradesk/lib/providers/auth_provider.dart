import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/manager_model.dart';
import '../models/unified_menu_models.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final Manager? manager;
  final String? companyCode;
  final String? error;

  const AuthState({
    this.isAuthenticated = false, 
    this.user, 
    this.manager,
    this.companyCode, 
    this.error
  });

  AuthState copyWith({
    bool? isAuthenticated, 
    User? user,
    Manager? manager, 
    String? companyCode, 
    String? error
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      manager: manager ?? this.manager,
      companyCode: companyCode ?? this.companyCode,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  
  AuthNotifier(this.ref) : super(const AuthState()) {
    // API 서비스 초기화
    ApiService.setupInterceptors();
  }

  /// 회사코드와 함께 로그인 (기존 호환성 유지)
  Future<void> loginWithCompanyCode(String companyCode, String username, String password) async {
    await login(username, password);
  }

  /// 실제 백엔드 API를 사용한 로그인
  Future<void> login(String managerId, String password) async {
    try {
      // 에러 상태 초기화
      state = state.copyWith(error: null);
      
      // 백엔드 API를 통한 로그인 시도
      final manager = await AuthService.login(managerId, password);
      
      if (manager != null) {
        // 로그인 성공 - Manager 정보를 User 모델로 변환
        final user = User(
          id: manager.managerId,
          username: manager.managerId,
          name: manager.name,
          type: UserType.admin, // 관리자는 기본적으로 admin 타입
          status: UserStatus.active,
          permissionLevel: PermissionLevel.level1, // 기본 관리자 권한
        );

        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          manager: manager,
          companyCode: 'a1', // 기본 회사코드
          error: null,
        );
      } else {
        // 로그인 실패
        state = state.copyWith(
          error: '잘못된 관리자 ID 또는 비밀번호입니다.',
        );
      }
    } on ApiException catch (e) {
      // API 예외 처리
      state = state.copyWith(error: e.message);
    } catch (e) {
      // 기타 예외 처리
      state = state.copyWith(error: '로그인 중 오류가 발생했습니다: $e');
    }
  }

  void logout() {
    // 로그아웃 처리
    AuthService.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
