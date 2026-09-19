import 'dart:async';

import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../providers/api_provider.dart';
import 'community_repository.dart';

/// REST-backed implementation of [CommunityRepository].
///
/// Contract verified from the Draft Backend `PostController`:
///
///   GET    /posts                    -> 200 PageResponse`<PostResponse>`
///   POST   /posts                    -> 201 PostResponse  (owner from JWT)
///   PUT    /posts/{id}               -> 200 PostResponse  (owner only)
///   DELETE /posts/{id}               -> 204               (owner only)
///   GET    /posts/{postId}/comments  -> 200 PageResponse`<CommentResponse>`
///   POST   /posts/{postId}/comments  -> 201 CommentResponse (owner from JWT)
///   DELETE /posts/comments/{id}      -> 204               (owner only)
///   POST   /posts/{postId}/like      -> 200 (toggle, owner from JWT)
///
/// Stories, drafts, save/share and people search have NO backend endpoints
/// yet, so they keep working through local in-memory state. This keeps the
/// Stories module, its editor and the profile story tray fully functional
/// without inventing fake REST contracts.
class RestCommunityRepository implements CommunityRepository {
  RestCommunityRepository({ApiProvider? apiProvider})
    : _api = apiProvider ?? ApiProvider();

  final ApiProvider _api;

  final List<StoryModel> _stories = [];
  final List<StoryModel> _drafts = [];
  final Set<String> _saved = <String>{};
  final Set<String> _shared = <String>{};

  static const int _feedPageSize = 50;
  static const int _commentsPageSize = 100;

  // ── Feed / posts ───────────────────────────────────────────

  @override
  Future<List<PostModel>> fetchFeed() async {
    final data = await _api.get('/posts?page=0&size=$_feedPageSize');
    final posts = _pageContent(data)
        .map((e) => _toPost(e as Map<String, dynamic>))
        .whereType<PostModel>()
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    final data = await _api.post('/posts', {
      'content': post.caption,
      // Only real URLs can be stored by the backend; locally picked image
      // files have no upload endpoint yet, so they are not sent.
      'photoUrls': post.imagePaths.where((p) => p.startsWith('http')).toList(),
    });
    final created = _toPost(data as Map<String, dynamic>);
    if (created == null) {
      throw const ApiException(0, 'The post could not be created.');
    }
    return created;
  }

  @override
  Future<void> updatePost(PostModel post) async {
    await _api.put('/posts/${post.id}', {'content': post.caption});
  }

  @override
  Future<void> deletePost(String postId) async {
    await _api.delete('/posts/$postId');
  }

  @override
  Future<void> toggleLike(String postId) async {
    await _api.post('/posts/$postId/like', const {});
  }

  @override
  Future<String> uploadPhoto(String postId, String filePath) async {
    final data = await _api.postMultipartFile(
      '/posts/$postId/photos',
      filePath,
    );
    final photoUrls = (data as Map<String, dynamic>)['photoUrls'] as List? ?? const [];
    if (photoUrls.isNotEmpty) {
      return photoUrls.last as String;
    }
    throw const ApiException(0, 'The photo could not be uploaded.');
  }

  // ── Local-only (no backend contract) ────────────────────────

  @override
  Future<void> toggleSave(String postId) async {
    if (!_saved.remove(postId)) _saved.add(postId);
  }

  @override
  Future<void> toggleShare(String postId) async {
    if (!_shared.remove(postId)) _shared.add(postId);
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async => const [];

  // ── Comments ──────────────────────────────────────────────

  @override
  Future<List<CommentModel>> fetchComments(String postId) async {
    final data = await _api.get('/posts/$postId/comments?page=0&size=$_commentsPageSize');
    final list = _pageContent(data);
    return list
        .map((e) => _toComment(e as Map<String, dynamic>))
        .whereType<CommentModel>()
        .toList();
  }

  @override
  Future<CommentModel?> addComment(
    String postId,
    String text, {
    String? parentId,
  }) async {
    // The Draft Backend has no parentId field; replies are submitted as
    // top-level comments.
    final data = await _api.post('/posts/$postId/comments', {
      'content': text,
    });
    return _toComment(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/posts/comments/$commentId');
  }

  @override
  Stream<CommentModel> watchComments(String postId) => Stream.empty();

  // ── Stories (local until a backend contract exists) ────────

  @override
  Future<List<StoryModel>> fetchStories() async {
    return List.unmodifiable(_stories.where((s) => !s.isExpired).toList());
  }

  @override
  Future<void> addStory(StoryModel story) async {
    _stories.insert(0, story);
  }

  @override
  Future<void> updateStory(StoryModel story) async {
    final idx = _stories.indexWhere((s) => s.id == story.id);
    if (idx != -1) _stories[idx] = story;
  }

  @override
  Future<void> deleteStory(String storyId) async {
    _stories.removeWhere((s) => s.id == storyId);
  }

  @override
  Future<List<StoryModel>> fetchDraftStories() async {
    return List.unmodifiable(_drafts);
  }

  @override
  Future<void> addDraftStory(StoryModel story) async {
    _drafts.insert(0, story);
  }

  // ── Helpers ─────────────────────────────────────────────────

  List<dynamic> _pageContent(dynamic data) {
    if (data is Map && data['content'] is List) {
      return data['content'] as List;
    }
    if (data is List) return data;
    return const [];
  }

  PostModel? _toPost(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) return null;
    return PostModel(
      id: id.toString(),
      author: UserModel(
        id: json['userId']?.toString() ?? '',
        name: (json['authorFullName'] as String?) ?? 'YouthX Member',
      ),
      createdAt: _parseDate(json['createdAt']),
      caption: (json['content'] as String?) ?? '',
      imagePaths: List<String>.from(json['photoUrls'] as List? ?? const []),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  CommentModel? _toComment(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) return null;
    return CommentModel(
      id: id.toString(),
      postId: json['postId']?.toString() ?? '',
      author: UserModel(
        id: json['userId']?.toString() ?? '',
        name: (json['authorFullName'] as String?) ?? 'YouthX Member',
      ),
      text: (json['content'] as String?) ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}