import 'package:uuid/uuid.dart';

import '../../core/network/app_config.dart';
import '../../core/network/socket_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'community_repository.dart';

abstract class ChatRepository {
  Future<List<ThreadModel>> fetchThreads();
  Future<List<MessageModel>> fetchMessages(String threadId);
  Future<void> sendMessage(MessageModel message);
  Stream<MessageModel> watchThread(String threadId);
}

String chatChannel(String threadId) => 'chat:$threadId';

class MockChatRepository implements ChatRepository {
  final _uuid = const Uuid();
  static final UserModel me = UserModel(id: AppConfig.currentUserId, name: 'You');

  final List<ThreadModel> _threads = [];
  final Map<String, List<MessageModel>> _messages = {};

  MockChatRepository() {
    _seed();
  }

  void _seed() {
    final peers = [
      MockCommunityRepository.alex,
      MockCommunityRepository.priya,
      MockCommunityRepository.marcus,
    ];
    final openers = [
      'Hey! Saw your post, great job 🎉',
      'Are you joining the meetup this week?',
      'Let\'s catch up soon!',
    ];

    for (var i = 0; i < peers.length; i++) {
      final threadId = _uuid.v4();
      final firstMessage = MessageModel(
        id: _uuid.v4(),
        threadId: threadId,
        sender: peers[i],
        type: MessageType.text,
        text: openers[i],
        createdAt: DateTime.now().subtract(Duration(minutes: (i + 1) * 12)),
      );
      _messages[threadId] = [firstMessage];
      _threads.add(ThreadModel(
        id: threadId,
        peer: peers[i],
        lastMessage: firstMessage,
        unreadCount: i == 0 ? 1 : 0,
      ));
    }
  }

  @override
  Future<List<ThreadModel>> fetchThreads() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _threads.sort((a, b) =>
        (b.lastMessage?.createdAt ?? DateTime.now()).compareTo(a.lastMessage?.createdAt ?? DateTime.now()));
    return List.unmodifiable(_threads);
  }

  @override
  Future<List<MessageModel>> fetchMessages(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_messages[threadId] ?? []);
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    _messages.putIfAbsent(message.threadId, () => []).add(message);
    final thread = _threads.firstWhere((t) => t.id == message.threadId);
    thread.lastMessage = message;

    RealtimeSocketService.instance.emit(chatChannel(message.threadId), 'message', message.toJson());
  }

  @override
  Stream<MessageModel> watchThread(String threadId) {
    return RealtimeSocketService.instance
        .on(chatChannel(threadId))
        .where((event) => event['type'] == 'message')
        .map((event) => MessageModel.fromJson(event['data'] as Map<String, dynamic>));
  }
}
