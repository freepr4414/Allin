import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCodeController = TextEditingController(text: 'a1');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🔑 [LOGIN_SCREEN] LoginScreen initState 시작');
    print('📝 [LOGIN_SCREEN] 기본 회사코드: ${_companyCodeController.text}');
  }

  @override
  void dispose() {
    print('🗑️ [LOGIN_SCREEN] LoginScreen dispose');
    _companyCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    print('🔍 [LOGIN_SCREEN] _login 함수 시작');
    print('📋 [LOGIN_SCREEN] 폼 상태: ${_formKey.currentState}');

    if (_formKey.currentState?.validate() ?? false) {
      print('🚀 [LOGIN_SCREEN] 로그인 버튼 클릭됨');
      print('📝 [LOGIN_SCREEN] 폼 검증 통과');
      print(
        '� [LOGIN_SCREEN] 입력값 - 회사코드: ${_companyCodeController.text}, 사용자: ${_usernameController.text}',
      );

      setState(() {
        _isLoading = true;
      });

      print('⏳ [LOGIN_SCREEN] 로딩 상태 시작');

      await ref
          .read(authProvider.notifier)
          .loginWithCompanyCode(
            _companyCodeController.text,
            _usernameController.text,
            _passwordController.text,
          );

      print('✨ [LOGIN_SCREEN] 로그인 요청 완료');

      setState(() {
        _isLoading = false;
      });

      print('⏹️ [LOGIN_SCREEN] 로딩 상태 종료');
    } else {
      print('❌ [LOGIN_SCREEN] 폼 검증 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [LOGIN_SCREEN] LoginScreen build 시작');
    final authState = ref.watch(authProvider);
    print('🔍 [LOGIN_SCREEN] 현재 인증 상태: ${authState.isAuthenticated}');

    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      // Scaffold 배경은 글로벌 테마 사용
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
            boxShadow: [
              // 다크모드에서는 더 부드럽게
              BoxShadow(
                color: (isDark ? Colors.black : Colors.black).withValues(
                  alpha: isDark ? 0.45 : 0.08,
                ),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 로고 및 제목
                Icon(Icons.local_cafe, size: 64, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Study Cafe',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  'Management System',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // 회사코드 입력
                TextFormField(
                  controller: _companyCodeController,
                  decoration: const InputDecoration(
                    labelText: '회사코드',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                    hintText: 'a1',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '회사코드를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 사용자명 입력
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '사용자명',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '사용자명을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 에러 메시지 (복사 가능한 텍스트박스)
                if (authState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: scheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '오류 메시지 (복사 가능)',
                              style: TextStyle(
                                color: scheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: scheme.error,
                                size: 16,
                              ),
                              onPressed: () {
                                // 클립보드에 복사
                                Clipboard.setData(
                                  ClipboardData(text: authState.error!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      '오류 메시지가 클립보드에 복사되었습니다',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: scheme.primary,
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: SelectableText(
                            authState.error!,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            print('🔥 [LOGIN_SCREEN] 로그인 버튼 클릭 감지!');
                            _login();
                          },
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ).merge(
                          ButtonStyle(
                            overlayColor: WidgetStatePropertyAll(
                              scheme.onPrimary.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ), // onPrimary
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 실제 테스트 계정 정보
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '테스트 계정',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: qqqq\n비밀번호: 1111',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
