import 'package:get/get.dart';

import '../../../data/repositories/chat_repository.dart';
import '../controllers/messenger_controller.dart';

class MessengerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatRepository>(() => MockChatRepository(), fenix: true);
    Get.lazyPut<MessengerController>(() => MessengerController(repository: Get.find<ChatRepository>()));
  }
}
