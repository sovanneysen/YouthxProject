import 'user_model.dart';

enum MessageType { text, image, voice }

class MessageModel {
  final String id;
  final String threadId;
  final UserModel sender;
  final MessageType type;
  final String? text;
  final String? mediaPath; // image or audio file path / url
  final Duration? voiceDuration;
  final DateTime createdAt;
  bool isRead;

  MessageModel({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.type,
    this.text,
    this.mediaPath,
    this.voiceDuration,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        threadId: json['threadId'] as String,
        sender: UserModel.fromJson(json['sender'] as Map<String, dynamic>),
        type: MessageType.values.firstWhere((e) => e.name == json['type']),
        text: json['text'] as String?,
        mediaPath: json['mediaPath'] as String?,
        voiceDuration: json['voiceDurationMs'] != null
            ? Duration(milliseconds: json['voiceDurationMs'] as int)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'threadId': threadId,
        'sender': sender.toJson(),
        'type': type.name,
        'text': text,
        'mediaPath': mediaPath,
        'voiceDurationMs': voiceDuration?.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };
}

class ThreadModel {
  final String id;
  final UserModel peer;
  MessageModel? lastMessage;
  int unreadCount;

  ThreadModel({
    required this.id,
    required this.peer,
    this.lastMessage,
    this.unreadCount = 0,
  });
}
