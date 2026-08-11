import 'user_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final UserModel author;
  final String text;
  final DateTime createdAt;

  /// Null for a top-level comment. When set, this comment is a reply to
  /// the comment with this id — used to build a one-level thread
  /// (reply-to-comment), so replies stay attached to their parent.
  final String? parentId;

  CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.parentId,
  });

  bool get isReply => parentId != null;

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as String,
        postId: json['postId'] as String,
        author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        parentId: json['parentId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'author': author.toJson(),
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'parentId': parentId,
      };
}

class PostModel {
  final String id;
  final UserModel author;
  DateTime createdAt;
  String caption;
  List<String> imagePaths; // local file paths or network urls
  String? feelingId;
  List<String> tags;
  int likeCount;
  bool likedByMe;
  bool savedByMe;
  bool sharedByMe;
  int commentCount;
  String visibility;

  PostModel({
    required this.id,
    required this.author,
    required this.createdAt,
    required this.caption,
    this.imagePaths = const [],
    this.feelingId,
    this.tags = const [],
    this.likeCount = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.sharedByMe = false,
    this.commentCount = 0,
    this.visibility = 'Public',
  });

  /// Only the original author can edit or delete their own post.
  bool isOwner(String currentUserId) => author.id == currentUserId;

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String,
        author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
        caption: json['caption'] as String,
        imagePaths: List<String>.from(json['imagePaths'] as List? ?? []),
        feelingId: json['feelingId'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        likeCount: json['likeCount'] as int? ?? 0,
        likedByMe: json['likedByMe'] as bool? ?? false,
        savedByMe: json['savedByMe'] as bool? ?? false,
        sharedByMe: json['sharedByMe'] as bool? ?? false,
        commentCount: json['commentCount'] as int? ?? 0,
        visibility: json['visibility'] as String? ?? 'Public',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'caption': caption,
        'imagePaths': imagePaths,
        'feelingId': feelingId,
        'tags': tags,
        'likeCount': likeCount,
        'likedByMe': likedByMe,
        'savedByMe': savedByMe,
        'sharedByMe': sharedByMe,
        'commentCount': commentCount,
        'visibility': visibility,
      };
}
