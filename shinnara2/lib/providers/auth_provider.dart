import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({this.isAuthenticated = false, this.user, this.error});

  AuthState copyWith({bool? isAuthenticated, User? user, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String username, String password) async {
    try {
      // 간단한 로그인 로직
      if (username == 'admin' && password == 'admin') {
        final user = User(
          id: '1',
          username: 'admin',
          name: '관리자',
          type: UserType.admin,
          status: UserStatus.active,
        );
        state = state.copyWith(isAuthenticated: true, user: user, error: null);
      } else if (username == 'user' && password == 'user') {
        final user = User(
          id: '2',
          username: 'user',
          name: '사용자',
          type: UserType.member,
          status: UserStatus.active,
        );
        state = state.copyWith(isAuthenticated: true, user: user, error: null);
      } else {
        state = state.copyWith(error: '잘못된 사용자명 또는 비밀번호입니다.');
      }
    } catch (e) {
      state = state.copyWith(error: '로그인 중 오류가 발생했습니다: $e');
    }
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
