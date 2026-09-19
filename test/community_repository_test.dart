import 'package:flutter_test/flutter_test.dart';

import 'package:youthx/core/network/token_store.dart';
import 'package:youthx/data/models/post_model.dart';
import 'package:youthx/data/models/story_model.dart';
import 'package:youthx/data/models/user_model.dart';
import 'package:youthx/data/providers/api_provider.dart';
import 'package:youthx/data/repositories/rest_community_repository.dart';

/// In-memory [ApiProvider] that returns canned payloads and records the last
/// request so tests can assert paths/bodies without any real HTTP call.
class _FakeApiProvider extends ApiProvider {
  _FakeApiProvider() : super(tokenStore: MemoryTokenStore());

  dynamic getData;
  dynamic postData;
  ApiException? failure;

  String? lastPath;
  Map<String, dynamic>? lastBody;
  int deleteCalls = 0;

  @override
  Future<dynamic> get(String path) async {
    if (failure != null) throw failure!;
    lastPath = path;
    return getData;
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    if (failure != null) throw failure!;
    lastPath = path;
    lastBody = body;
    return postData;
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    if (failure != null) throw failure!;
    lastPath = path;
    lastBody = body;
    return postData;
  }

  @override
  Future<dynamic> delete(String path) async {
    if (failure != null) throw failure!;
    lastPath = path;
    deleteCalls += 1;
    return null;
  }
}

Map<String, dynamic> postJson({
  String id = '1',
  String userId = 'u-1',
  String content = 'Hello youthx',
  String createdAt = '2026-09-19T10:00:00+07:00',
  int likeCount = 5,
  int commentCount = 2,
  bool likedByMe = true,
}) =>
    {
      'id': id,
      'userId': userId,
      'content': content,
      'photoUrls': <String>[],
      'createdAt': createdAt,
      'updatedAt': createdAt,
      'authorFullName': 'Draft UI User',
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedByMe': likedByMe,
    };

void main() {
  RestCommunityRepository repoWith(_FakeApiProvider fake) =>
      RestCommunityRepository(apiProvider: fake);

  group('RestCommunityRepository feed', () {
    test('parses the page payload into PostModel list ordered newest first',
        () async {
      final fake = _FakeApiProvider();
      fake.getData = {
        'content': [
          postJson(id: '10', createdAt: '2026-09-19T12:00:00+07:00'),
          postJson(id: '20', createdAt: '2026-09-18T09:00:00+07:00'),
        ],
        'page': 0,
        'size': 50,
        'totalElements': 2,
        'totalPages': 1,
      };

      final posts = await repoWith(fake).fetchFeed();

      expect(fake.lastPath, contains('/posts'));
      expect(posts, hasLength(2));
      expect(posts.first.id, '10');
      expect(posts.first.author.id, 'u-1');
      expect(posts.first.author.name, 'Draft UI User');
      expect(posts.first.caption, 'Hello youthx');
      expect(posts.first.likedByMe, isTrue);
      expect(posts.first.likeCount, 5);
      expect(posts.first.commentCount, 2);
    });

    test('rethrows the backend ApiException when the feed fails', () async {
      final fake = _FakeApiProvider()..failure = const ApiException(403, 'Forbidden');

      await expectLater(
        repoWith(fake).fetchFeed(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 403)
              .having((e) => e.message, 'message', 'Forbidden'),
        ),
      );
    });
  });

  group('RestCommunityRepository create post', () {
    test('posts content plus http photo urls and parses the created post',
        () async {
      final fake = _FakeApiProvider()..postData = postJson(id: '99');
      final repo = repoWith(fake);

      final created = await repo.createPost(
        PostModel(
          id: 'local-id',
          author: UserModel(id: 'u-1', name: 'You'),
          createdAt: DateTime.parse('2026-09-19T10:00:00+07:00'),
          caption: 'First real post',
          imagePaths: const ['/local/picked/image.jpg', 'https://cdn/x.jpg'],
        ),
      );

      expect(fake.lastPath, '/posts');
      expect(fake.lastBody!['content'], 'First real post');
      // Local file paths must not be sent (no upload endpoint exists yet).
      expect(fake.lastBody!['photoUrls'], ['https://cdn/x.jpg']);
      expect(created.id, '99');
      expect(created.caption, 'Hello youthx');
    });

    test('rethrows the backend error when create fails', () async {
      final fake = _FakeApiProvider()
        ..failure = const ApiException(400, 'content: must not be blank');
      final repo = repoWith(fake);

      await expectLater(
        repo.createPost(PostModel(
          id: 'x',
          author: UserModel(id: 'u-1', name: 'You'),
          createdAt: DateTime.now(),
          caption: '',
        )),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message',
              'content: must not be blank'),
        ),
      );
    });
  });

  group('RestCommunityRepository like', () {
    test('calls the toggle endpoint', () async {
      final fake = _FakeApiProvider()..postData = {'message': 'ok'};
      await repoWith(fake).toggleLike('7');

      expect(fake.lastPath, '/posts/7/like');
      expect(fake.lastBody, isEmpty);
    });

    test('rethrows when the like request fails', () async {
      final fake = _FakeApiProvider()..failure = const ApiException(500, 'boom');

      await expectLater(
        repoWith(fake).toggleLike('7'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('RestCommunityRepository comments', () {
    test('parses the comment page payload', () async {
      final fake = _FakeApiProvider();
      fake.getData = {
        'content': [
          {
            'id': 11,
            'postId': 7,
            'userId': 'u-9',
            'content': 'Nice work!',
            'createdAt': '2026-09-19T11:00:00+07:00',
            'authorFullName': 'Priya Sharma',
          },
        ],
        'page': 0,
        'size': 100,
        'totalElements': 1,
        'totalPages': 1,
      };

      final comments = await repoWith(fake).fetchComments('7');

      expect(fake.lastPath, contains('/posts/7/comments'));
      expect(comments, hasLength(1));
      expect(comments.first.id, '11');
      expect(comments.first.postId, '7');
      expect(comments.first.author.name, 'Priya Sharma');
      expect(comments.first.text, 'Nice work!');
    });

    test('posts a comment and parses the created comment', () async {
      final fake = _FakeApiProvider();
      fake.postData = {
        'id': 12,
        'postId': 7,
        'userId': 'u-1',
        'content': 'First!',
        'createdAt': '2026-09-19T12:00:00+07:00',
        'authorFullName': 'Draft UI User',
      };

      final created = await repoWith(fake).addComment('7', 'First!');

      expect(fake.lastPath, '/posts/7/comments');
      expect(fake.lastBody!['content'], 'First!');
      expect(created, isNotNull);
      expect(created!.text, 'First!');
      expect(created.postId, '7');
    });

    test('deletes a comment through the backend endpoint', () async {
      final fake = _FakeApiProvider();
      await repoWith(fake).deleteComment('7', '11');

      expect(fake.lastPath, '/posts/comments/11');
      expect(fake.deleteCalls, 1);
    });

    test('rethrows when comment requests fail', () async {
      final fake = _FakeApiProvider()..failure = const ApiException(404, 'missing');

      await expectLater(
        repoWith(fake).fetchComments('7'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        repoWith(fake).deleteComment('7', '11'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('RestCommunityRepository local-only features', () {
    test('save and share toggle locally without any request', () async {
      final fake = _FakeApiProvider();
      final repo = repoWith(fake);

      await repo.toggleSave('1');
      await repo.toggleShare('1');

      expect(fake.lastPath, isNull);
      expect(fake.deleteCalls, 0);
    });

    test('people search has no backend endpoint yet, so it returns empty',
        () async {
      expect(await repoWith(_FakeApiProvider()).searchUsers('alex'), isEmpty);
    });

    test('stories stay fully functional in memory', () async {
      final repo = repoWith(_FakeApiProvider());
      final story = StoryModel(
        id: 's1',
        author: UserModel(id: 'u-1', name: 'You'),
        imagePath: '',
        createdAt: DateTime.now(),
      );

      expect(await repo.fetchStories(), isEmpty);
      await repo.addStory(story);
      expect(await repo.fetchStories(), hasLength(1));

      story.viewed = true;
      await repo.updateStory(story);
      await repo.deleteStory('s1');
      expect(await repo.fetchStories(), isEmpty);

      await repo.addDraftStory(story);
      expect(await repo.fetchDraftStories(), hasLength(1));
    });

    test('comment realtime watch emits no fake events', () async {
      final repo = repoWith(_FakeApiProvider());
      expect(await repo.watchComments('1').isEmpty, isTrue);
    });
  });
}