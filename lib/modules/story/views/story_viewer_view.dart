import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/network/app_config.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/story_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../../community/controllers/community_controller.dart';

/// Route arguments for the story viewer: stories grouped per user (a "tray"
/// like Instagram/Facebook). The viewer plays through one group, then
/// auto-advances to the next user's group, and only exits after the last
/// group finishes.
class StoryViewerArgs {
  final List<List<StoryModel>> groups;
  final int initialGroupIndex;
  final int initialStoryIndex;

  const StoryViewerArgs({
    required this.groups,
    this.initialGroupIndex = 0,
    this.initialStoryIndex = 0,
  });
}

class StoryViewerView extends StatefulWidget {
  final StoryViewerArgs args;

  const StoryViewerView({super.key, required this.args});

  @override
  State<StoryViewerView> createState() => _StoryViewerViewState();
}

class _StoryViewerViewState extends State<StoryViewerView>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);

  late final AnimationController _progress;
  late int _groupIndex;
  late int _index;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _storyDuration);
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
    if (widget.args.groups.isEmpty) return;
    _groupIndex = widget.args.initialGroupIndex.clamp(0, widget.args.groups.length - 1);
    _index = widget.args.initialStoryIndex.clamp(0, _currentGroupLength - 1);
    _show(_groupIndex, _index);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  int get _currentGroupLength => widget.args.groups.isEmpty ? 0 : widget.args.groups[_groupIndex].length;

  StoryModel get _story => widget.args.groups[_groupIndex][_index];

  bool get _isOwner => _story.author.id == AppConfig.currentUserId;

  void _show(int groupIndex, int storyIndex) {
    setState(() {
      _groupIndex = groupIndex.clamp(0, widget.args.groups.length - 1);
      _index = storyIndex.clamp(0, _currentGroupLength - 1);
      _story.viewed = true;
    });
    _progress
      ..stop()
      ..value = 0
      ..forward();
  }

  void _goNext() {
    if (_index < _currentGroupLength - 1) {
      _show(_groupIndex, _index + 1);
      return;
    }
    if (_groupIndex < widget.args.groups.length - 1) {
      _show(_groupIndex + 1, 0);
      return;
    }
    Get.back();
  }

  void _goPrevious() {
    if (_index > 0) {
      _show(_groupIndex, _index - 1);
      return;
    }
    if (_groupIndex > 0) {
      _show(_groupIndex - 1, widget.args.groups[_groupIndex - 1].length - 1);
      return;
    }
    _show(_groupIndex, _index);
  }

  void _handleTap(TapUpDetails details, Size size) {
    if (details.localPosition.dx < size.width / 3) {
      _goPrevious();
    } else {
      _goNext();
    }
  }

  Future<void> _editStory() async {
    _progress.stop();
    final storyId = _story.id;
    await Get.toNamed('/story/create', arguments: _story);
    final stories = await Get.find<CommunityRepository>().fetchStories();
    final updated = stories.firstWhereOrNull((s) => s.id == storyId);
    if (!mounted) return;
    if (updated == null) {
      _removeCurrentStory();
      return;
    }
    setState(() {
      widget.args.groups[_groupIndex][_index] = updated;
    });
    if (Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().loadStories();
    }
    if (mounted) _progress.forward();
  }

  Future<void> _deleteStory() async {
    _progress.stop();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete story?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      if (mounted) _progress.forward();
      return;
    }

    await Get.find<CommunityRepository>().deleteStory(_story.id);
    if (Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().loadStories();
    }

    _removeCurrentStory();
  }

  void _removeCurrentStory() {
    final group = widget.args.groups[_groupIndex];
    group.removeAt(_index);
    if (group.isEmpty) {
      widget.args.groups.removeAt(_groupIndex);
      if (widget.args.groups.isEmpty) {
        Get.back(result: true);
        return;
      }
      _groupIndex = _groupIndex.clamp(0, widget.args.groups.length - 1);
      _index = 0;
    } else {
      _index = _index.clamp(0, group.length - 1);
    }
    _show(_groupIndex, _index);
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.args.groups;
    if (groups.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final story = _story;
    final bg = story.backgroundColorHex;
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d, size),
          onLongPressStart: (_) => _progress.stop(),
          onLongPressEnd: (_) => _progress.forward(),
          onLongPressCancel: () => _progress.forward(),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: bg != null ? colorFromHex(bg) : Colors.black,
                    child: story.imagePath.isNotEmpty
                        ? Image.file(File(story.imagePath), fit: BoxFit.cover)
                        : null,
                  ),
                ),
                ...story.textOverlays.map((o) => Positioned(
                      left: o.position.dx * size.width - 100,
                      top: o.position.dy * size.height - 20,
                      child: SizedBox(
                        width: 200,
                        child: Text(
                          o.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: o.color,
                            fontSize: o.fontSize,
                            fontWeight: FontWeight.w700,
                            shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                          ),
                        ),
                      ),
                    )),
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      _ProgressBars(count: _currentGroupLength, index: _index, progress: _progress),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          UserAvatar(user: story.author, size: 34, border: Border.all(color: Colors.white, width: 1.5)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${story.author.name} • ${timeago.format(story.createdAt, locale: 'en_short')}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (_isOwner)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz, color: Colors.white),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              onOpened: () => _progress.stop(),
                              onCanceled: () => _progress.forward(),
                              onSelected: (value) {
                                if (value == 'edit') _editStory();
                                if (value == 'delete') _deleteStory();
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 10),
                                    Text('Edit Story'),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ]),
                                ),
                              ],
                            ),
                          IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  final int count;
  final int index;
  final Animation<double> progress;

  const _ProgressBars({required this.count, required this.index, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return AnimatedBuilder(
          animation: progress,
          builder: (_, __) {
            final fill = i < index ? 1.0 : (i == index ? progress.value : 0.0);
            return Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fill,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
