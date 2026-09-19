import 'package:uuid/uuid.dart';

import '../../core/network/app_config.dart';
import '../../core/network/socket_service.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
abstract class CommunityRepository {
  Future<List<PostModel>> fetchFeed();
  Future<PostModel> createPost(PostModel post);
  Future<void> updatePost(PostModel post);
  Future<void> deletePost(String postId);
  Future<void> toggleLike(String postId);
  Future<void> toggleSave(String postId);
  Future<void> toggleShare(String postId);

  /// Uploads a local photo for [postId] and returns its public URL.
  Future<String> uploadPhoto(String postId, String filePath);

  Future<List<UserModel>> searchUsers(String query);

  Future<List<CommentModel>> fetchComments(String postId);

  /// Returns the persisted comment so callers (and realtime subscribers) can
  /// insert it without a refetch. Null when the backend did not return it.
  Future<CommentModel?> addComment(String postId, String text,
      {String? parentId});

  Future<void> deleteComment(String postId, String commentId);

  Stream<CommentModel> watchComments(String postId);

  Future<List<StoryModel>> fetchStories();
  Future<void> addStory(StoryModel story);
  Future<void> updateStory(StoryModel story);
  Future<void> deleteStory(String storyId);

  /// Drafts saved from the story editor without publishing them to the feed.
  Future<List<StoryModel>> fetchDraftStories();
  Future<void> addDraftStory(StoryModel story);
}

String commentsChannel(String postId) => 'post:$postId:comments';

class MockCommunityRepository implements CommunityRepository {
  final _uuid = const Uuid();
  final List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _comments = {};
  final List<StoryModel> _stories = [];
  final List<StoryModel> _drafts = [];

  static final UserModel me = UserModel(id: AppConfig.currentUserId, name: 'You');
  static final UserModel alex = UserModel(id: 'u1', name: 'Alex Johnson');
  static final UserModel priya = UserModel(id: 'u2', name: 'Priya Sharma');
  static final UserModel marcus = UserModel(id: 'u3', name: 'Marcus Lee');
  static final UserModel sofia = UserModel(id: 'u4', name: 'Sofia Rossi');

  MockCommunityRepository() {
    _seed();
  }

  void _seed() {
    _posts.addAll([
      PostModel(
        id: _uuid.v4(),
        author: alex,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        caption:
            'Just hit my 7-day reading streak! 🎉 Consistency truly is everything. What goals are you all working on right now?',
        feelingId: 'proud',
        tags: const ['Goals', 'Reading'],
        likeCount: 24,
        commentCount: 3,
      ),
      PostModel(
        id: _uuid.v4(),
        author: priya,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        caption: 'Finally finished my budgeting spreadsheet for the month. Small wins add up!',
        feelingId: 'motivated',
        tags: const ['Finance'],
        likeCount: 12,
        commentCount: 1,
      ),
      PostModel(
        id: _uuid.v4(),
        author: marcus,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        caption: 'Community meetup this weekend was amazing. Thanks to everyone who came out 🙌',
        feelingId: 'grateful',
        tags: const ['Community'],
        likeCount: 41,
        commentCount: 5,
      ),
    ]);

    for (final p in _posts) {
      _comments[p.id] = [];
    }

    _stories.addAll([
      StoryModel(id: _uuid.v4(), author: priya, imagePath: '', createdAt: DateTime.now()),
      StoryModel(id: _uuid.v4(), author: marcus, imagePath: '', createdAt: DateTime.now()),
      StoryModel(id: _uuid.v4(), author: sofia, imagePath: '', createdAt: DateTime.now()),
    ]);
  }

  @override
  Future<List<PostModel>> fetchFeed() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_posts);
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _posts.insert(0, post);
    _comments[post.id] = [];
    return post;
  }

  @override
  Future<void> updatePost(PostModel post) async {
    final idx = _posts.indexWhere((p) => p.id == post.id);
    if (idx != -1) _posts[idx] = post;
  }

  @override
  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    _comments.remove(postId);
  }

  @override
  Future<void> toggleLike(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.likedByMe = !post.likedByMe;
    post.likeCount += post.likedByMe ? 1 : -1;
  }

  @override
  Future<void> toggleSave(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.savedByMe = !post.savedByMe;
  }

  @override
  Future<void> toggleShare(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.sharedByMe = !post.sharedByMe;
  }

  @override
  Future<String> uploadPhoto(String postId, String filePath) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'mock://uploads/$postId/${filePath.split('/').last}';
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    // People search: substring match on name, names starting with the query
    // ranked first so closely-matching profiles surface at the top.
    final candidates = [me, alex, priya, marcus, sofia];
    final matches = candidates.where((u) => u.name.toLowerCase().contains(q)).toList();
    matches.sort((a, b) {
      final aStart = a.name.toLowerCase().startsWith(q) ? 0 : 1;
      final bStart = b.name.toLowerCase().startsWith(q) ? 0 : 1;
      return aStart.compareTo(bStart);
    });
    return matches;
  }

  @override
  Future<List<CommentModel>> fetchComments(String postId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_comments[postId] ?? []);
  }

  @override
  Future<CommentModel?> addComment(String postId, String text,
      {String? parentId}) async {
    final comment = CommentModel(
      id: _uuid.v4(),
      postId: postId,
      author: me,
      text: text,
      createdAt: DateTime.now(),
      parentId: parentId,
    );
    _comments.putIfAbsent(postId, () => []).add(comment);
    final post = _posts.firstWhere((p) => p.id == postId);
    post.commentCount += 1;

    // Publish over the realtime channel so every open comment sheet for
    // this post (this device and, in a real backend, every other device)
    // updates instantly without a manual refresh.
    RealtimeSocketService.instance.emit(
      commentsChannel(postId),
      'comment',
      comment.toJson(),
    );
    return comment;
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    _comments[postId]?.removeWhere((c) => c.id == commentId);
    final post = _posts.firstWhere((p) => p.id == postId);
    post.commentCount = (post.commentCount - 1).clamp(0, 1 << 31).toInt();
  }

  @override
  Stream<CommentModel> watchComments(String postId) {
    return RealtimeSocketService.instance
        .on(commentsChannel(postId))
        .where((event) => event['type'] == 'comment')
        .map((event) => CommentModel.fromJson(event['data'] as Map<String, dynamic>));
  }

  @override
  Future<List<StoryModel>> fetchStories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Stories older than 24h stop showing up here — no cleanup job needed,
    // expiry is enforced purely by this filter when the feed (re)loads.
    return _stories.where((s) => !s.isExpired).toList();
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
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_drafts);
  }

  @override
  Future<void> addDraftStory(StoryModel story) async {
    _drafts.insert(0, story);
  }
}
