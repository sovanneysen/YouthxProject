import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/selectable_chip.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';
import '../../messenger/views/messenger_list_view.dart';
import '../../story/views/story_viewer_view.dart';
import '../controllers/community_controller.dart';
import 'create_post_view.dart';
import 'comments_view.dart';
import 'widgets/post_card.dart';
import 'widgets/stories_row.dart';

class CommunityView extends GetView<CommunityController> {
  const CommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadFeed,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _SearchBar()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Obx(() {
                    final stories = controller.stories.toList();
                    return StoriesRow(
                      stories: stories,
                      onAddStory: () => Get.toNamed('/story/create'),
                      onOpenStory: (s) {
                        // Build the full story tray (one group per user, in
                        // feed order) so the viewer auto-advances to the next
                        // person's stories instead of exiting early.
                        final active = stories.where((x) => !x.isExpired).toList();
                        final groups = <String, List<StoryModel>>{};
                        for (final st in active) {
                          groups.putIfAbsent(st.author.id, () => []).add(st);
                        }
                        final groupList = groups.values.toList();
                        final gi = groupList.indexWhere((g) => g.first.author.id == s.author.id);
                        Get.toNamed(
                          '/story/view',
                          arguments: StoryViewerArgs(
                            groups: groupList,
                            initialGroupIndex: gi < 0 ? 0 : gi,
                          ),
                        )?.then((_) => controller.loadStories());
                      },
                    );
                  }),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(child: _FilterChips()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: Obx(() {
                  if (controller.isSearching) {
                    return _peopleResults(controller);
                  }
                  if (controller.loading.value) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  final feedError = controller.feedError.value;
                  if (feedError != null) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off,
                                  color: AppColors.textMuted, size: 32),
                              const SizedBox(height: 10),
                              Text(
                                feedError,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: controller.loadFeed,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final posts = controller.filteredPosts;
                  if (posts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text('No posts yet',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final index = i ~/ 2;
                        if (i.isOdd) return const SizedBox(height: 16);
                        return _PostCardBound(post: posts[index]);
                      },
                      childCount: posts.length * 2 - 1,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.to(() => const CreatePostView()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PostCardBound extends GetView<CommunityController> {
  final PostModel post;
  const _PostCardBound({required this.post});

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      isOwner: post.isOwner(controller.currentUserId),
      onLike: () => controller.toggleLike(post),
      onComment: () => Get.bottomSheet(
        CommentsView(post: post),
        isScrollControlled: true,
        backgroundColor: context.cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      onSave: () async {
        await controller.toggleSave(post);
        if (!context.mounted) return;
        _showWhiteSnackBar(
          context,
          post.savedByMe ? 'Saved' : 'Removed from saved',
        );
      },
      onShare: () async {
        await controller.toggleShare(post);
        if (!context.mounted) return;
        _showWhiteSnackBar(
          context,
          post.sharedByMe ? 'Shared' : 'Removed from shared',
        );
      },
      onEdit: () => Get.to(() => CreatePostView(editingPost: post)),
      onDelete: () => _confirmDelete(context, post),
      onAuthorTap: () => Get.toNamed('/profile', arguments: post.author),
    );
  }

  void _confirmDelete(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deletePost(post);
              Get.back();
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

SliverList _peopleResults(CommunityController controller) {
  final people = controller.peopleResults;
  if (people.isEmpty) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((_, __) {
        return const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(
            child: Text('No people found', style: TextStyle(color: AppColors.textSecondary)),
          ),
        );
      }, childCount: 1),
    );
  }
  return SliverList(
    delegate: SliverChildBuilderDelegate((_, i) {
      final user = people[i];
      return _PersonRow(
        user: user,
        onTap: () {
          // Open the profile and clear the search so the box is ready for
          // the next query when the user comes back.
          Get.toNamed('/profile', arguments: user);
          controller.clearSearch();
        },
      );
    }, childCount: people.length),
  );
}

class _PersonRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _PersonRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(user: user, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Community member',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showWhiteSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Text(message,
                style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
}

class _Header extends GetView<CommunityController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('2,840 members active today',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _IconButton(
            icon: Icons.chat_bubble_outline,
            badge: '1',
            onTap: () => Get.to(() => const MessengerListView()),
          ),
          const SizedBox(width: 10),
          _IconButton(
            icon: Icons.add,
            filled: true,
            onTap: () => Get.to(() => const CreatePostView()),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final bool filled;
  final VoidCallback onTap;

  const _IconButton(
      {required this.icon,
      this.badge,
      this.filled = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : context.cardBgAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon,
                color: filled ? Colors.white : AppColors.textPrimary, size: 22),
            if (badge != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(badge!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends GetView<CommunityController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.setSearch,
        decoration: InputDecoration(
          hintText: 'Search people...',
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          suffixIcon: Obx(() => controller.isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  onPressed: controller.clearSearch,
                )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _FilterChips extends GetView<CommunityController> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Obx(() {
        final activeFilter = controller.activeFilter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = controller.filters[i];
            return SelectableChip(
              label: f,
              selected: activeFilter == f,
              onTap: () => controller.setFilter(f),
            );
          },
        );
      }),
    );
  }
}
