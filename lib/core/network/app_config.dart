/// Central place to point the app at a real backend.
///
/// Swap [socketUrl] / [apiBaseUrl] for your production endpoints. Until then
/// the app runs fully offline using [MockCommunityRepository] /
/// [MockChatRepository] plus an in-memory realtime bus, so every screen
/// (feed, comments, messenger, chat) is fully interactive out of the box.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.youthx.app',
  );

  /// A single websocket endpoint used both for realtime post comments and
  /// chat messages. Real backends typically multiplex channels/rooms over
  /// one socket connection using a `channel` field in the payload, which is
  /// how [RealtimeSocketService] frames every message.
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'wss://echo.websocket.events',
  );

  /// When true, the app doesn't attempt a real network connection and only
  /// uses the in-memory realtime bus (handy for demos / offline dev).
  static const bool useMockBackend = true;

  static const String currentUserId = 'me';
}
