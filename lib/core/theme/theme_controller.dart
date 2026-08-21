import 'package:get/get.dart';

/// Controls light/dark mode for the whole app.
/// Not persisted yet — wire up shared_preferences once the backend
/// / local storage layer is connected.
class ThemeController extends GetxController {
  final RxBool isDark = false.obs;

  void toggle() => isDark.value = !isDark.value;
}
