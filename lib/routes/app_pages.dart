import 'package:get/get.dart';

import '../auth/views/auth_screen.dart';
import '../auth/views/home_screen.dart';
import '../auth/views/notifi_screen.dart';
import '../auth/views/onboarding_screen.dart';
import '../auth/views/splash_screen.dart';
import '../auth/views/verify_screen.dart';
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
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.auth, page: () => const AuthScreen()),
    GetPage(name: AppRoutes.verify, page: () => const VerifyEmailScreen()),
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
    ),
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
