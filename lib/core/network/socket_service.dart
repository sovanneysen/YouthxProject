import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_config.dart';

/// A thin realtime layer built on [WebSocketChannel].
///
/// Every payload sent/received is a JSON object shaped like:
/// `{ "channel": "post:123", "type": "comment", "data": {...} }`
///
/// Screens subscribe with [on] and filter by `channel`, so comments on a
/// post and messages in a chat thread can share one physical socket
/// connection exactly like a production app would multiplex rooms over a
/// single websocket.
///
/// If [AppConfig.useMockBackend] is true (or the real socket fails to
/// connect), events are instead broadcast through an in-memory
/// [StreamController] so the UI keeps working with zero backend - this is
/// what "realtime without refresh" is powered by in this demo build. Point
/// [AppConfig.socketUrl] at a real server and flip the flag off to go live.
class RealtimeSocketService {
  RealtimeSocketService._internal();
  static final RealtimeSocketService instance = RealtimeSocketService._internal();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _localBus =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _connected = false;

  Future<void> connect() async {
    if (_connected) return;
    _connected = true;

    if (AppConfig.useMockBackend) return; // local bus only

    try {
      final channel = WebSocketChannel.connect(Uri.parse(AppConfig.socketUrl));
      _channel = channel;
      channel.stream.listen(
        (raw) {
          try {
            final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
            _localBus.add(decoded);
          } catch (_) {
            // ignore malformed frames (e.g. echo server sends back raw text)
          }
        },
        onError: (_) {},
        onDone: () {
          _channel = null;
        },
      );
    } catch (_) {
      _channel = null;
    }
  }

  /// Broadcast [data] under [channel]. Also fans it back into the local bus
  /// immediately so the sender's own UI updates instantly (optimistic +
  /// realtime), matching how most chat/comment UIs behave.
  void emit(String channel, String type, Map<String, dynamic> data) {
    final payload = {'channel': channel, 'type': type, 'data': data};
    _localBus.add(payload);
    _channel?.sink.add(jsonEncode(payload));
  }

  /// Listen to every event on [channel].
  Stream<Map<String, dynamic>> on(String channel) {
    return _localBus.stream.where((event) => event['channel'] == channel);
  }

  void dispose() {
    _channel?.sink.close();
    _localBus.close();
    _connected = false;
  }
}
