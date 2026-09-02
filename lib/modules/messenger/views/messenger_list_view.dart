import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/message_model.dart';
import '../binding/messenger_binding.dart';
import '../controllers/messenger_controller.dart';
import 'chat_thread_view.dart';

class MessengerListView extends StatelessWidget {
  const MessengerListView({super.key});

  @override
  Widget build(BuildContext context) {
    MessengerBinding().dependencies();
    final controller = Get.find<MessengerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: controller.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final threads = controller.filtered;
                if (threads.isEmpty) {
                  return const Center(child: Text('No conversations', style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.separated(
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 84, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final t = threads[i];
                    final last = t.lastMessage;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      // The whole row (including the avatar) opens the chat —
                      // search results should land in the messenger thread,
                      // not the profile page.
                      leading: UserAvatar(
                        user: t.peer,
                        size: 52,
                        onTap: () => Get.to(() => ChatThreadView(thread: t)),
                      ),
                      title: Text(t.peer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                        _preview(last),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (last != null)
                            Text(timeago.format(last.createdAt),
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          if (t.unreadCount > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: Text('${t.unreadCount}',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => Get.to(() => ChatThreadView(thread: t)),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _preview(MessageModel? m) {
    if (m == null) return '';
    switch (m.type) {
      case MessageType.text:
        return m.text ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.voice:
        return '🎙️ Voice message';
    }
  }
}
