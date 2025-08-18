import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/manager_model.dart';
import '../models/unified_menu_models.dart';
import '../models/user.dart';
<<<<<<< HEAD
=======
import '../services/api_service.dart';
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final Manager? manager;
  final String? companyCode;
  final String? error;

  const AuthState({
<<<<<<< HEAD
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
=======
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
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
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
<<<<<<< HEAD

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
=======
  
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
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
      }
    } on ApiException catch (e) {
      // API 예외 처리
      state = state.copyWith(error: e.message);
    } catch (e) {
<<<<<<< HEAD
      print('💥 [AUTH] 로그인 오류: $e');
=======
      // 기타 예외 처리
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
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
