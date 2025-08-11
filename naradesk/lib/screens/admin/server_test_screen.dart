import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';

class ServerTestScreen extends ConsumerStatefulWidget {
  const ServerTestScreen({super.key});

  @override
  ConsumerState<ServerTestScreen> createState() => _ServerTestScreenState();
}

class _ServerTestScreenState extends ConsumerState<ServerTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController(text: "localhost");
  final _portController = TextEditingController(text: "8080");
  final _roomCodeController = TextEditingController();
  final _seatNumberController = TextEditingController();
  final _powerNumberController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _roomCodeController.dispose();
    _seatNumberController.dispose();
    _powerNumberController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final webSocketService = ref.read(webSocketServiceProvider);
    final authState = ref.read(authProvider);

    if (authState.companyCode == null) {
      _showSnackBar('회사코드가 설정되지 않았습니다', Colors.red);
      return;
    }

    final host = _hostController.text.trim();
    final portStr = _portController.text.trim();

    if (host.isEmpty || portStr.isEmpty) {
      _showSnackBar('호스트와 포트를 입력해주세요', Colors.red);
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      _showSnackBar('올바른 포트번호를 입력해주세요', Colors.red);
      return;
    }

    final companyCode = authState.companyCode!;
    final userCode = '${companyCode}01'; // 기본 사용자 코드

    final success = await webSocketService.connect(
      host,
      port,
      companyCode,
      userCode,
    );
    if (success) {
      _showSnackBar('WebSocket 서버에 연결되었습니다', Colors.green);
    } else {
      _showSnackBar('WebSocket 서버 연결에 실패했습니다', Colors.red);
    }
  }

  Future<void> _disconnect() async {
    final webSocketService = ref.read(webSocketServiceProvider);
    await webSocketService.disconnect();
    _showSnackBar('WebSocket 서버 연결이 해제되었습니다', Colors.orange);
  }

  Future<void> _sendTestMessage() async {
    final roomCode = _roomCodeController.text.trim();
    final seatNumber = _seatNumberController.text.trim();
    final powerNumber = _powerNumberController.text.trim();

    if (roomCode.isEmpty || seatNumber.isEmpty || powerNumber.isEmpty) {
      _showSnackBar('열람실, 좌석번호, 전원번호를 모두 입력해주세요', Colors.red);
      return;
    }

    final webSocketService = ref.read(webSocketServiceProvider);
    if (!webSocketService.isConnected) {
      _showSnackBar('WebSocket 서버에 연결되어 있지 않습니다', Colors.red);
      return;
    }

    await webSocketService.sendMessage(roomCode, seatNumber, powerNumber);
    _showSnackBar('테스트 데이터가 전송되었습니다', Colors.green);
  }

  void _sendCustomMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showSnackBar('메시지를 입력해주세요', Colors.red);
      return;
    }

    final webSocketService = ref.read(webSocketServiceProvider);
    if (!webSocketService.isConnected) {
      _showSnackBar('WebSocket 서버에 연결되어 있지 않습니다', Colors.red);
      return;
    }

    // 커스텀 메시지는 단순 로그만 추가 (실제 구현 시 확장 가능)
    _messageController.clear();
    _showSnackBar('커스텀 메시지 기능은 아직 구현되지 않았습니다', Colors.orange);
  }

  void _clearMessages() {
    final webSocketService = ref.read(webSocketServiceProvider);
    webSocketService.clearMessages();
  }

  void _showSnackBar(String message, Color color) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final webSocketService = ref.watch(webSocketServiceProvider);
    final isConnected = webSocketService.isConnected;
    final messages = webSocketService.messages;

    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          '서버통신테스트',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isConnected
            ? scheme.primary
            : scheme.surfaceContainerHighest,
        foregroundColor: scheme.onPrimary,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected
                  ? scheme.primaryContainer
                  : scheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected
                    ? scheme.primary.withValues(alpha: 0.4)
                    : scheme.error.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              isConnected ? '연결됨' : '연결끊김',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isConnected
                    ? scheme.onPrimaryContainer
                    : scheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 서버 연결 설정
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '서버 연결 설정',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _hostController,
                          decoration: const InputDecoration(
                            labelText: '호스트',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          enabled: !isConnected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: '포트',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          enabled: !isConnected,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 연결 제어 버튼
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConnected ? null : _connect,
                      icon: const Icon(Icons.link),
                      label: const Text('연결'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConnected ? _disconnect : null,
                      icon: const Icon(Icons.link_off),
                      label: const Text('연결해제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 테스트 데이터 전송
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '테스트 데이터 전송',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _roomCodeController,
                          decoration: const InputDecoration(
                            labelText: '열람실코드',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _seatNumberController,
                          decoration: const InputDecoration(
                            labelText: '좌석번호',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _powerNumberController,
                          decoration: const InputDecoration(
                            labelText: '전원번호',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isConnected ? _sendTestMessage : null,
                      icon: const Icon(Icons.send),
                      label: const Text('테스트 데이터 전송'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 커스텀 메시지 전송
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '커스텀 메시지',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            labelText: '메시지 입력',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isConnected ? _sendCustomMessage : null,
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('전송'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.tertiary,
                          foregroundColor: scheme.onTertiary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 메시지 로그
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.05),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '메시지 로그 (${messages.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: messages.isNotEmpty
                              ? _clearMessages
                              : null,
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('지우기'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.message_outlined,
                                    size: 48,
                                    color: onSurface.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '아직 메시지가 없습니다',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: onSurface.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: onSurface.withValues(alpha: 0.08),
                                ),
                              ),
                              child: ListView.builder(
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message =
                                      messages[messages.length - 1 - index];
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
