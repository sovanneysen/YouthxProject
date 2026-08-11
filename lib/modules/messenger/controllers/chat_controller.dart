import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/socket_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatController extends GetxController {
  final ChatRepository repository;
  final ThreadModel thread;

  ChatController({required this.repository, required this.thread});

  final UserModel me = UserModel(id: AppConfig.currentUserId, name: 'You');
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool loading = true.obs;
  final RxBool isRecording = false.obs;
  final RxInt recordSeconds = 0.obs;
  final RxBool hasText = false.obs;
  final TextEditingController inputController = TextEditingController();

  /// Telegram-style flow: picking a photo only stages it for review. The user
  /// can add a caption and tap send, or tap the photo again to cancel.
  final RxnString pendingImagePath = RxnString();
  final TextEditingController captionController = TextEditingController();
  final RxBool hasCaption = false.obs;

  final _recorder = AudioRecorder();
  StreamSubscription<MessageModel>? _sub;
  Timer? _recordTimer;
  String? _recordingPath;

  @override
  void onInit() {
    super.onInit();
    RealtimeSocketService.instance.connect();
    inputController.addListener(() => hasText.value = inputController.text.trim().isNotEmpty);
    captionController.addListener(() => hasCaption.value = captionController.text.trim().isNotEmpty);
    _load();
    _sub = repository.watchThread(thread.id).listen((msg) {
      if (messages.any((m) => m.id == msg.id)) return;
      messages.add(msg);
    });
  }

  Future<void> _load() async {
    loading.value = true;
    messages.assignAll(await repository.fetchMessages(thread.id));
    loading.value = false;
  }

  Future<void> sendText() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    inputController.clear();
    final msg = MessageModel(
      id: const Uuid().v4(),
      threadId: thread.id,
      sender: me,
      type: MessageType.text,
      text: text,
      createdAt: DateTime.now(),
    );
    await repository.sendMessage(msg);
  }

  /// Pick an image and stage it for review instead of sending immediately.
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    pendingImagePath.value = file.path;
    captionController.clear();
  }

  /// Tapping the staged photo cancels the send (Telegram-style).
  void cancelPendingImage() {
    pendingImagePath.value = null;
    captionController.clear();
  }

  /// Send the staged photo, attaching the caption when one was typed.
  Future<void> sendPendingImage() async {
    final path = pendingImagePath.value;
    if (path == null) return;
    final caption = captionController.text.trim();
    final msg = MessageModel(
      id: const Uuid().v4(),
      threadId: thread.id,
      sender: me,
      type: MessageType.image,
      text: caption.isEmpty ? null : caption,
      mediaPath: path,
      createdAt: DateTime.now(),
    );
    pendingImagePath.value = null;
    captionController.clear();
    await repository.sendMessage(msg);
  }

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: _recordingPath!);
    isRecording.value = true;
    recordSeconds.value = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) => recordSeconds.value++);
  }

  Future<void> cancelRecording() async {
    _recordTimer?.cancel();
    isRecording.value = false;
    await _recorder.stop();
    _recordingPath = null;
  }

  Future<void> stopAndSendRecording() async {
    _recordTimer?.cancel();
    isRecording.value = false;
    final path = await _recorder.stop();
    final finalPath = path ?? _recordingPath;
    if (finalPath == null) return;

    final msg = MessageModel(
      id: const Uuid().v4(),
      threadId: thread.id,
      sender: me,
      type: MessageType.voice,
      mediaPath: finalPath,
      voiceDuration: Duration(seconds: recordSeconds.value),
      createdAt: DateTime.now(),
    );
    await repository.sendMessage(msg);
  }

  @override
  void onClose() {
    _sub?.cancel();
    _recordTimer?.cancel();
    _recorder.dispose();
    inputController.dispose();
    captionController.dispose();
    super.onClose();
  }
}
