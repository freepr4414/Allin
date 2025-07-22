import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';

// 바이너리 메시지 타입 상수
class KtwBinaryMessageType {
  static const int connect = 1;
  static const int message = 2;
  static const int ping = 3;
  static const int pong = 4;
  static const int welcome = 5;
}

// TCP 서비스 상태 클래스
class TCPState {
  final bool isConnected;
  final String? error;
  final List<Message> messages;
  final List<DeviceInfo> devices;
  final String? companyCode;

  const TCPState({this.isConnected = false, this.error, this.messages = const [], this.devices = const [], this.companyCode});

  TCPState copyWith({bool? isConnected, String? error, List<Message>? messages, List<DeviceInfo>? devices, String? companyCode}) {
    return TCPState(isConnected: isConnected ?? this.isConnected, error: error, messages: messages ?? this.messages, devices: devices ?? this.devices, companyCode: companyCode ?? this.companyCode);
  }
}

// TCP 서비스 노티파이어
class TCPServiceNotifier extends StateNotifier<TCPState> {
  TCPServiceNotifier() : super(const TCPState());

  Socket? _socket;
  String? _host;
  int? _port;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  StreamSubscription? _socketSubscription;
  final StreamController<Uint8List> _dataBuffer = StreamController<Uint8List>();
  List<int> _buffer = [];

  @override
  void dispose() {
    disconnect();
    _dataBuffer.close();
    super.dispose();
  }

  // 회사 코드 설정
  void setCompanyCode(String companyCode) {
    state = state.copyWith(companyCode: companyCode);
  }

  // TCP 서버에 연결
  Future<void> connect(String host, int port) async {
    if (state.isConnected) {
      if (kDebugMode) print('이미 연결되어 있습니다.');
      return;
    }

    _host = host;
    _port = port;

    try {
      state = state.copyWith(error: null);

      if (kDebugMode) print('TCP 서버에 연결 시도: $host:$port');

      _socket = await Socket.connect(host, port);

      if (kDebugMode) print('TCP 서버에 연결되었습니다');

      state = state.copyWith(isConnected: true, error: null);

      // 소켓 데이터 수신 리스너 설정
      _socketSubscription = _socket!.listen(_onDataReceived, onError: _onError, onDone: _onDisconnected);

      // 연결 후 바이너리 Connect 메시지 전송 (infree와 동일)
      await _sendConnectMessage();

      // 주기적 ping 타이머 시작 (30초마다)
      _startPingTimer();
    } catch (e) {
      if (kDebugMode) print('TCP 연결 실패: $e');
      // 오류 메시지를 표시하지 않고 연결 상태만 업데이트
      state = state.copyWith(isConnected: false, error: null);
      _scheduleReconnect();
    }
  }

  // 연결 해제
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socketSubscription?.cancel();
    _socket?.close();
    _socket = null;
    _buffer.clear();

    state = state.copyWith(isConnected: false, error: null);

    if (kDebugMode) print('TCP 연결이 해제되었습니다');
  }

  // 데이터 수신 처리
  void _onDataReceived(Uint8List data) {
    if (kDebugMode) print('====== TCP 데이터 수신 ======');
    if (kDebugMode) print('수신된 데이터: ${data.length}바이트');
    if (kDebugMode) {
      print('수신 데이터 내용: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    }

    // 버퍼에 데이터 추가
    _buffer.addAll(data);

    if (kDebugMode) print('현재 버퍼 크기: ${_buffer.length}바이트');

    // 완전한 메시지 처리
    _processBuffer();
  }

  // 버퍼에서 완전한 메시지 추출 및 처리
  void _processBuffer() {
    while (_buffer.length >= 9) {
      // 최소 헤더 크기 (인증 4바이트 + 타입 1바이트 + 길이 4바이트)

      // 인증 헤더 건너뛰기 (4바이트)
      // 메시지 타입 읽기 (5번째 바이트)
      int messageType = _buffer[4];

      // 데이터 길이 읽기 (6-9번째 바이트, 빅 엔디안)
      int dataLength = (_buffer[5] << 24) | (_buffer[6] << 16) | (_buffer[7] << 8) | _buffer[8];

      // 전체 메시지 길이 확인
      int totalLength = 9 + dataLength;
      if (_buffer.length < totalLength) {
        // 아직 완전한 메시지가 도착하지 않음
        break;
      }

      // 메시지 데이터 추출 (인증 헤더 제외)
      List<int> messageData = _buffer.sublist(9, totalLength);

      // 처리된 데이터를 버퍼에서 제거
      _buffer = _buffer.sublist(totalLength);

      // 메시지 처리
      _processMessage(messageType, Uint8List.fromList(messageData));
    }
  }

  // 메시지 처리
  void _processMessage(int messageType, Uint8List data) {
    if (kDebugMode) print('메시지 처리: 타입=$messageType, 길이=${data.length}');

    try {
      switch (messageType) {
        case KtwBinaryMessageType.message:
          _handleBinaryMessage(data);
          break;
        case KtwBinaryMessageType.welcome:
          _handleWelcomeMessage(data);
          break;
        case KtwBinaryMessageType.ping:
          _handlePing();
          break;
        case KtwBinaryMessageType.pong:
          _handlePong();
          break;
        default:
          if (kDebugMode) print('알 수 없는 메시지 타입: $messageType');
      }
    } catch (e) {
      if (kDebugMode) print('메시지 처리 오류: $e');
    }
  }

  // 바이너리 메시지 처리
  void _handleBinaryMessage(Uint8List data) {
    if (kDebugMode) print('====== 바이너리 메시지 처리 시작 ======');
    if (kDebugMode) print('메시지 데이터 크기: ${data.length}바이트');
    if (kDebugMode) print('메시지 데이터: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    try {
      final decodedData = _decodeBinaryMessageData(data);

      if (kDebugMode) print('디코딩된 데이터: $decodedData');

      final message = Message(
        companyCode: decodedData['companyCode'] ?? '',
        userCode: decodedData['userCode'] ?? '',
        roomCode: decodedData['roomCode'] ?? '',
        seatNumber: decodedData['seatNumber'] ?? '',
        powerNumber: decodedData['powerNumber'] ?? '',
        source: decodedData['source'] ?? 'unknown',
        isSent: false,
        rawData: String.fromCharCodes(data),
      );

      if (kDebugMode) print('생성된 메시지: ${message.companyCode}/${message.userCode} - ${message.source}');

      final newMessages = [...state.messages, message];
      state = state.copyWith(messages: newMessages);

      if (kDebugMode) print('메시지 목록에 추가됨. 총 메시지 수: ${newMessages.length}');
      if (kDebugMode) print('바이너리 메시지 수신: ${message.companyCode}/${message.userCode}');
    } catch (e) {
      if (kDebugMode) print('바이너리 메시지 디코딩 오류: $e');
      if (kDebugMode) print('오류 스택: ${StackTrace.current}');
    }
  }

  // 웰컴 메시지 처리
  void _handleWelcomeMessage(Uint8List data) {
    try {
      if (data.isEmpty) return;

      int messageLength = data[0];
      if (data.length < 1 + messageLength) return;

      String welcomeMessage = String.fromCharCodes(data.sublist(1, 1 + messageLength));
      if (kDebugMode) print('웰컴 메시지: $welcomeMessage');

      // infree와 동일하게 연결 성공 처리
      _handleConnectionSuccess();
    } catch (e) {
      if (kDebugMode) print('웰컴 메시지 처리 오류: $e');
    }
  }

  // 핑 메시지 처리 - 퐁으로 응답
  void _handlePing() {
    if (kDebugMode) print('핑 수신, 퐁 응답');
    _sendPong();
  }

  // 퐁 메시지 처리
  void _handlePong() {
    if (kDebugMode) print('서버로부터 pong 수신');
    _handleConnectionSuccess();
  }

  // 연결 성공 처리 (infree와 동일한 로직)
  void _handleConnectionSuccess() {
    if (state.isConnected) {
      // 이미 연결된 상태에서는 연결 상태 확인만 로깅
      if (kDebugMode) print('Naradevice: 서버 연결 상태 확인됨');
    }
  }

  // 오류 처리
  void _onError(error) {
    if (kDebugMode) print('TCP 소켓 오류: $error');

    // 이미 연결이 끊어진 상태이면 오류 메시지를 업데이트하지 않음
    if (!state.isConnected) return;

    // 연결 상태만 업데이트하고 오류 메시지는 한 번만 설정
    state = state.copyWith(isConnected: false, error: null);
    _scheduleReconnect();
  }

  // 연결 해제 처리
  void _onDisconnected() {
    if (kDebugMode) print('TCP 소켓 연결 해제됨');

    // 이미 연결이 끊어진 상태이면 중복 처리하지 않음
    if (!state.isConnected) return;

    state = state.copyWith(isConnected: false, error: null);
    _scheduleReconnect();
  }

  // 재연결 스케줄링
  void _scheduleReconnect() {
    // 이미 재연결 타이머가 동작 중이면 중복 실행하지 않음
    if (_reconnectTimer?.isActive == true) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_host != null && _port != null && !state.isConnected) {
        if (kDebugMode) print('재연결 시도...');
        connect(_host!, _port!);
      }
    });
  }

  // 주기적 ping 타이머 시작 (30초마다)
  void _startPingTimer() {
    _pingTimer?.cancel();
    if (kDebugMode) print('Ping 타이머 시작: 30초 주기');
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state.isConnected && _socket != null) {
        try {
          // 바이너리 ping 메시지 전송
          final pingMessage = _encodeBinaryMessage(KtwBinaryMessageType.ping, Uint8List(0));
          _socket!.add(pingMessage);
          if (kDebugMode) {
            print('Naradevice: 바이너리 ping 전송 (타이머 ${timer.tick}회차)');
          }
        } catch (e) {
          if (kDebugMode) {
            print('ping 전송 오류: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('ping 전송 건너뜀: 연결상태=${state.isConnected}, 소켓=${_socket != null}');
        }
      }
    });
  }

  // 바이너리 Connect 메시지 전송 (infree와 동일한 방식)
  Future<void> _sendConnectMessage() async {
    if (_socket == null || state.companyCode == null) return;

    try {
      final userCode = '${state.companyCode!}02'; // 기본 사용자 코드

      // 바이너리 Connect 메시지 데이터 인코딩 (Connect용 - 간단한 형식)
      final connectData = _encodeBinaryConnectData(state.companyCode!, userCode, 'naradevice');

      // 바이너리 Connect 메시지 인코딩
      final connectMessage = _encodeBinaryMessage(KtwBinaryMessageType.connect, connectData);

      // 전송
      _socket!.add(connectMessage);

      if (kDebugMode) {
        print('[CONNECT] 바이너리 Connect 메시지 전송: 회사코드=${state.companyCode}, 사용자코드=$userCode, 소스=naradevice');
      }
    } catch (e) {
      if (kDebugMode) print('Connect 메시지 전송 실패: $e');
    }
  }

  // 전원 제어 메시지 전송 (항상 바이너리로만 전송)
  Future<void> sendPowerControlMessage(String roomCode, String seatNumber, String powerNumber) async {
    if (_socket == null || state.companyCode == null) {
      if (kDebugMode) print('소켓이 연결되지 않았거나 회사코드가 설정되지 않음');
      return;
    }

    try {
      final userCode = '${state.companyCode!}02'; // 기본 사용자 코드
      final timestamp = DateTime.now().toIso8601String();

      // 바이너리 메시지 데이터 인코딩
      final messageData = _encodeBinaryMessageData(state.companyCode!, userCode, 'naradevice', roomCode, seatNumber, powerNumber, timestamp);

      // 바이너리 메시지 인코딩
      final binaryMessage = _encodeBinaryMessage(KtwBinaryMessageType.message, messageData);

      // 전송
      _socket!.add(binaryMessage);

      if (kDebugMode) {
        print('바이너리 메시지 전송: 회사=${state.companyCode}, 방=$roomCode, 좌석=$seatNumber, 전원=$powerNumber');
      }

      // 전송된 메시지를 목록에 추가
      final sentMessage = Message(companyCode: state.companyCode!, userCode: userCode, roomCode: roomCode, seatNumber: seatNumber, powerNumber: powerNumber, source: 'naradevice', isSent: true);

      final newMessages = [...state.messages, sentMessage];
      state = state.copyWith(messages: newMessages);
    } catch (e) {
      if (kDebugMode) print('메시지 전송 실패: $e');
    }
  }

  // 퐁 메시지 전송
  void _sendPong() {
    if (_socket == null) return;

    try {
      final pongMessage = _encodeBinaryMessage(KtwBinaryMessageType.pong, Uint8List(0));
      _socket!.add(pongMessage);
    } catch (e) {
      if (kDebugMode) print('퐁 전송 실패: $e');
    }
  }

  // Naradevice 인증 헤더 생성: (랜덤1+랜덤2) & 0xFF XOR 랜덤3
  Uint8List _generateNaradeviceAuth() {
    final random = Random.secure();
    final byte1 = random.nextInt(256);
    final byte2 = random.nextInt(256);
    final byte3 = random.nextInt(256);
    final byte4 = ((byte1 + byte2) & 0xFF) ^ byte3;

    return Uint8List.fromList([byte1, byte2, byte3, byte4]);
  }

  // 바이너리 메시지 인코딩
  Uint8List _encodeBinaryMessage(int messageType, Uint8List data) {
    final buffer = ByteData(9 + data.length);

    // 인증 헤더 (4바이트)
    final auth = _generateNaradeviceAuth();
    buffer.setUint8(0, auth[0]);
    buffer.setUint8(1, auth[1]);
    buffer.setUint8(2, auth[2]);
    buffer.setUint8(3, auth[3]);

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

  // 바이너리 Connect 메시지 데이터 인코딩 (간단한 형식)
  Uint8List _encodeBinaryConnectData(String companyCode, String userCode, String source) {
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

    return Uint8List.fromList(buffer);
  }

  // 바이너리 메시지 데이터 인코딩
  Uint8List _encodeBinaryMessageData(String companyCode, String userCode, String source, String roomCode, String seatNumber, String powerNumber, String timestamp) {
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

  // 메시지 기록 초기화
  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}

// Provider 정의
final tcpServiceProvider = StateNotifierProvider<TCPServiceNotifier, TCPState>((ref) {
  return TCPServiceNotifier();
});

// 연결 상태만 확인하는 Provider
final tcpConnectedProvider = Provider<bool>((ref) {
  return ref.watch(tcpServiceProvider).isConnected;
});
