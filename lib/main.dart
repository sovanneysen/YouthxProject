import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/network/socket_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

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
      // Product requirement: light mode only.
      themeMode: ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      initialRoute: AppRoutes.community,
      getPages: AppPages.routes,
    );
  }
}
