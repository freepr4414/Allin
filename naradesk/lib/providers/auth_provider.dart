import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final String? companyCode;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.companyCode,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    String? companyCode,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      companyCode: companyCode ?? this.companyCode,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState());

  Future<void> loginWithCompanyCode(
    String companyCode,
    String username,
    String password,
  ) async {
    try {
      print('🔐 [AUTH] 로그인 시도 시작');
      print('📋 [AUTH] 회사코드: $companyCode');
      print('👤 [AUTH] 사용자명: $username');
      print('🔑 [AUTH] 비밀번호 길이: ${password.length}');

      // 백엔드 API를 통한 사용자 인증
      print('📡 [AUTH] 백엔드 API 호출 시작');
      final manager = await AuthService.login(username, password);

      if (manager != null) {
        print('✅ [AUTH] 백엔드 인증 성공');
        print('👤 [AUTH] 매니저 정보: ${manager.managerName}');

        // Manager를 User로 변환
        final user = User(
          id: manager.managerId,
          username: manager.managerId,
          name: manager.managerName,
          type: UserType.admin, // 기본값으로 admin 설정
          status: UserStatus.active,
          permissionLevel: PermissionLevel.level1,
        );

        print('🎉 [AUTH] 로그인 성공! 사용자: ${user.name}');
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          companyCode: companyCode,
          error: null,
        );
      } else {
        print('❌ [AUTH] 백엔드 인증 실패');
        state = state.copyWith(error: '잘못된 사용자명 또는 비밀번호입니다.');
      }
    } catch (e) {
      print('💥 [AUTH] 로그인 오류: $e');
      state = state.copyWith(error: '로그인 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> login(String username, String password) async {
    await loginWithCompanyCode('a1', username, password);
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
