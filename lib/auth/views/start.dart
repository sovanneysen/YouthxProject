import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'verify_screen.dart';
import 'home_screen.dart';
import 'notifi_screen.dart';
class YouthXApp extends StatelessWidget {
  const YouthXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouthX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/verify': (context) => const VerifyEmailScreen(),
        '/home': (context) => const HomeScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}