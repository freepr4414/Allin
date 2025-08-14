import 'package:flutter/material.dart';
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
  void dispose() {
    _companyCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      await ref
          .read(authProvider.notifier)
          .loginWithCompanyCode(
            _companyCodeController.text,
            _usernameController.text,
            _passwordController.text,
          );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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

                // 에러 메시지
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
                    child: Text(
                      authState.error!,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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

                // 테스트 계정 안내 (qqqq/1111)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '테스트 계정',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: qqqq / PW: 1111',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: 'monospace',
                        ),
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
