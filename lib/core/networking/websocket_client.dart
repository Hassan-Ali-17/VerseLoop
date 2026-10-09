import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../app/configuration/app_config.dart';

enum WsConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class WsEvent {
  final String event;
  final Map<String, dynamic> data;
  final String? eventId;
  final int? version;

  WsEvent({
    required this.event,
    required this.data,
    this.eventId,
    this.version,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      event: json['event'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      eventId: json['eventId'] as String?,
      version: json['version'] as int?,
    );
  }
}

class RealtimeClient {
  WebSocketChannel? _channel;
  WsConnectionStatus _status =
      AppConfig.isFixtureMode ? WsConnectionStatus.connected : WsConnectionStatus.connecting;

  final StreamController<WsEvent> _eventController = StreamController<WsEvent>.broadcast();
  final StreamController<WsConnectionStatus> _statusController =
      StreamController<WsConnectionStatus>.broadcast();

  final Set<String> _processedEventIds = {};
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  Stream<WsEvent> get events => _eventController.stream;
  Stream<WsConnectionStatus> get statusStream => _statusController.stream;
  WsConnectionStatus get status => _status;

  Future<void> connect() async {
    if (_isDisposed) return;
    if (AppConfig.isFixtureMode) {
      _setStatus(WsConnectionStatus.connected);
      return;
    }

    _setStatus(WsConnectionStatus.connecting);

    try {
      final uri = Uri.parse(AppConfig.webSocketUrl);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      channel.stream.listen(
        (message) => _onMessageReceived(message),
        onError: (err) {
          debugPrint('WebSocket stream error: $err');
          _onDisconnected();
        },
        onDone: () => _onDisconnected(),
      );

      // Wait for socket handshake to be ready before reporting connected
      await channel.ready;
      if (_isDisposed || _channel != channel) return;

      _setStatus(WsConnectionStatus.connected);
      _reconnectAttempts = 0;
    } catch (e) {
      debugPrint('WebSocket connection attempt failed: $e');
      _onDisconnected();
    }
  }

  void _onMessageReceived(dynamic message) {
    try {
      final json = jsonDecode(message.toString()) as Map<String, dynamic>;
      final event = WsEvent.fromJson(json);

      // Event deduplication check
      if (event.eventId != null) {
        if (_processedEventIds.contains(event.eventId)) {
          debugPrint('Duplicate WS Event ignored: ${event.eventId}');
          return;
        }
        _processedEventIds.add(event.eventId!);
        if (_processedEventIds.length > 200) {
          _processedEventIds.remove(_processedEventIds.first);
        }
      }

      _eventController.add(event);
    } catch (e) {
      debugPrint('Failed to parse WebSocket message: $e');
    }
  }

  void _onDisconnected() {
    if (_isDisposed) return;

    if (AppConfig.isFixtureMode) {
      _setStatus(WsConnectionStatus.connected);
      return;
    }

    // Keep status as reconnecting with stable retry backoff
    _setStatus(WsConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final backoffSeconds = max(3, min(pow(2, _reconnectAttempts).toInt(), 20));
    _reconnectAttempts++;

    debugPrint('WebSocket reconnecting in $backoffSeconds seconds (Attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (!_isDisposed && !AppConfig.isFixtureMode) {
        connect();
      }
    });
  }

  void emitLocalFixtureEvent(String eventName, Map<String, dynamic> data) {
    if (_isDisposed) return;
    _eventController.add(WsEvent(
      event: eventName,
      data: data,
      eventId: 'evt-${DateTime.now().millisecondsSinceEpoch}',
    ));
  }

  void _setStatus(WsConnectionStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _setStatus(WsConnectionStatus.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
    _statusController.close();
  }
}
