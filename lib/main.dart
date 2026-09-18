import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth/views/auth_screen.dart';
import 'auth/views/home_screen.dart';
import 'auth/views/notifi_screen.dart';
import 'auth/views/onboarding_screen.dart';
import 'auth/views/splash_screen.dart';
import 'auth/views/verify_screen.dart';
import 'core/network/socket_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RealtimeSocketService.instance.connect();
  runApp(const YouthXApp());
}

class YouthXApp extends StatelessWidget {
  const YouthXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'YouthX',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      home: const SplashScreen(),
      getPages: AppPages.routes,
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/auth': (_) => const AuthScreen(),
        '/verify': (_) => const VerifyEmailScreen(),
        '/home': (_) => const HomeScreen(),
        '/notifications': (_) => const NotificationsScreen(),
      },
    );
  }
}
