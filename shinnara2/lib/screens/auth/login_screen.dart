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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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
          .login(_usernameController.text, _passwordController.text);

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 로고 및 제목
                Icon(Icons.local_cafe, size: 64, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Study Cafe',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'Management System',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

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
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      authState.error!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5단계 권한 레벨 테스트 계정 안내
                Text(
                  '권한별 테스트 계정',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _usernameController.text = 'admin';
                              _passwordController.text = 'admin';
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[300]!),
                            ),
                            child: const Text(
                              '최고 관리자\n(Level 1)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _usernameController.text = 'manager';
                              _passwordController.text = 'manager';
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                              side: BorderSide(color: Colors.orange[300]!),
                            ),
                            child: const Text(
                              '상급 관리자\n(Level 2)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _usernameController.text = 'staff';
                              _passwordController.text = 'staff';
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              side: BorderSide(color: Colors.green[300]!),
                            ),
                            child: const Text(
                              '일반 직원\n(Level 4)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _usernameController.text = 'user';
                              _passwordController.text = 'user';
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            child: const Text(
                              '제한된 직원\n(Level 5)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
