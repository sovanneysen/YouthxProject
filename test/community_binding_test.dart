import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/core/network/token_store.dart';
import 'package:youthx/data/providers/api_provider.dart';
import 'package:youthx/data/repositories/community_repository.dart';
import 'package:youthx/data/repositories/rest_community_repository.dart';
import 'package:youthx/modules/community/binding/community_binding.dart';
import 'package:youthx/modules/community/controllers/community_controller.dart';

class _OfflineApiProvider extends ApiProvider {
  _OfflineApiProvider() : super(tokenStore: MemoryTokenStore());

  @override
  Future<dynamic> get(String path) async => <String, dynamic>{'content': <dynamic>[]};

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> delete(String path) async => null;
}

void main() {
  setUp(Get.reset);

  test('CommunityBinding wires the REST repository by default', () async {
    Get.put<ApiProvider>(_OfflineApiProvider());

    CommunityBinding().dependencies();

    final repository = Get.find<CommunityRepository>();
    expect(repository, isA<RestCommunityRepository>());

    final controller = Get.find<CommunityController>();
    expect(controller.repository, same(repository));

    await controller.loadFeed();
    expect(controller.feedError.value, isNull);
  });

  test('CommunityBinding keeps an already-registered repository', () {
    Get.put<ApiProvider>(_OfflineApiProvider());
    final existing = MockCommunityRepository();
    Get.put<CommunityRepository>(existing, permanent: true);

    CommunityBinding().dependencies();

    expect(Get.find<CommunityRepository>(), same(existing));
  });
}