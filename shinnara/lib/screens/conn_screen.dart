import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';

// WebSocket 서비스 프로바이더
final webSocketServiceProvider = ChangeNotifierProvider<WebSocketService>((ref) {
  return WebSocketService();
});

class ConnScreen extends ConsumerStatefulWidget {
  const ConnScreen({super.key});

  @override
  ConsumerState<ConnScreen> createState() => _ConnScreenState();
}

class _ConnScreenState extends ConsumerState<ConnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController(text: "localhost");
  final _portController = TextEditingController(text: "8080");
  final _companyCodeController = TextEditingController();
  final _roomCodeController = TextEditingController();
  final _seatNumberController = TextEditingController();
  final _powerNumberController = TextEditingController();

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _companyCodeController.dispose();
    _roomCodeController.dispose();
    _seatNumberController.dispose();
    _powerNumberController.dispose();
    super.dispose();
  }

  void _connect() {
    if (_formKey.currentState!.validate()) {
      final companyCode = _companyCodeController.text.trim();
      if (companyCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회사 코드를 입력해주세요'), backgroundColor: Colors.red));
        return;
      }

      final host = _hostController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 8080;

      final webSocketService = ref.read(webSocketServiceProvider);
      // 사용자 코드는 고정값으로 설정, 호스트와 포트는 현재 WebSocketService에서 직접 사용하지 않지만 향후 확장을 위해 표시
      webSocketService.connect(companyCode, 'user01');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebSocket 서버에 연결 중... ($host:$port, 회사코드: $companyCode)'), backgroundColor: Colors.blue, duration: const Duration(seconds: 3)));
    }
  }

  void _disconnect() {
    final webSocketService = ref.read(webSocketServiceProvider);
    webSocketService.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WebSocket 서버 연결이 종료되었습니다')));
  }

  void _sendMessage() {
    final companyCode = _companyCodeController.text.trim();
    final roomCode = _roomCodeController.text.trim();
    final seatNumber = _seatNumberController.text.trim();
    final powerNumber = _powerNumberController.text.trim();

    if (companyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회사 코드가 설정되지 않았습니다'), backgroundColor: Colors.red));
      return;
    }

    if (roomCode.isEmpty || seatNumber.isEmpty || powerNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('열람실, 좌석번호, 전원번호를 모두 입력해주세요'), backgroundColor: Colors.red));
      return;
    }

    final webSocketService = ref.read(webSocketServiceProvider);

    if (!webSocketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WebSocket 서버에 연결되어 있지 않습니다'), backgroundColor: Colors.red));
      return;
    }

    webSocketService.sendMessage(roomCode, seatNumber, powerNumber);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('데이터가 전송되었습니다 (회사코드: $companyCode)'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final webSocketService = ref.watch(webSocketServiceProvider);
    final isConnected = webSocketService.isConnected;
    final messages = webSocketService.messages;

    return Scaffold(
      appBar: AppBar(title: const Text('인프리'), backgroundColor: isConnected ? Colors.green : Colors.grey),
      body: Column(
        children: [
          Container(
            color: isConnected ? Colors.green.shade100 : Colors.red.shade100,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isConnected ? Icons.check_circle : Icons.error_outline, color: isConnected ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(
                  isConnected ? '서버에 연결됨' : '서버 연결 끊김',
                  style: TextStyle(color: isConnected ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
                ),
                if (isConnected && webSocketService.reconnectAttempts > 0) ...[const SizedBox(width: 8), Text('(재연결: ${webSocketService.reconnectAttempts}회)', style: TextStyle(color: Colors.orange.shade800, fontSize: 12))],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('서버 연결 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // 회사 코드 필드
                    TextFormField(
                      controller: _companyCodeController,
                      decoration: const InputDecoration(labelText: '회사 코드', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business), hintText: '회사 코드를 입력하세요'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '회사 코드를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 호스트와 포트 필드
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _hostController,
                            decoration: const InputDecoration(labelText: '호스트', border: OutlineInputBorder(), prefixIcon: Icon(Icons.dns), hintText: 'localhost'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '호스트를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(labelText: '포트', border: OutlineInputBorder(), prefixIcon: Icon(Icons.settings_ethernet), hintText: '8080'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '포트를 입력해주세요';
                              }
                              final port = int.tryParse(value);
                              if (port == null || port < 1 || port > 65535) {
                                return '유효한 포트 번호를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isConnected ? null : _connect,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text('연결'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isConnected ? _disconnect : null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text('연결 해제'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('메시지 전송', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roomCodeController,
                            decoration: const InputDecoration(labelText: '열람실 코드', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _seatNumberController,
                            decoration: const InputDecoration(labelText: '좌석 번호', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _powerNumberController,
                            decoration: const InputDecoration(labelText: '전원 번호', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isConnected ? _sendMessage : null,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('데이터 전송'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('메시지 송수신 이력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text('총 ${messages.length}개'),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.red),
                              tooltip: '메시지 기록 초기화',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('메시지 기록 초기화'),
                                    content: const Text('모든 메시지 기록을 초기화하시겠습니까?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
                                      TextButton(
                                        onPressed: () {
                                          webSocketService.clearMessages();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('메시지 기록이 초기화되었습니다')));
                                        },
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('초기화'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(child: Text('송수신된 메시지가 없습니다'))
                          : ListView.builder(
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[messages.length - 1 - index];
                                final isSent = message.isSent;

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  color: isSent ? Colors.blue.shade50 : Colors.green.shade50,
                                  child: ListTile(
                                    leading: Icon(isSent ? Icons.send : Icons.call_received, color: isSent ? Colors.blue : Colors.green),
                                    title: RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: '${isSent ? "보냄" : "받음"}: ',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: isSent ? Colors.blue : Colors.green),
                                          ),
                                          TextSpan(text: '회사: ${message.companyCode}, 회원: ${message.userCode}'),
                                        ],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('열람실: ${message.roomCode}, 좌석: ${message.seatNumber}, 전원: ${message.powerNumber}'),
                                        Text('출처: ${message.source}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                                        if (message.rawData != null && message.rawData!.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                            child: Text(
                                              '바이너리 원본: ${message.rawData}',
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Text('${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}'),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
