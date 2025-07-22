import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';

class AuthState {
  final bool isLoggedIn;
  final User? user;
  final String? error;

  const AuthState({this.isLoggedIn = false, this.user, this.error});

  AuthState copyWith({bool? isLoggedIn, User? user, String? error}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    try {
      // 실제 구현시에는 API 호출
      await Future.delayed(const Duration(milliseconds: 500));

      if (email == "admin@studycafe.com" && password == "admin123") {
        const user = User(id: "1", name: "관리자", email: "admin@studycafe.com", role: UserRole.admin);
        state = state.copyWith(isLoggedIn: true, user: user, error: null);
      } else {
        state = state.copyWith(error: "이메일 또는 비밀번호가 올바르지 않습니다.");
      }
    } catch (e) {
      state = state.copyWith(error: "로그인 중 오류가 발생했습니다.");
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
