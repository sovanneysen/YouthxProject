import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../controllers/chat_controller.dart';
import 'widgets/voice_message_bubble.dart';

class ChatThreadView extends StatefulWidget {
  final ThreadModel thread;
  const ChatThreadView({super.key, required this.thread});

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  late final String tag;
  late final ChatController c;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    tag = 'chat_${widget.thread.id}';
    c = Get.put(ChatController(repository: Get.find<ChatRepository>(), thread: widget.thread), tag: tag);
    ever(c.messages, (_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    Get.delete<ChatController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Get.toNamed('/profile', arguments: widget.thread.peer),
          child: Row(
            children: [
              UserAvatar(user: widget.thread.peer, size: 36),
              const SizedBox(width: 10),
              Text(widget.thread.peer.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (c.loading.value) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: c.messages.length,
                  itemBuilder: (_, i) => _MessageBubble(message: c.messages[i], isMe: c.messages[i].sender.id == c.me.id),
                );
              }),
            ),
            Obx(() {
              if (c.pendingImagePath.value != null) return _ImageComposer(c: c);
              return c.isRecording.value ? _RecordingBar(c: c) : _InputBar(c: c);
            }),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppColors.primary : context.cardBg;
    final fg = isMe ? Colors.white : context.textPrimaryColor;

    Widget content;
    switch (message.type) {
      case MessageType.text:
        content = Text(message.text ?? '', style: TextStyle(color: fg, fontSize: 14, height: 1.4));
        break;
      case MessageType.image:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(message.mediaPath!), width: 200, height: 200, fit: BoxFit.cover),
            ),
            if (message.text != null && message.text!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(message.text!, style: TextStyle(color: fg, fontSize: 14, height: 1.4)),
              ),
            ],
          ],
        );
        break;
      case MessageType.voice:
        content = VoiceMessageBubble(path: message.mediaPath!, isMe: isMe, duration: message.voiceDuration);
        break;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: message.type == MessageType.image ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: isMe ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: content,
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final ChatController c;
  const _InputBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: c.pickImage, icon: Icon(Icons.image_outlined, color: context.textSecondaryColor)),
          Expanded(
            child: TextField(
              controller: c.inputController,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(color: context.textSecondaryColor),
                filled: true,
                fillColor: context.cardBgAlt,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => c.sendText(),
            ),
          ),
          const SizedBox(width: 6),
          Obx(() => IconButton(
                onPressed: c.hasText.value ? c.sendText : c.startRecording,
                icon: Icon(c.hasText.value ? Icons.send : Icons.mic_none, color: AppColors.primary),
              )),
        ],
      ),
    );
  }
}

class _ImageComposer extends StatelessWidget {
  final ChatController c;
  const _ImageComposer({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Obx(() {
        final path = c.pendingImagePath.value;
        if (path == null) return const SizedBox.shrink();
        return Row(
          children: [
            // Tap the photo again to cancel the send (Telegram-style).
            GestureDetector(
              onTap: c.cancelPendingImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(path), width: 48, height: 48, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: c.captionController,
                style: TextStyle(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(color: context.textSecondaryColor),
                  filled: true,
                  fillColor: context.cardBgAlt,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => c.sendPendingImage(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: c.sendPendingImage,
              icon: const Icon(Icons.send, color: AppColors.primary),
            ),
          ],
        );
      }),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final ChatController c;
  const _RecordingBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: c.cancelRecording, icon: const Icon(Icons.close, color: AppColors.danger)),
          const Icon(Icons.fiber_manual_record, color: AppColors.danger, size: 14),
          const SizedBox(width: 8),
          Obx(() => Text(_format(c.recordSeconds.value), style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor))),
          const Spacer(),
          Text('Recording voice message...', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
          const Spacer(),
          IconButton(
            onPressed: c.stopAndSendRecording,
            icon: const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
