import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../community/controllers/community_controller.dart';
import '../controllers/story_editor_controller.dart';
import '../binding/story_binding.dart';
import '../../../data/models/story_model.dart';

class StoryEditorView extends StatefulWidget {
  const StoryEditorView({super.key});

  @override
  State<StoryEditorView> createState() => _StoryEditorViewState();
}

class _StoryEditorViewState extends State<StoryEditorView> {
  late final StoryEditorController c;

  @override
  void initState() {
    super.initState();
    StoryBinding().dependencies();
    c = Get.find<StoryEditorController>();
    final args = Get.arguments;
    if (args is StoryModel) {
      c.loadStory(args);
    } else {
      c.startNewStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (c.imagePath.value == null && c.backgroundColorHex.value == null) {
            return _EmptyPicker(c: c);
          }
          return Column(
            children: [
              _TopBar(c: c),
              Expanded(child: _EditorCanvas(c: c)),
              _BottomPanel(c: c),
            ],
          );
        }),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final StoryEditorController c;
  const _TopBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.close,
            onTap: () => Get.back(),
          ),
          const SizedBox(width: 12),
          Obx(() => Text(c.isEditing ? 'Edit Story' : 'New Story',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary))),
          const Spacer(),
          Obx(() {
            final selected = c.selectedOverlay.value;
            if (selected == null) {
              if (!c.isEditing) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _confirmDeleteStory(context),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 22),
              );
            }
            return IconButton(
              onPressed: () => c.removeOverlay(selected.id),
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 22),
            );
          }),
          _CircleButton(
            icon: Icons.text_fields,
            onTap: c.addText,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStory(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete story?'),
        content: const Text(
            'This story will be removed from your profile and the community feed.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final ok = await c.deleteStory();
              Get.back();
              if (ok) Get.back(result: true);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _EditorCanvas extends StatelessWidget {
  final StoryEditorController c;
  const _EditorCanvas({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: LayoutBuilder(builder: (context, constraints) {
            final canvasSize =
                Size(constraints.maxWidth, constraints.maxHeight);
            final bg = c.backgroundColorHex.value;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () => c.selectOverlay(null),
                      child: ColoredBox(
                        color: bg != null ? colorFromHex(bg) : Colors.black,
                        child: c.imagePath.value != null
                            ? Image.file(File(c.imagePath.value!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                    ),
                    // Draggable text overlays - Instagram style, move anywhere
                    // on the canvas using fractional positions.
                    Obx(() => Stack(
                          children: c.overlays
                              .map((overlay) => _DraggableText(
                                  overlay: overlay,
                                  canvasSize: canvasSize,
                                  c: c))
                              .toList(),
                        )),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DraggableText extends StatelessWidget {
  final StoryTextOverlay overlay;
  final Size canvasSize;
  final StoryEditorController c;

  const _DraggableText(
      {required this.overlay, required this.canvasSize, required this.c});

  @override
  Widget build(BuildContext context) {
    final left = overlay.position.dx * canvasSize.width;
    final top = overlay.position.dy * canvasSize.height;

    return Positioned(
      left: left - 100,
      top: top - 24,
      child: GestureDetector(
        onTap: () => c.selectOverlay(overlay),
        onPanUpdate: (details) {
          final newDx = (left + details.delta.dx) / canvasSize.width;
          final newDy = (top + details.delta.dy) / canvasSize.height;
          c.updateOverlayPosition(overlay.id, Offset(newDx, newDy));
        },
        onDoubleTap: () => _editText(context),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: c.selectedOverlay.value?.id == overlay.id
                  ? AppColors.primary
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            overlay.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: overlay.color,
              fontSize: overlay.fontSize,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }

  void _editText(BuildContext context) {
    final controller = TextEditingController(text: overlay.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content:
            TextField(controller: controller, autofocus: true, maxLines: 2),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              c.updateOverlayText(
                  overlay.id,
                  controller.text.trim().isEmpty
                      ? overlay.text
                      : controller.text.trim());
              Get.back();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final StoryEditorController c;
  const _BottomPanel({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (c.imagePath.value != null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Background',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _BackgroundSwatches(
                    selectedHex: c.backgroundColorHex.value,
                    onSelect: c.setBackgroundColor,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            );
          }),
          Obx(() {
            final selected = c.selectedOverlay.value;
            if (selected == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Text color',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: storyTextColors.map((color) {
                      final active = selected.color == color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => c.updateOverlayColor(selected.id, color),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: active ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 18),
          Obx(() => Opacity(
                opacity: c.canPost ? 1 : 0.45,
                child: Row(
                  children: [
                    Expanded(child: _ShareButton(c: c)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final StoryEditorController c;
  const _ShareButton({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final shared = c.isShared.value;
      final editing = c.isEditing;
      final label = shared
          ? (editing ? 'Updated' : 'Shared')
          : (editing ? 'Update Story' : 'Share to Story');
      return SizedBox(
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: shared
                    ? [AppColors.accentGreen, AppColors.accentGreen]
                    : [AppColors.primary, AppColors.accentPurple]),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: c.posting.value || !c.canPost
                  ? null
                  : () async {
                      final ok = await c.postStory();
                      if (ok && context.mounted) {
                        // Story appears immediately in the feed's stories row.
                        if (Get.isRegistered<CommunityController>()) {
                          Get.find<CommunityController>().loadStories();
                        }
                        Get.back(result: true);
                      }
                    },
              borderRadius: BorderRadius.circular(26),
              child: Center(
                child: c.posting.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (shared) ...[
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                          ],
                          Text(label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _BackgroundSwatches extends StatelessWidget {
  final String? selectedHex;
  final ValueChanged<String> onSelect;

  const _BackgroundSwatches({
    required this.selectedHex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: storyBackgroundColors.map((color) {
        final hex = colorToHex(color);
        final selected = selectedHex == hex;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelect(hex),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  final StoryEditorController c;
  const _EmptyPicker({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _CircleButton(icon: Icons.close, onTap: () => Get.back()),
          ),
        ),
        const Spacer(),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accentPurple]),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10))
            ],
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('Create a story',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Share a moment with the community',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PickCard(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => c.pickImage(ImageSource.gallery)),
            const SizedBox(width: 16),
            _PickCard(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => c.pickImage(ImageSource.camera)),
          ],
        ),
        const SizedBox(height: 28),
        const Text('or pick a solid background',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        _BackgroundSwatches(
          selectedHex: c.backgroundColorHex.value,
          onSelect: c.setBackgroundColor,
        ),
        const Spacer(),
      ],
    );
  }
}

class _PickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
