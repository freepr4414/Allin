import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';

// 바이너리 메시지 타입 정의
class KtwBinaryMessageType {
  static const int connect = 1;
  static const int message = 2;
  static const int ping = 3;
  static const int pong = 4;
  static const int welcome = 5;
}

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _connected = false;
  String? _companyCode;
  String? _userCode;
  final List<Message> _messages = [];
  final StreamController<Message> _messageController = StreamController<Message>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _shouldMaintainConnection = false;

  // 연결 확인을 위한 타임아웃 타이머
  Timer? _connectionVerificationTimer;
  static const Duration connectionTimeout = Duration(seconds: 10); // 연결 타임아웃
  // 재연결 시도 관련 변수
  int _reconnectAttempts = 0;
  static const Duration reconnectDelay = Duration(seconds: 5); // 고정된 재연결 지연 시간

  // 메시지 중복 방지를 위한 최근 메시지 해시 캐시
  final Map<String, DateTime> _processedMessages = {};
  static const Duration messageCacheTTL = Duration(seconds: 30); // 중복 메시지 캐시 유지 시간

  // 재연결 시도 횟수를 외부에서 접근할 수 있도록 getter 추가
  int get reconnectAttempts => _reconnectAttempts;

  bool get isConnected => _connected;
  List<Message> get messages => List.unmodifiable(_messages);
  Stream<Message> get messageStream => _messageController.stream;
  String? get companyCode => _companyCode;
  String? get userCode => _userCode;

  Future<void> connect(String companyCode, String userCode) async {
    _companyCode = companyCode;
    _userCode = userCode;
    _shouldMaintainConnection = true;

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (!_shouldMaintainConnection) {
      print('[DISCONNECT] 연결 유지가 설정되지 않아 연결하지 않습니다.');
      return;
    }

    if (_connected && _channel != null) {
      print('[CONNECT] 이미 연결되어 있습니다.');
      return;
    }

    _connected = false;

    try {
      print('[CONNECT] 웹소켓 서버에 연결 시도 중... (회사코드=$_companyCode, 유저코드=$_userCode)');
      // 기존 타이머가 있으면 취소
      _connectionVerificationTimer?.cancel();

      final wsUrl = 'ws://localhost:8080/ws';
      if (kIsWeb) {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      } else {
        _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      }

      // 이 시점에서는 아직 연결이 완전히 확립되었다고 확신할 수 없음
      // 연결 확인 타이머 설정
      _connectionVerificationTimer = Timer(connectionTimeout, () {
        if (!_connected) {
          if (kDebugMode) {
            print('Infree: 연결 타임아웃, 서버 응답 없음');
          }
          _handleDisconnect();
        }
      });

      if (kDebugMode) {
        print('웹소켓 채널 생성됨: $_channel');
      }

      // 연결 후 회사코드 및 사용자 정보 전송 (바이너리 형식)
      final connectData = _encodeBinaryMessageData(
        _companyCode!,
        _userCode!,
        'shinnara',
        '',
        '',
        '',
        '',
      );
      final connectMessage = _encodeBinaryMessage(KtwBinaryMessageType.connect, connectData);
      _channel!.sink.add(connectMessage);
      print('[CONNECT] 바이너리 연결 메시지 전송: ${connectMessage.length} bytes');

      // 메시지 수신 리스닝 (바이너리 전용)
      _channel!.stream.listen(
        (data) {
          if (data is List<int>) {
            print('====== WebSocket 데이터 수신 ======');
            print('수신된 데이터: ${data.length}바이트');
            print('수신 데이터 내용: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

            // 바이너리 데이터 처리
            _handleBinaryMessage(Uint8List.fromList(data));
          } else {
            print('[RECV] WebSocket에서 바이너리가 아닌 데이터 수신 - 무시됨: ${data.runtimeType}');
          }
        },
        onDone: () {
          print('[DISCONNECT] 서버와의 연결이 끊어졌습니다.');
          _connectionVerificationTimer?.cancel();
          _handleDisconnect();
        },
        onError: (error) {
          print('[DISCONNECT] WebSocket 오류: $error');
          _connectionVerificationTimer?.cancel();
          _handleDisconnect();
        },
      );

      // 주기적인 ping 설정
      _startPingTimer();

      notifyListeners();
      if (kDebugMode) {
        print('웹소켓 서버에 연결 시도 완료, 응답 대기 중');
      }
    } catch (e) {
      print('[DISCONNECT] 웹소켓 연결 실패: $e');
      _connectionVerificationTimer?.cancel();
      _connected = false;
      _scheduleReconnect();
    }
  }

  void sendMessage(String roomCode, String seatNumber, String powerNumber) {
    if (!_connected || _channel == null || _companyCode == null || _userCode == null) {
      print('[SEND] 메시지를 보낼 수 없음: 연결되지 않음');
      return;
    }

    final timestamp = DateTime.now().toIso8601String();

    // 바이너리 메시지 데이터 인코딩
    final messageData = _encodeBinaryMessageData(
      _companyCode!,
      _userCode!,
      'shinnara',
      roomCode,
      seatNumber,
      powerNumber,
      timestamp,
    );

    // 바이너리 메시지 생성
    final binaryMessage = _encodeBinaryMessage(KtwBinaryMessageType.message, messageData);

    // 로컬 메시지 객체 생성 (isSent = true로 설정)
    final localMsgData = {
      'companyCode': _companyCode!,
      'userCode': _userCode!,
      'source': 'shinnara',
      'roomCode': roomCode,
      'seatNumber': seatNumber,
      'powerNumber': powerNumber,
      'timestamp': timestamp,
      'isSent': true,
      'rawData': 'Binary message (${binaryMessage.length} bytes)',
    };

    // 메시지 객체 생성
    final message = Message.fromJson(localMsgData);

    // 바이너리 메시지 전송
    _channel!.sink.add(binaryMessage);
    print(
      '[SEND] WebSocket 바이너리 메시지 전송: ${binaryMessage.length} bytes [회사코드:$_companyCode][사용자:$_userCode][방:$roomCode][좌석:$seatNumber][전원:$powerNumber]',
    );

    // 발신 메시지도 로컬 목록에 추가
    _addMessage(message);
  }

  void disconnect() {
    _shouldMaintainConnection = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _connectionVerificationTimer?.cancel();
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _connected = false;
    notifyListeners();
  }

  // 바이너리 메시지 처리
  void _handleBinaryMessage(Uint8List data) {
    print('====== WebSocket 바이너리 메시지 처리 시작 ======');
    print('메시지 데이터 크기: ${data.length}바이트');
    print('메시지 데이터: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    try {
      if (data.length < 9) {
        print('[RECV] 바이너리 메시지가 너무 짧습니다: ${data.length} bytes');
        return;
      }

      // 인증 헤더 건너뛰기 (4바이트)
      // 메시지 타입 (5번째 바이트)
      final messageType = data[4];

      // 데이터 길이 (6-9번째 바이트, 빅 엔디안)
      final dataLength = ByteData.view(data.buffer, 5, 4).getUint32(0);

      if (data.length < 9 + dataLength) {
        print('[RECV] 바이너리 메시지 데이터 부족: 예상 ${9 + dataLength}, 실제 ${data.length}');
        return;
      }

      final messageData = data.sublist(9, 9 + dataLength);

      print('[RECV] 바이너리 메시지 수신: 타입=$messageType, 데이터 길이=$dataLength bytes');

      switch (messageType) {
        case KtwBinaryMessageType.message:
          _processBinaryMessage(messageData);
          break;
        case KtwBinaryMessageType.welcome:
          print('[RECV] Welcome 메시지 수신');
          _handleConnectionSuccess();
          break;
        case KtwBinaryMessageType.ping:
          print('[RECV] Ping 수신, Pong 응답 전송');
          _sendPong();
          break;
        case KtwBinaryMessageType.pong:
          print('[RECV] Pong 수신');
          _handleConnectionSuccess();
          break;
        default:
          print('[RECV] 알 수 없는 바이너리 메시지 타입: $messageType');
      }
    } catch (e) {
      print('[RECV] 바이너리 메시지 처리 오류: $e');
    }
  }

  // 바이너리 메시지 데이터 처리
  void _processBinaryMessage(Uint8List messageData) {
    print('====== WebSocket 바이너리 메시지 디코딩 시작 ======');
    print('메시지 데이터 크기: ${messageData.length}바이트');
    print('메시지 데이터: ${messageData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    try {
      final decodedData = _decodeBinaryMessageData(messageData);

      print('디코딩된 데이터: $decodedData');

      print(
        '[RECV] 바이너리 메시지 디코딩 성공: [회사코드:${decodedData['companyCode']}][사용자:${decodedData['userCode']}][소스:${decodedData['source']}][방:${decodedData['roomCode']}][좌석:${decodedData['seatNumber']}][전원:${decodedData['powerNumber']}]',
      );

      // Map<String, dynamic>으로 변환
      final msgMap = Map<String, dynamic>.from(decodedData);

      // 로컬 사용자가 보낸 메시지인지 확인
      msgMap['isSent'] = msgMap['source'] == 'infree' && msgMap['userCode'] == _userCode;

      // 바이너리 원본 데이터 정보 저장
      msgMap['rawData'] = 'Binary message (${messageData.length} bytes)';

      // 메시지 중복 검사
      final messageHash = _createMessageHash(msgMap);
      if (_isMessageProcessed(messageHash)) {
        print('[RECV] 중복 메시지 감지: $messageHash - 무시됨');
        return;
      }

      // 메시지 처리됨으로 표시
      _markMessageAsProcessed(messageHash);

      final message = Message.fromJson(msgMap);
      print('[RECV] 바이너리 메시지 객체 생성 및 목록 추가: $messageHash');
      print('생성된 메시지: ${message.companyCode}/${message.userCode} - ${message.source}');
      _addMessage(message);
      print('[RECV] 바이너리 메시지가 목록에 추가되었습니다 (총 ${_messages.length}개)');
      print('메시지 목록에 추가됨. 총 메시지 수: ${_messages.length}');
    } catch (e) {
      print('[RECV] 바이너리 메시지 처리 중 오류: $e');
      print('오류 스택: ${StackTrace.current}');
    }
  }

  // 연결 성공 처리
  void _handleConnectionSuccess() {
    if (!_connected) {
      _connected = true;
      _connectionVerificationTimer?.cancel();
      _reconnectAttempts = 0; // 재연결 시도 횟수 초기화
      print('Infree: 서버 연결 확인됨');
      notifyListeners();
    }
  }

  // Pong 메시지 전송
  void _sendPong() {
    if (_connected && _channel != null) {
      final pongMessage = _encodeBinaryMessage(KtwBinaryMessageType.pong, Uint8List(0));
      _channel!.sink.add(pongMessage);
      print('[SEND] Pong 응답 전송');
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connected && _channel != null) {
        try {
          // 바이너리 ping 메시지 전송
          final pingMessage = _encodeBinaryMessage(KtwBinaryMessageType.ping, Uint8List(0));
          _channel!.sink.add(pingMessage);
          if (kDebugMode) {
            print('Infree: 바이너리 ping 전송');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error sending ping: $e');
          }
        }
      }
    });
  }

  void _addMessage(Message message) {
    _messages.add(message);
    _messageController.add(message);
    notifyListeners();
  }

  // 메시지 기록 초기화
  void clearMessages() {
    _messages.clear();
    notifyListeners();
    if (kDebugMode) {
      print('메시지 기록이 초기화되었습니다.');
    }
  }

  void _handleDisconnect() {
    _connected = false;
    notifyListeners();

    if (_shouldMaintainConnection) {
      if (kDebugMode) {
        print('WebSocket connection lost. Attempting to reconnect...');
      }
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      if (_shouldMaintainConnection && _companyCode != null && _userCode != null) {
        _reconnectAttempts++; // 재연결 시도 횟수 증가
        if (kDebugMode) {
          print('Infree: 재연결 시도 #$_reconnectAttempts, 지연 시간: ${reconnectDelay.inSeconds}초');
        }

        _establishConnection();
      }
    });
  }

  // 연결이 끊어졌을 때 연결 복원
  Future<void> ensureConnected() async {
    if (_shouldMaintainConnection && !_connected && _companyCode != null && _userCode != null) {
      if (kDebugMode) {
        print('Infree: 소켓 연결 복원 시도');
      }
      await _establishConnection();
    }
  }

  // 메시지가 이미 처리되었는지 확인하는 헬퍼 메서드
  bool _isMessageProcessed(String messageHash) {
    final timestamp = _processedMessages[messageHash];
    if (timestamp == null) {
      return false;
    }

    // TTL이 지났으면 처리되지 않은 것으로 간주
    if (DateTime.now().difference(timestamp) > messageCacheTTL) {
      _processedMessages.remove(messageHash);
      return false;
    }

    return true;
  }

  // 메시지를 처리됨으로 표시하는 헬퍼 메서드
  void _markMessageAsProcessed(String messageHash) {
    // 오래된 메시지 제거
    _processedMessages.removeWhere(
      (_, timestamp) => DateTime.now().difference(timestamp) > messageCacheTTL,
    );

    // 새 메시지 추가
    _processedMessages[messageHash] = DateTime.now();
  }

  // 메시지에서 고유 해시 생성
  String _createMessageHash(Map<String, dynamic> msgMap) {
    // 메시지의 주요 필드 조합하여 고유 ID 생성
    final companyCode = msgMap['companyCode'] ?? '';
    final roomCode = msgMap['roomCode'] ?? '';
    final seatNumber = msgMap['seatNumber'] ?? '';
    final powerNumber = msgMap['powerNumber'] ?? '';
    final timestamp = msgMap['timestamp'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    // 중복 방지를 위한 고유 해시 생성
    return '$companyCode-$roomCode-$seatNumber-$powerNumber-$timestamp';
  }

  // Infree용 인증 생성: 첫3바이트 합산
  int _generateInfreeAuth() {
    final random = Random.secure();
    int byte1 = random.nextInt(256);
    int byte2 = random.nextInt(256);
    int byte3 = random.nextInt(256);
    int byte4 = (byte1 + byte2 + byte3) & 0xFF;

    return (byte1 << 24) | (byte2 << 16) | (byte3 << 8) | byte4;
  }

  // 바이너리 메시지 인코딩
  Uint8List _encodeBinaryMessage(int messageType, Uint8List data) {
    // Infree 인증 생성
    final auth = _generateInfreeAuth();

    final buffer = ByteData(9 + data.length);

    // 인증 헤더 (4바이트, 빅 엔디안)
    buffer.setUint32(0, auth);

    // 메시지 타입 (1바이트)
    buffer.setUint8(4, messageType);

    // 데이터 길이 (4바이트, 빅 엔디안)
    buffer.setUint32(5, data.length);

    // 메시지 생성
    final result = Uint8List(9 + data.length);
    result.setRange(0, 9, buffer.buffer.asUint8List());
    result.setRange(9, 9 + data.length, data);

    return result;
  }

  // 바이너리 메시지 데이터 인코딩
  Uint8List _encodeBinaryMessageData(
    String companyCode,
    String userCode,
    String source,
    String roomCode,
    String seatNumber,
    String powerNumber,
    String timestamp,
  ) {
    final List<int> buffer = [];

    // 회사코드
    buffer.add(companyCode.length);
    buffer.addAll(utf8.encode(companyCode));

    // 사용자코드
    buffer.add(userCode.length);
    buffer.addAll(utf8.encode(userCode));

    // 소스
    buffer.add(source.length);
    buffer.addAll(utf8.encode(source));

    // 방코드
    buffer.add(roomCode.length);
    buffer.addAll(utf8.encode(roomCode));

    // 좌석번호
    buffer.add(seatNumber.length);
    buffer.addAll(utf8.encode(seatNumber));

    // 전원번호
    buffer.add(powerNumber.length);
    buffer.addAll(utf8.encode(powerNumber));

    // 타임스탬프
    buffer.add(timestamp.length);
    buffer.addAll(utf8.encode(timestamp));

    return Uint8List.fromList(buffer);
  }

  // 바이너리 메시지 데이터 디코딩
  Map<String, String> _decodeBinaryMessageData(Uint8List data) {
    int offset = 0;
    final result = <String, String>{};

    try {
      // 회사코드
      if (offset >= data.length) throw Exception('회사코드 길이 필드 없음');
      int companyLen = data[offset++];
      if (offset + companyLen > data.length) throw Exception('회사코드 데이터 부족');
      result['companyCode'] = utf8.decode(data.sublist(offset, offset + companyLen));
      offset += companyLen;

      // 사용자코드
      if (offset >= data.length) throw Exception('사용자코드 길이 필드 없음');
      int userLen = data[offset++];
      if (offset + userLen > data.length) throw Exception('사용자코드 데이터 부족');
      result['userCode'] = utf8.decode(data.sublist(offset, offset + userLen));
      offset += userLen;

      // 소스
      if (offset >= data.length) throw Exception('소스 길이 필드 없음');
      int sourceLen = data[offset++];
      if (offset + sourceLen > data.length) throw Exception('소스 데이터 부족');
      result['source'] = utf8.decode(data.sublist(offset, offset + sourceLen));
      offset += sourceLen;

      // 방코드
      if (offset >= data.length) throw Exception('방코드 길이 필드 없음');
      int roomLen = data[offset++];
      if (offset + roomLen > data.length) throw Exception('방코드 데이터 부족');
      result['roomCode'] = utf8.decode(data.sublist(offset, offset + roomLen));
      offset += roomLen;

      // 좌석번호
      if (offset >= data.length) throw Exception('좌석번호 길이 필드 없음');
      int seatLen = data[offset++];
      if (offset + seatLen > data.length) throw Exception('좌석번호 데이터 부족');
      result['seatNumber'] = utf8.decode(data.sublist(offset, offset + seatLen));
      offset += seatLen;

      // 전원번호
      if (offset >= data.length) throw Exception('전원번호 길이 필드 없음');
      int powerLen = data[offset++];
      if (offset + powerLen > data.length) throw Exception('전원번호 데이터 부족');
      result['powerNumber'] = utf8.decode(data.sublist(offset, offset + powerLen));
      offset += powerLen;

      // 타임스탬프
      if (offset >= data.length) throw Exception('타임스탬프 길이 필드 없음');
      int timestampLen = data[offset++];
      if (offset + timestampLen > data.length) throw Exception('타임스탬프 데이터 부족');
      result['timestamp'] = utf8.decode(data.sublist(offset, offset + timestampLen));
    } catch (e) {
      if (kDebugMode) print('바이너리 메시지 데이터 디코딩 오류: $e');
      rethrow;
    }

    return result;
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}
