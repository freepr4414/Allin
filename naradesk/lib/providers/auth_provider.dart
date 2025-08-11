import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import '../models/user.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final String? companyCode;
  final String? error;

  const AuthState({this.isAuthenticated = false, this.user, this.companyCode, this.error});

  AuthState copyWith({bool? isAuthenticated, User? user, String? companyCode, String? error}) {
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

  Future<void> loginWithCompanyCode(String companyCode, String username, String password) async {
    try {
      // 다양한 권한 레벨 사용자 로그인 지원
      User? user;
      
      if (username == 'admin' && password == 'admin') {
        user = User(
          id: '1',
          username: 'admin',
          name: '최고 관리자',
          type: UserType.admin,
          status: UserStatus.active,
          permissionLevel: PermissionLevel.level1,
        );
      } else if (username == 'manager' && password == 'manager') {
        user = User(
          id: '2',
          username: 'manager',
          name: '상급 관리자',
          type: UserType.staff,
          status: UserStatus.active,
          permissionLevel: PermissionLevel.level2,
        );
      } else if (username == 'staff' && password == 'staff') {
        user = User(
          id: '3',
          username: 'staff',
          name: '일반 직원',
          type: UserType.staff,
          status: UserStatus.active,
          permissionLevel: PermissionLevel.level4,
        );
      } else if (username == 'user' && password == 'user') {
        user = User(
          id: '4',
          username: 'user',
          name: '제한된 사용자',
          type: UserType.member,
          status: UserStatus.active,
          permissionLevel: PermissionLevel.level5,
        );
      }

      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true, 
          user: user, 
          companyCode: companyCode,
          error: null
        );
      } else {
        state = state.copyWith(error: '잘못된 사용자명 또는 비밀번호입니다.');
      }
    } catch (e) {
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
