import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls light/dark mode for the whole app.
/// The chosen mode is persisted via shared_preferences so it survives
/// restarts.
class ThemeController extends GetxController {
  static const String _storageKey = 'darkMode';

  final RxBool isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_storageKey) ?? false;
      if (saved != isDark.value) isDark.value = saved;
      Get.changeThemeMode(saved ? ThemeMode.dark : ThemeMode.light);
    } catch (_) {
      Get.changeThemeMode(ThemeMode.light);
    }
  }

  Future<void> toggle() async {
    isDark.value = !isDark.value;
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, isDark.value);
    } catch (_) {
      // Non-critical preference; keep the in-memory value.
    }
  }
}
