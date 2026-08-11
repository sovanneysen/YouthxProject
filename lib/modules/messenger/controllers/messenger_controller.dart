import 'package:get/get.dart';

import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';

class MessengerController extends GetxController {
  final ChatRepository repository;
  MessengerController({required this.repository});

  final RxList<ThreadModel> threads = <ThreadModel>[].obs;
  final RxBool loading = true.obs;
  final RxString query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    threads.assignAll(await repository.fetchThreads());
    loading.value = false;
  }

  List<ThreadModel> get filtered {
    if (query.value.isEmpty) return threads;
    return threads.where((t) => t.peer.name.toLowerCase().contains(query.value.toLowerCase())).toList();
  }

  void setQuery(String q) => query.value = q;
}
