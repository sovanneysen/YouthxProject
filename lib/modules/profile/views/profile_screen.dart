import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../data/models/post_model.dart';
import '../../../routes/app_routes.dart';
import '../../community/controllers/community_controller.dart';
import '../../community/views/comments_view.dart';
import '../../community/views/create_post_view.dart';
import '../../community/views/widgets/post_card.dart';
import '../controllers/profile_data_controller.dart';
import '../profile_model.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

/// Profile tab.
///
/// The header identity, the statistics, and the "My posts" list are all read
/// from [ProfileDataController], which in turn reads the existing auth,
/// community, and growth controllers. Nothing on this screen is hardcoded, and
/// no repository or API is called from a widget.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryPurple = Color(0xFF5B5FEF);
  static const Color gradientBlue = Color(0xFF3B82F6);
  static const Color gradientPurple = Color(0xFF7C5CF0);

  bool _menuOpen = false;
  PostTab _selectedTab = PostTab.myPosts;

  final ProfileDataController _profile = Get.find<ProfileDataController>();
  final ThemeController _theme = Get.find<ThemeController>();

  /// Only resolved when the Community tab has been built at least once.
  CommunityController? get _community => Get.isRegistered<CommunityController>()
      ? Get.find<CommunityController>()
      : null;

  /// Posts for the selected tab. My posts are the account's own; saved and
  /// shared are the session-local in-memory state the community feed already
  /// tracks, because the backend has no persistence for either.
  List<PostModel> get _activePosts {
    switch (_selectedTab) {
      case PostTab.myPosts:
        return _profile.myPosts;
      case PostTab.shared:
        return _profile.sharedPosts;
      case PostTab.saved:
        return _profile.savedPosts;
    }
  }

  /// True only while the community feed has never completed a load, so an
  /// empty list is not mistaken for "no posts".
  bool get _isLoading =>
      _activePosts.isEmpty && _profile.communityLoading;

  List<MenuItemData> get _menuItems => [
        MenuItemData(
          icon: Icons.edit,
          iconColor: primaryPurple,
          iconBg: const Color(0xFFE6E9FE),
          title: 'Edit profile',
        ),
        MenuItemData(
          icon: Icons.dark_mode,
          iconColor: const Color(0xFF9B59B6),
          iconBg: const Color(0xFFF4E8FE),
          title: 'Dark mode',
          isToggle: true,
        ),
        MenuItemData(
          icon: Icons.notifications,
          iconColor: gradientBlue,
          iconBg: const Color(0xFFE3ECFE),
          title: 'Notifications',
        ),
        MenuItemData(
          icon: Icons.shield,
          iconColor: const Color(0xFF2E9E5B),
          iconBg: const Color(0xFFE3F2E1),
          title: 'Privacy',
        ),
        MenuItemData(
          icon: Icons.settings,
          iconColor: const Color(0xFFD9A441),
          iconBg: const Color(0xFFFFF1DE),
          title: 'Settings',
        ),
        MenuItemData(
          icon: Icons.help_outline,
          iconColor: Colors.grey.shade700,
          iconBg: const Color(0xFFEDEDED),
          title: 'Help and support',
        ),
        MenuItemData(
          icon: Icons.logout,
          iconColor: Colors.redAccent,
          iconBg: const Color(0xFFFDEAEA),
          title: 'Log out',
          isDanger: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? context.bg : const Color(0xFFF4F5FB),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildAvatar(),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatsRow()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildIdentity(),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildActionButtons(),
                        ),
                        const SizedBox(height: 20),
                        _buildTabs(),
                        const SizedBox(height: 12),
                        // Wrapped in Obx so the list reacts to community
                        // and growth updates, and so the loading spinner
                        // is replaced once the feed resolves.
                        Obx(() => _buildPostsList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Dim/close menu when tapping outside the panel
            if (_menuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _menuOpen = false),
                  child: Container(color: Colors.transparent),
                ),
              ),
            if (_menuOpen)
              Positioned(
                top: 60,
                right: 20,
                child: _buildMenuPanel(),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            final name = _profile.displayName;
            return Text(
              name.isEmpty ? 'YOUTHX' : name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
          GestureDetector(
            onTap: () => setState(() => _menuOpen = !_menuOpen),
            child: const Icon(Icons.menu, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ---------------- ACCOUNT / SETTINGS DROPDOWN ----------------

  Widget _buildMenuPanel() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in _menuItems) ...[
              if (item.isDanger)
                Divider(
                    height: 1,
                    color: context.borderColor,
                    indent: 12,
                    endIndent: 12),
              _buildMenuRow(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(MenuItemData item) {
    return InkWell(
      onTap: () {
        if (item.isToggle) {
          _theme.toggle();
          return;
        }
        setState(() => _menuOpen = false);

        switch (item.title) {
          case 'Edit profile':
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            break;
          case 'Notifications':
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            break;
          case 'Privacy':
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            break;
          case 'Settings':
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            break;
          case 'Help and support':
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            break;
          case 'Log out':
            _confirmLogOut();
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: item.iconBg, shape: BoxShape.circle),
              child: Icon(item.icon, size: 15, color: item.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: item.isDanger
                      ? Colors.redAccent
                      : context.textPrimaryColor,
                ),
              ),
            ),
            if (item.isToggle)
              Transform.scale(
                scale: 0.75,
                child: Obx(
                  () => Switch(
                    value: _theme.isDark.value,
                    activeColor: primaryPurple,
                    onChanged: (_) => _theme.toggle(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmLogOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Get.find<AuthController>().logout();
              Get.offAllNamed(AppRoutes.auth);
            },
            child: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ---------------- AVATAR ----------------

  Widget _buildAvatar() {
    return Obx(() {
      final imagePath = _profile.imagePath;
      final initials = _profile.initials;

      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.cardBg,
          gradient: imagePath == null ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientBlue, primaryPurple],
          ) : null,
          image: imagePath != null ? DecorationImage(
            image: FileImage(File(imagePath)),
            fit: BoxFit.cover,
          ) : null,
        ),
        child: imagePath == null ? Center(
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ) : null,
      );
    });
  }

  // ---------------- IDENTITY ----------------

  Widget _buildIdentity() {
    return Obx(() {
      final name = _profile.displayName;
      final email = _profile.email;
      final bio = _profile.bio;
      final location = _profile.location;
      final memberSince = _profile.memberSince;
      final hasLocalName = _profile.hasLocalName;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'YOUTHX member' : name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
            ),
          ],
          if (location.isNotEmpty || memberSince != null) ...[
            const SizedBox(height: 6),
            _buildMetaRow(location: location, memberSince: memberSince),
          ],
          if (hasLocalName) ...[
            const SizedBox(height: 6),
            _buildLocalNameNote(),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bio,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: context.textPrimaryColor),
            ),
          ],
        ],
      );
    });
  }

  /// Location and join date, each shown only when the session provides it.
  Widget _buildMetaRow({
    required String location,
    required DateTime? memberSince,
  }) {
    final parts = <String>[];
    if (location.isNotEmpty) parts.add(location);
    if (memberSince != null) {
      parts.add('Member since ${DateFormat.yMMM().format(memberSince)}');
    }
    return Text(
      parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
    );
  }

  /// Marks a name that lives on this device only, so it is never mistaken for
  /// the account name stored by the backend.
  Widget _buildLocalNameNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smartphone, size: 12, color: primaryPurple),
          const SizedBox(width: 5),
          const Text(
            'Display name saved on this device',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STATS ----------------

  Widget _buildStatsRow() {
    return Obx(() {
      final growthLoading = _profile.growthLoading;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('${_profile.postCount}', 'Posts'),
          _statItem(growthLoading ? '—' : '${_profile.goalCount}', 'Goals'),
          _statItem(growthLoading ? '—' : '${_profile.streakDays}', 'Streak'),
        ],
      );
    });
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor)),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(fontSize: 13, color: context.textSecondaryColor)),
      ],
    );
  }

  // ---------------- TABS ----------------

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          _tabItem('My posts', PostTab.myPosts),
          _tabItem('Shared', PostTab.shared),
          _tabItem('Saved', PostTab.saved),
        ],
      ),
    );
  }

  Widget _tabItem(String label, PostTab tab) {
    final bool selected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? primaryPurple : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? primaryPurple : context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- POSTS ----------------

  Widget _buildPostsList() {
    // Always touch an observable so the enclosing Obx has a dependency even
    // when neither the community nor the growth controller is registered.
    _profile.loadingLocalProfile.value;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final posts = _activePosts;
    if (posts.isEmpty) return _buildEmptyState();

    return Column(
      children: posts.map((post) => _buildPostCard(post)).toList(),
    );
  }

  /// Explains why a tab is empty instead of inventing posts. Saved and shared
  /// also state that they are not persisted on the server.
  Widget _buildEmptyState() {
    final (icon, title, message) = switch (_selectedTab) {
      PostTab.myPosts => (
          Icons.edit_note,
          'No posts yet',
          'Posts you publish in Community will show up here.',
        ),
      PostTab.shared => (
          Icons.send,
          'No shared posts',
          'Posts you share in Community appear here for this session only.',
        ),
      PostTab.saved => (
          Icons.bookmark_border,
          'No saved posts',
          'Posts you save in Community appear here for this session only.',
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(icon, size: 34, color: context.textSecondaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a real post through the shared community card so Profile shows
  /// the same content, media, and actions as the feed.
  Widget _buildPostCard(PostModel post) {
    final community = _community;
    final isOwner = post.isOwner(_profile.userId);

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(12),
      child: PostCard(
        post: post,
        isOwner: isOwner,
        onLike: community == null ? () {} : () => community.toggleLike(post),
        onComment: community == null ? () {} : () => _openComments(post),
        onSave: community == null ? () {} : () => community.toggleSave(post),
        onShare: community == null ? () {} : () => community.toggleShare(post),
        onEdit: () => Get.to(() => CreatePostView(editingPost: post)),
        onDelete: () => _confirmDeletePost(post),
        onAuthorTap: () {},
      ),
    );
  }

  void _openComments(PostModel post) {
    Get.bottomSheet(
      CommentsView(post: post),
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  void _confirmDeletePost(PostModel post) {
    final community = _community;
    if (community == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              community.deletePost(post);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ---------------- SHARED HELPERS ----------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
