import 'package:flutter/foundation.dart';

class Message {
  final String companyCode;
  final String userCode;
  final String roomCode;
  final String seatNumber;
  final String powerNumber;
  final DateTime timestamp;
  final bool isSent; // 발신 메시지 여부
  final String source; // 메시지 출처 (infree 또는 naradevice)
  final String? rawData; // ASCII 원본 데이터

  Message({required this.companyCode, required this.userCode, required this.roomCode, required this.seatNumber, required this.powerNumber, DateTime? timestamp, this.isSent = false, this.source = 'unknown', this.rawData}) : timestamp = timestamp ?? DateTime.now();
  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    try {
      if (json['timestamp'] is int) {
        // 밀리초 타임스탬프 처리
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
      } else if (json['timestamp'] is String) {
        // ISO 형식 문자열 처리
        timestamp = DateTime.parse(json['timestamp'] as String);
      } else {
        // 기본값
        timestamp = DateTime.now();
      }
    } catch (e) {
      if (kDebugMode) print('Timestamp 파싱 오류: ${e.toString()}, 기본값 사용');
      timestamp = DateTime.now();
    }

    return Message(
      companyCode: json['companyCode'] as String,
      userCode: json['userCode'] as String,
      roomCode: json['roomCode'] as String,
      seatNumber: json['seatNumber'] as String,
      powerNumber: json['powerNumber'] as String,
      timestamp: timestamp,
      isSent: json['isSent'] as bool? ?? false,
      source: json['source'] as String? ?? 'unknown',
      rawData: json['rawData'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'companyCode': companyCode, 'userCode': userCode, 'roomCode': roomCode, 'seatNumber': seatNumber, 'powerNumber': powerNumber, 'timestamp': timestamp.toIso8601String(), 'isSent': isSent, 'source': source, if (rawData != null) 'rawData': rawData};
  }
}

class DeviceInfo {
  final String id;
  final String deviceId;
  final String type;
  final String address;

  DeviceInfo({required this.id, required this.deviceId, required this.type, required this.address});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(id: json['id'] as String, deviceId: json['deviceId'] as String, type: json['type'] as String, address: json['address'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'deviceId': deviceId, 'type': type, 'address': address};
  }
}
