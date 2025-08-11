import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';

final webSocketServiceProvider = ChangeNotifierProvider<WebSocketService>((ref) {
  return WebSocketService();
});
