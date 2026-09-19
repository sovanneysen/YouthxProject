import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

// ==================================================================
// 5. HOME SCREEN (scrollable dashboard + bottom nav)
// ==================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _auth = Get.find<AuthController>();

  String _initials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '…';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '…';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  // Habit checklist lives here so checkboxes can update it with setState.
  final List<_Habit> habits = [
    _Habit(
      icon: Icons.self_improvement,
      label: 'Morning meditation',
      done: true,
    ),
    _Habit(
      icon: Icons.water_drop,
      label: 'Drink 8 glasses of water',
      done: true,
    ),
    _Habit(icon: Icons.menu_book, label: 'Read for 30 minutes', done: false),
  ];

  int get doneCount => habits.where((h) => h.done).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      // SingleChildScrollView is what makes the whole page scroll —
      // exactly like the tall screenshot you showed me.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildStatCards(),
              const SizedBox(height: 16),
              _buildWeeklyProgress(),
              const SizedBox(height: 16),
              _buildTodaysHabits(),
              const SizedBox(height: 16),
              _buildCommunityHighlights(),
              const SizedBox(height: 16), // breathing room above nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Obx(
              () => CircleAvatar(
                backgroundColor: const Color(0xFF4A6CF7),
                child: Text(
                  _initials(_auth.currentUser.value?.fullName),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning 👋',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _auth.currentUser.value?.fullName ?? '…',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Bell icon — InkWell so it has a native ripple, navigates to Notifications
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Get.toNamed(AppRoutes.notifications),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, size: 22),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(emoji: '🔥', value: '7', label: 'Day Streak'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '🎯',
            value: '${doneCount + 2}',
            label: 'Goals Active',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(emoji: '💰', value: '\$1.2k', label: 'Balance'),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress() {
    const totalTasks = 25;
    final tasksDone = 17; // static for now — wire to real data later
    final progress = tasksDone / totalTasks;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6CF7), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEEKLY PROGRESS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep going! You\'re 68% there 🚀',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$tasksDone of $totalTasks tasks done',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysHabits() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Habits",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$doneCount/${habits.length} done',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Build one row per habit, each with its own working checkbox
          ...habits.map((habit) {
            return Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: habit.done,
                activeColor: const Color(0xFF10B981),
                onChanged: (checked) {
                  setState(() => habit.done = checked ?? false);
                },
                title: Row(
                  children: [
                    Icon(habit.icon, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      habit.label,
                      style: TextStyle(
                        decoration: habit.done
                            ? TextDecoration.lineThrough
                            : null,
                        color: habit.done ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton(onPressed: () {}, child: const Text('View all habits →')),
        ],
      ),
    );
  }

  Widget _buildCommunityHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Community Highlights',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('See All')),
          ],
        ),
        _CommunityPost(
          initials: 'AJ',
          name: 'Alex Johnson',
          time: '2m ago',
          text:
              'Just hit my 7-day reading streak! Consistency truly is everything. What goals are...',
          tags: const ['Goals', 'Habits'],
          avatarColor: const Color(0xFF4A6CF7),
        ),
        const SizedBox(height: 10),
        _CommunityPost(
          initials: 'PS',
          name: 'Priya Sharma',
          time: '18m ago',
          text:
              'Saved my first \$500 this month by auditing my subscriptions. Cut 6 unused ones. Sma...',
          tags: const ['Finance', 'Tips'],
          avatarColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}

class _Habit {
  final IconData icon;
  final String label;
  bool done;
  _Habit({required this.icon, required this.label, required this.done});
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _CommunityPost extends StatelessWidget {
  final String initials;
  final String name;
  final String time;
  final String text;
  final List<String> tags;
  final Color avatarColor;

  const _CommunityPost({
    required this.initials,
    required this.name,
    required this.time,
    required this.text,
    required this.tags,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: tags.map((tag) {
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFF4A6CF7),
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
