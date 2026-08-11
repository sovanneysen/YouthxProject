import 'package:get/get.dart';

import '../modules/community/binding/community_binding.dart';
import '../modules/community/views/community_view.dart';
import '../modules/messenger/binding/messenger_binding.dart';
import '../modules/messenger/views/messenger_list_view.dart';
import '../modules/profile/binding/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/story/binding/story_binding.dart';
import '../modules/story/views/story_editor_view.dart';
import '../modules/story/views/story_viewer_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: AppRoutes.community,
      page: () => const CommunityView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.messenger,
      page: () => const MessengerListView(),
      binding: MessengerBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.storyCreate,
      page: () => const StoryEditorView(),
      binding: StoryBinding(),
    ),
    GetPage(
      name: AppRoutes.storyView,
      page: () => StoryViewerView(args: Get.arguments as StoryViewerArgs),
    ),
  ];
}
