
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../profile_model.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
 
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

  final AuthController _auth = Get.find<AuthController>();
  final ThemeController _theme = Get.find<ThemeController>();

  String _initials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '…';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '…';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
 
  // TODO: replace with data fetched from your backend / database.
  final List<Post> _myPosts = [
    Post(
      id: 'p1',
      authorName: 'Alex Johnson',
      authorInitials: 'AJ',
      timeAgo: '2 days ago',
      caption: 'Finally hit my savings goal for the semester 🎓',
      likeCount: 24,
    ),
    Post(
      id: 'p2',
      authorName: 'Alex Johnson',
      authorInitials: 'AJ',
      timeAgo: '5 days ago',
      caption: 'Study group at the library tonight, who\'s in?',
      likeCount: 12,
    ),
  ];
 
  final List<Post> _sharedPosts = [
    Post(
      id: 's1',
      authorName: 'Maria Chen',
      authorInitials: 'MC',
      timeAgo: '1 day ago',
      caption: 'Great tips on budgeting for students 💰',
      likeCount: 41,
    ),
  ];
 
  final List<Post> _savedPosts = [
    Post(
      id: 'sv1',
      authorName: 'Sam Patel',
      authorInitials: 'SP',
      timeAgo: '3 days ago',
      caption: 'My internship search checklist, saving this!',
      likeCount: 88,
      isSaved: true,
    ),
  ];
 
  List<Post> get _activePosts {
    switch (_selectedTab) {
      case PostTab.myPosts:
        return _myPosts;
      case PostTab.shared:
        return _sharedPosts;
      case PostTab.saved:
        return _savedPosts;
    }
  }
 
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
                      children: [
                        _buildHeader(),
                        Transform.translate(
                          offset: const Offset(0, -50),
                          child: Column(
                            children: [
                              _buildAvatar(),
                              const SizedBox(height: 14),
                              Obx(
                                () => Text(
                                  _auth.currentUser.value?.fullName ?? '…',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Obx(
                                () => Text(
                                  _auth.currentUser.value?.email ?? '',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: context.textSecondaryColor),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildStatsCard(),
                              const SizedBox(height: 16),
                              _buildTabs(),
                              const SizedBox(height: 12),
                              _buildPostsList(),
                            ],
                          ),
                        ),
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
 
  Widget _buildHeader() {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientBlue, gradientPurple],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -30, left: -20, child: _blurCircle(90)),
          Positioned(bottom: -20, right: 30, child: _blurCircle(60)),
          Positioned(
            top: 14,
            right: 14,
            child: GestureDetector(
              onTap: () => setState(() => _menuOpen = !_menuOpen),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _blurCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
      ),
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            break;
          case 'Notifications':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            break;
          case 'Privacy':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            break;
          case 'Settings':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            break;
          case 'Help and support':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
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
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientBlue, primaryPurple],
          ),
        ),
        child: Center(
          child: Obx(
            () => Text(
              _initials(_auth.currentUser.value?.fullName),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
 
  // ---------------- STATS ----------------
 
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('24', 'Posts'),
          _statDivider(),
          _statItem('128', 'Followers', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowersScreen()));
          }),
          _statDivider(),
          _statItem('36', 'Following', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowingScreen()));
          }),
        ],
      ),
    );
  }
 
Widget _statDivider() =>
      Container(width: 1, height: 36, color: context.borderColor);

  Widget _statItem(String value, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: context.textSecondaryColor)),
        ],
      ),
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
    if (_activePosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text('No posts yet',
            style: TextStyle(color: context.textSecondaryColor)),
      );
    }
    return Column(
      children: _activePosts.map((post) => _buildPostCard(post)).toList(),
    );
  }
 
  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE6E9FE),
                child: Text(
                  post.authorInitials,
                  style: const TextStyle(
                      fontSize: 11, color: primaryPurple, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(post.timeAgo,
                      style: TextStyle(
                          fontSize: 11, color: context.textSecondaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.caption,
              style: TextStyle(fontSize: 13, color: context.textPrimaryColor)),
          const SizedBox(height: 10),
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.bg,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 8),
          Row(
            children: [
              _postAction(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likeCount}',
                color: post.isLiked ? Colors.redAccent : context.textSecondaryColor,
                onTap: () => setState(() {
                  post.isLiked = !post.isLiked;
                  // TODO: persist like to database
                }),
              ),
              const SizedBox(width: 18),
              _postAction(
                icon: Icons.share_outlined,
                label: 'Share',
                color: context.textSecondaryColor,
                onTap: () {
                  // TODO: open share sheet / write to post_shares table
                },
              ),
              const Spacer(),
              _postAction(
                icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                label: 'Save',
                color: post.isSaved ? primaryPurple : context.textSecondaryColor,
                onTap: () => setState(() {
                  post.isSaved = !post.isSaved;
                  // TODO: persist save to post_saves table
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _postAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
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
 