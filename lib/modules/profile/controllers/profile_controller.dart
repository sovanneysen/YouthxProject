import 'package:get/get.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/community_repository.dart';

class ProfileController extends GetxController {
  final UserModel user;
  final CommunityRepository repository;

  final RxList<StoryModel> stories = <StoryModel>[].obs;

  ProfileController({required this.user, required this.repository});

  @override
  void onInit() {
    super.onInit();
    loadStories();
  }

  Future<void> loadStories() async {
    final all = await repository.fetchStories();
    stories.assignAll(all.where((s) => s.author.id == user.id));
  }

  /// The user's stories that are still visible (not expired), oldest first.
  List<StoryModel> get activeStories {
    final list = stories.where((s) => !s.isExpired).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }
}
