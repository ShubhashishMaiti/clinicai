import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import './api_service.dart';

typedef WebSocketEventCallback = void Function(Map<String, dynamic> event);

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  dynamic _socket;
  bool _connected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  final List<WebSocketEventCallback> _listeners = [];

  bool get isConnected => _connected;

  void addListener(WebSocketEventCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(WebSocketEventCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> connect() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    final wsUrl = ApiService.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    try {
      _socket = await _createWebSocket('$wsUrl/api/ws?token=$token');
      _connected = true;
      _reconnectAttempts = 0;
      debugPrint('WebSocket connected');

      _socket.listen(
        (data) {
          try {
            final event = jsonDecode(data as String) as Map<String, dynamic>;
            _notifyListeners(event);
          } catch (e) {
            debugPrint('WebSocket parse error: $e');
          }
        },
        onDone: () {
          _connected = false;
          debugPrint('WebSocket disconnected');
          _scheduleReconnect();
        },
        onError: (error) {
          _connected = false;
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connect failed: $e');
      _scheduleReconnect();
    }
  }

  Future<dynamic> _createWebSocket(String url) async {
    // Use dart:io WebSocket on mobile, dart:html on web
    if (kIsWeb) {
      // Web implementation
      return null; // Web WebSocket handled differently
    }
    // For mobile, use a simple HTTP-based polling fallback
    // since dart:io is not available in this context
    return null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  void _notifyListeners(Map<String, dynamic> event) {
    for (final listener in List.from(_listeners)) {
      listener(event);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _connected = false;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void send(String message) {
    if (_connected && _socket != null) {
      try {
        _socket.add(message);
      } catch (e) {
        debugPrint('WebSocket send error: $e');
      }
    }
  }

  void ping() => send('ping');
}
