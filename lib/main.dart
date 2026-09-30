import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth/views/splash_screen.dart';
import 'core/network/initial_binding.dart';
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(),
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
    );
  }
}
