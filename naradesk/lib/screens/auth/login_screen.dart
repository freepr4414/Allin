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

                // 5단계 권한 레벨 테스트 계정 안내
                Text(
                  '권한별 테스트 계정',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                _RoleButtons(
                  onSelect: (user, pass) {
                    _usernameController.text = user;
                    _passwordController.text = pass;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 권한별 테스트 계정 버튼 묶음
class _RoleButtons extends StatelessWidget {
  const _RoleButtons({required this.onSelect});

  final void Function(String username, String password) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget roleButton({
      required String label,
      required String user,
      required String pass,
      required Color color,
    }) {
      final borderColor = color.withValues(alpha: 0.4);
      return OutlinedButton(
        onPressed: () => onSelect(user, pass),
        style:
            OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: borderColor),
              textStyle: const TextStyle(fontSize: 12, height: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            ).merge(
              ButtonStyle(
                overlayColor: WidgetStatePropertyAll(
                  color.withValues(alpha: 0.08),
                ),
              ),
            ),
        child: Text(label, textAlign: TextAlign.center),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: roleButton(
                label: '최고 관리자\n(Level 1)',
                user: 'admin',
                pass: 'admin',
                color: scheme.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: roleButton(
                label: '상급 관리자\n(Level 2)',
                user: 'manager',
                pass: 'manager',
                color: scheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: roleButton(
                label: '일반 직원\n(Level 4)',
                user: 'staff',
                pass: 'staff',
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: roleButton(
                label: '제한된 직원\n(Level 5)',
                user: 'user',
                pass: 'user',
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
