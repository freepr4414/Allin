import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _companyCode;
  String? _userCode;
  final List<String> _messages = [];

  bool get isConnected => _isConnected;
  String? get companyCode => _companyCode;
  String? get userCode => _userCode;
  List<String> get messages => List.unmodifiable(_messages);

  Future<bool> connect(
    String host,
    int port,
    String companyCode,
    String userCode,
  ) async {
    try {
      _companyCode = companyCode;
      _userCode = userCode;

      final uri = Uri.parse('ws://$host:$port/ws');
      _channel = IOWebSocketChannel.connect(uri);

      // 연결 성공 처리
      _isConnected = true;
      notifyListeners();

      // 메시지 수신 처리
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _handleError(error);
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // Connect 메시지 전송
      await _sendConnectMessage();

      _addMessage('서버에 연결되었습니다: $host:$port (회사코드: $companyCode)');
      return true;
    } catch (e) {
      _addMessage('연결 실패: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
      _channel = null;
      _isConnected = false;
      _addMessage('서버 연결이 해제되었습니다');
      notifyListeners();
    } catch (e) {
      _addMessage('연결 해제 중 오류: $e');
    }
  }

  Future<void> sendMessage(
    String roomCode,
    String seatNumber,
    String powerNumber,
  ) async {
    if (!_isConnected ||
        _channel == null ||
        _companyCode == null ||
        _userCode == null) {
      _addMessage('오류: 서버에 연결되지 않았습니다');
      return;
    }

    try {
      final timestamp = DateTime.now().toIso8601String();
      final binaryMessage = _createBinaryMessage(
        _companyCode!,
        _userCode!,
        'naradesk',
        roomCode,
        seatNumber,
        powerNumber,
        timestamp,
      );

      _channel!.sink.add(binaryMessage);
      _addMessage('메시지 전송: 방=$roomCode, 좌석=$seatNumber, 전원=$powerNumber');
    } catch (e) {
      _addMessage('메시지 전송 실패: $e');
    }
  }

  Future<void> _sendConnectMessage() async {
    if (_channel == null || _companyCode == null || _userCode == null) return;

    try {
      final connectMessage = _createConnectMessage(
        _companyCode!,
        _userCode!,
        'naradesk',
      );
      _channel!.sink.add(connectMessage);
      _addMessage('Connect 메시지 전송완료');
    } catch (e) {
      _addMessage('Connect 메시지 전송 실패: $e');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      if (data is List<int>) {
        // 바이너리 메시지 처리
        final decodedData = _decodeBinaryMessage(Uint8List.fromList(data));
        _addMessage('수신: ${decodedData.toString()}');
      } else if (data is String) {
        // 텍스트 메시지 처리 (필요시)
        _addMessage('텍스트 수신: $data');
      }
    } catch (e) {
      _addMessage('메시지 처리 실패: $e');
    }
  }

  void _handleError(error) {
    _addMessage('WebSocket 오류: $error');
    _isConnected = false;
    notifyListeners();
  }

  void _handleDisconnect() {
    _addMessage('서버 연결이 종료되었습니다');
    _isConnected = false;
    _channel = null;
    notifyListeners();
  }

  void _addMessage(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _messages.add('[$timestamp] $message');
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // 바이너리 Connect 메시지 생성
  Uint8List _createConnectMessage(
    String companyCode,
    String userCode,
    String source,
  ) {
    final connectData = _encodeConnectData(companyCode, userCode, source);
    return _encodeBinaryMessage(1, connectData); // 1 = Connect type
  }

  // 바이너리 일반 메시지 생성
  Uint8List _createBinaryMessage(
    String companyCode,
    String userCode,
    String source,
    String roomCode,
    String seatNumber,
    String powerNumber,
    String timestamp,
  ) {
    final messageData = _encodeMessageData(
      companyCode,
      userCode,
      source,
      roomCode,
      seatNumber,
      powerNumber,
      timestamp,
    );
    return _encodeBinaryMessage(2, messageData); // 2 = Message type
  }

  // Connect 데이터 인코딩
  Uint8List _encodeConnectData(
    String companyCode,
    String userCode,
    String source,
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

    return Uint8List.fromList(buffer);
  }

  // 메시지 데이터 인코딩
  Uint8List _encodeMessageData(
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

  // naradesk용 인증 헤더 생성 (첫 3바이트 합산)
  int _generateNaradeskAuth() {
    final random = Random();
    final byte1 = random.nextInt(256);
    final byte2 = random.nextInt(256);
    final byte3 = random.nextInt(256);
    final byte4 = (byte1 + byte2 + byte3) & 0xFF;

    return (byte1 << 24) | (byte2 << 16) | (byte3 << 8) | byte4;
  }

  // 바이너리 메시지 인코딩 (naracontrol 서버 포맷)
  Uint8List _encodeBinaryMessage(int messageType, Uint8List data) {
    final List<int> buffer = [];

    // naradesk 인증 헤더 생성 (4바이트, Big Endian)
    final auth = _generateNaradeskAuth();
    buffer.add((auth >> 24) & 0xFF);
    buffer.add((auth >> 16) & 0xFF);
    buffer.add((auth >> 8) & 0xFF);
    buffer.add(auth & 0xFF);

    // 메시지 타입
    buffer.add(messageType);

    // 데이터 길이 (Big Endian, 4바이트)
    final dataLength = data.length;
    buffer.add((dataLength >> 24) & 0xFF);
    buffer.add((dataLength >> 16) & 0xFF);
    buffer.add((dataLength >> 8) & 0xFF);
    buffer.add(dataLength & 0xFF);

    // 데이터
    buffer.addAll(data);

    return Uint8List.fromList(buffer);
  }

  // 바이너리 메시지 디코딩 (naracontrol 서버 포맷)
  Map<String, dynamic> _decodeBinaryMessage(Uint8List data) {
    int offset = 0;

    // 최소 길이 확인 (인증 4 + 타입 1 + 길이 4 = 9바이트)
    if (data.length < 9) throw Exception('메시지가 너무 짧음');

    // 인증 헤더 건너뛰기 (4바이트)
    offset += 4;

    // 메시지 타입
    final messageType = data[offset++];

    // 데이터 길이 (Big Endian, 4바이트)
    final dataLength =
        (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
    offset += 4;

    // 데이터 추출
    if (offset + dataLength > data.length) {
      throw Exception('데이터 길이 불일치');
    }

    final messageData = data.sublist(offset, offset + dataLength);

    return {'type': messageType, 'data': _decodeMessageData(messageData)};
  }

  // 메시지 데이터 디코딩
  Map<String, String> _decodeMessageData(Uint8List data) {
    int offset = 0;
    final result = <String, String>{};

    try {
      // 회사코드
      if (offset >= data.length) throw Exception('회사코드 길이 필드 없음');
      int companyLen = data[offset++];
      if (offset + companyLen > data.length) throw Exception('회사코드 데이터 부족');
      result['companyCode'] = utf8.decode(
        data.sublist(offset, offset + companyLen),
      );
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

      // 방코드 (메시지 타입인 경우만)
      if (offset < data.length) {
        int roomLen = data[offset++];
        if (offset + roomLen <= data.length) {
          result['roomCode'] = utf8.decode(
            data.sublist(offset, offset + roomLen),
          );
          offset += roomLen;

          // 좌석번호
          if (offset < data.length) {
            int seatLen = data[offset++];
            if (offset + seatLen <= data.length) {
              result['seatNumber'] = utf8.decode(
                data.sublist(offset, offset + seatLen),
              );
              offset += seatLen;

              // 전원번호
              if (offset < data.length) {
                int powerLen = data[offset++];
                if (offset + powerLen <= data.length) {
                  result['powerNumber'] = utf8.decode(
                    data.sublist(offset, offset + powerLen),
                  );
                  offset += powerLen;

                  // 타임스탬프
                  if (offset < data.length) {
                    int timestampLen = data[offset++];
                    if (offset + timestampLen <= data.length) {
                      result['timestamp'] = utf8.decode(
                        data.sublist(offset, offset + timestampLen),
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
