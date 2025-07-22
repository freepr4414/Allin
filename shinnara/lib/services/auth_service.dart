import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'websocket_service.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  User? _currentUser;
  final WebSocketService _webSocketService = WebSocketService();

  // 임시 데이터베이스로 사용할 사용자 맵
  final List<User> _users = [const User(companyCode: 'a1', userCode: 'a101', password: '1111'), const User(companyCode: 'a1', userCode: 'a102', password: '1111'), const User(companyCode: 'a2', userCode: 'a201', password: '1111'), const User(companyCode: 'a2', userCode: 'a202', password: '1111')];

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  WebSocketService get webSocketService => _webSocketService;

  AuthService() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      final userData = jsonDecode(userJson);
      for (var user in _users) {
        if (user.companyCode == userData['companyCode'] && user.userCode == userData['userCode']) {
          _currentUser = user;
          _isLoggedIn = true;
          await _connectToWebSocket();
          notifyListeners();
          break;
        }
      }
    }
  }

  Future<bool> login(String companyCode, String userCode, String password) async {
    for (var user in _users) {
      if (user.companyCode == companyCode && user.userCode == userCode && user.password == password) {
        _currentUser = user;
        _isLoggedIn = true;

        // 사용자 정보 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode({'companyCode': user.companyCode, 'userCode': user.userCode}));

        // WebSocket 연결
        await _connectToWebSocket();

        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    _webSocketService.disconnect();
    _isLoggedIn = false;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    notifyListeners();
  }

  Future<void> _connectToWebSocket() async {
    if (_currentUser != null) {
      if (kDebugMode) {
        print('연결 시작: ${_currentUser!.companyCode}, ${_currentUser!.userCode}');
      }
      await _webSocketService.connect(_currentUser!.companyCode, _currentUser!.userCode);
    }
  }

  // 앱이 백그라운드에서 포그라운드로 돌아올 때 연결 복원
  Future<void> ensureConnected() async {
    if (_isLoggedIn && _currentUser != null && !_webSocketService.isConnected) {
      if (kDebugMode) {
        print('소켓 연결 복원 중...');
      }
      await _connectToWebSocket();
    }
  }
}
