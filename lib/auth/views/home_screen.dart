import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_user_model.dart';
import '../../data/models/post_model.dart';
import '../../modules/community/controllers/community_controller.dart';
import '../../modules/finance/controllers/finance_controller.dart';
import '../../modules/finance/models/transaction_model.dart';
import '../../modules/finance/views/transaction_detail_page.dart';
import '../../modules/growth_center/controllers/growth_controller.dart';
import '../../modules/growth_center/models/goal_model.dart';
import '../../modules/growth_center/models/habit_model.dart';
import '../../modules/growth_center/models/task_model.dart';
import '../../modules/profile/controllers/profile_data_controller.dart';
import '../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

// ==================================================================
// Shared formatters
// ==================================================================

// These live at library level because the small row widgets further down are
// top-level classes, not part of the screen State. Formatting matches the
// Finance tab: `NumberFormat('#,##0.00')` with the currency symbol added by
// hand, which is the convention already used by `finance_home_page.dart`.
final NumberFormat _moneyFormat = NumberFormat('#,##0.00');
final DateFormat _dayMonth = DateFormat('d MMM');

/// Signed money string, e.g. `-12.50` -> `-$12.50`.
String _money(double amount) {
  final formatted = _moneyFormat.format(amount.abs());
  return amount < 0 ? '-\$$formatted' : '\$$formatted';
}

// ==================================================================
// HOME SCREEN — personalised dashboard
// ==================================================================

/// Every value on this screen is read from the controllers that already own
/// the data ([AuthController] for the session, [ProfileDataController] for the
/// derived personal metrics and the Batch 2C local name,
/// [GrowthController] for goals/habits/to-dos, [FinanceController] for money
/// and [CommunityController] for posts). No repository or API is called from a
/// widget and no number is invented: each section falls back to a loading
/// dash, a real `0`, or an honest empty state.
class HomeScreen extends StatefulWidget {
  /// Switch the surrounding [AppShell] to the Growth tab, Habits sub-tab.
  final VoidCallback? onViewAllHabits;

  /// Switch the surrounding [AppShell] to the Community tab.
  final VoidCallback? onSeeAllCommunity;

  /// Switch the surrounding [AppShell] to the Profile tab.
  final VoidCallback? onAvatarTap;

  const HomeScreen({
    super.key,
    this.onViewAllHabits,
    this.onSeeAllCommunity,
    this.onAvatarTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _auth = Get.find<AuthController>();

  /// Optional module controllers. Each is resolved defensively so a module
  /// whose binding has not run degrades to a placeholder instead of taking the
  /// whole screen down.
  ProfileDataController? get _profile =>
      Get.isRegistered<ProfileDataController>()
          ? Get.find<ProfileDataController>()
          : null;

  CommunityController? get _community => Get.isRegistered<CommunityController>()
      ? Get.find<CommunityController>()
      : null;

  GrowthController? get _growth =>
      Get.isRegistered<GrowthController>() ? Get.find<GrowthController>() : null;

  FinanceController? get _finance => Get.isRegistered<FinanceController>()
      ? Get.find<FinanceController>()
      : null;

  /// Session observable read by every [Obx] below.
  ///
  /// The module controllers above are optional, so a section can end up with
  /// no observable of its own to watch. Reading the session first guarantees
  /// each [Obx] has at least one reactive dependency in that case.
  AuthUserModel? get _sessionTick => _auth.currentUser.value;

  /// The name to greet the user with.
  ///
  /// [ProfileDataController] is the single profile state source introduced in
  /// Batch 2C, so reading it here honours the on-device display-name override
  /// without introducing a second user/profile state.
  String get _displayName {
    final profile = _profile;
    if (profile != null) return profile.displayName;
    return _auth.currentUser.value?.fullName ?? '';
  }

  /// Avatar initials for the header.
  ///
  /// [ProfileDataController.initials] already derives initials from the exact
  /// name rendered beside it, so it is reused rather than recomputed. The local
  /// helper exists only for the defensive case where that controller has not
  /// been registered.
  String get _initials {
    final profile = _profile;
    if (profile != null) {
      final fromProfile = profile.initials;
      return fromProfile.isEmpty ? '?' : fromProfile;
    }
    return _initialsFromName(_auth.currentUser.value?.fullName ?? '');
  }

  static String _initialsFromName(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.substring(0, 1)
        : '';
    return (first + last).toUpperCase();
  }

  String? get _firstName {
    final name = _displayName.trim();
    if (name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Subtitle built only from progress the Growth Center actually loaded —
  /// no invented numbers. Falls back to neutral copy while loading, when the
  /// load failed, or when the user has not created anything yet.
  String _progressSubtitle() {
    final growth = _growth;
    if (growth == null) {
      return 'Track your goals, habits and tasks in one place.';
    }
    if (growth.loading.value) return 'Loading your progress…';
    if (growth.error.value != null) {
      return 'Pull to your Growth Center to see your progress.';
    }

    final habits = growth.habits;
    final goals = growth.goals;
    final tasks = growth.tasks;
    if (habits.isEmpty && goals.isEmpty && tasks.isEmpty) {
      return 'Add your first goal or habit to get going.';
    }

    final facts = <String>[];
    if (habits.isNotEmpty) {
      final done = habits.where((h) => h.isCompletedToday).length;
      facts.add(done == habits.length
          ? 'All ${habits.length} habits done today 🔥'
          : '$done of ${habits.length} habits done today');
    }
    if (goals.isNotEmpty) {
      final average =
          goals.fold<double>(0, (sum, g) => sum + g.effectiveProgress) /
              goals.length;
      facts.add(
        '${goals.length} goal${goals.length == 1 ? '' : 's'} at '
        '${(average * 100).round()}%',
      );
    }
    if (tasks.isNotEmpty) {
      final done = tasks.where((t) => t.isCompleted).length;
      if (done > 0) {
        facts.add('$done of ${tasks.length} to-dos done');
      }
    }
    if (facts.isEmpty) {
      return 'Small steps count — pick one thing for today.';
    }
    return '${facts.join(' · ')}. Keep it going!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.isDark ? context.bg : const Color(0xFFF6F8FC),
      // SingleChildScrollView is what makes the whole page scroll.
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
              _buildTodayProgress(),
              const SizedBox(height: 16),
              _buildTodaysHabits(),
              const SizedBox(height: 16),
              _buildRecentActivity(),
              const SizedBox(height: 16),
              _buildCommunityHighlights(),
              const SizedBox(height: 16), // breathing room above nav bar
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.onAvatarTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Obx(() {
                  final imagePath = _profile?.imagePath;
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4A6CF7),
                      image: imagePath != null ? DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      ) : null,
                    ),
                    child: imagePath == null ? Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ) : null,
                  );
                }),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()} 👋',
                          style: TextStyle(
                              fontSize: 12, color: context.textSecondaryColor),
                        ),
                        Text(
                          _displayName.isEmpty ? 'YOUTHX member' : _displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Bell icon — InkWell so it has a native ripple, navigates to
        // Notifications. No unread badge is drawn: there is no real unread
        // source yet, and a red dot would claim a notification exists.
        Material(
          color: context.cardBg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Get.toNamed(AppRoutes.notifications),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.notifications_none, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ stat cards

  /// Real streak, goal and balance counts. A dash means "still loading"; a `0`
  /// means the module really loaded and has nothing.
  Widget _buildStatCards() {
    return Obx(() {
      _sessionTick;
      final profile = _profile;
      final growth = _growth;
      final finance = _finance;

      final growthLoading = growth?.loading.value ?? true;
      final financeLoading = finance?.loading.value ?? true;

      return Row(
        children: [
          Expanded(
            child: _StatCard(
              emoji: '🔥',
              value: growthLoading || profile == null
                  ? '—'
                  : '${profile.streakDays}',
              label: 'Best Streak',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              emoji: '🎯',
              value: growthLoading || profile == null
                  ? '—'
                  : '${profile.goalCount}',
              label: 'Goals Active',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              emoji: '💰',
              value: financeLoading || finance == null
                  ? '—'
                  : _money(finance.totalBalance),
              label: 'Balance',
            ),
          ),
        ],
      );
    });
  }

  // -------------------------------------------------------- today progress

  /// Replaces the old static "68% there" weekly card with the real state of
  /// today: how many habits are already ticked off and how many to-dos are
  /// closed. The bar is `habitsDone / habitsTotal`, so it is a fact about the
  /// loaded data rather than a decorative guess.
  Widget _buildTodayProgress() {
    return Obx(() {
      _sessionTick;
      final growth = _growth;
      final habits = growth?.habits ?? const <HabitModel>[];
      final tasks = growth?.tasks ?? const <TaskModel>[];
      final goals = growth?.goals ?? const <GoalModel>[];

      final habitsDone = habits.where((h) => h.isCompletedToday).length;
      final tasksDone = tasks.where((t) => t.isCompleted).length;
      final progress =
          habits.isEmpty ? 0.0 : (habitsDone / habits.length).clamp(0.0, 1.0);

      final (title, detail, showBar) = _todayCopy(
        growth: growth,
        habits: habits,
        tasks: tasks,
        goals: goals,
        habitsDone: habitsDone,
        tasksDone: tasksDone,
      );

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
              'TODAY',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (showBar) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$habitsDone of ${habits.length} habits done',
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
          ],
        ),
      );
    });
  }

  /// Headline/supporting copy for the Today card, driven only by loaded data.
  (String, String, bool) _todayCopy({
    required GrowthController? growth,
    required List<HabitModel> habits,
    required List<TaskModel> tasks,
    required List<GoalModel> goals,
    required int habitsDone,
    required int tasksDone,
  }) {
    if (growth == null) {
      return ('Your day at a glance', 'Open Growth to see your habits.', false);
    }
    if (growth.loading.value) {
      return ('Loading your day…', '', false);
    }
    if (growth.error.value != null) {
      return (
          'Could not load your progress',
          'Open Growth Center to try again.',
          false
        );
    }
    if (habits.isEmpty) {
      if (goals.isNotEmpty) {
        return (
          'No habits for today yet',
          'You have ${goals.length} goal${goals.length == 1 ? '' : 's'} in '
              'progress.',
          false
        );
      }
      if (tasks.isNotEmpty) {
        return (
          'No habits for today yet',
          '$tasksDone of ${tasks.length} to-dos done.',
          false
        );
      }
      return (
        'No habits or to-dos yet',
        'Add one in the Growth Center to start tracking.',
        false
      );
    }

    final title = habitsDone == habits.length
        ? 'All ${habits.length} habits done today 🎉'
        : '$habitsDone of ${habits.length} habits done today';
    final details = <String>[];
    if (tasks.isNotEmpty) {
      details.add('$tasksDone of ${tasks.length} to-dos done');
    }
    if (goals.isNotEmpty) {
      details.add('${goals.length} goal${goals.length == 1 ? '' : 's'} active');
    }
    return (title, details.join(' · '), true);
  }

  // -------------------------------------------------------------- habits

  /// Real habits from the Growth Center, with the real completion toggle and
  /// the "View all habits" shell shortcut kept in every state.
  Widget _buildTodaysHabits() {
    return Obx(() {
      _sessionTick;
      final growth = _growth;
      if (growth == null) {
        return _habitsPanel(
          body: const _PanelMessage(
            icon: Icons.cloud_off,
            text: 'Habits are unavailable right now.',
          ),
        );
      }
      if (growth.loading.value) {
        return _habitsPanel(
          body: const _PanelMessage(icon: null, loading: true),
        );
      }
      if (growth.error.value != null) {
        return _habitsPanel(
          body: const _PanelMessage(
            icon: Icons.cloud_off,
            text: 'Could not load your habits. Open Growth Center to retry.',
          ),
        );
      }

      final habits = _previewHabits(growth.habits);
      if (growth.habits.isEmpty) {
        return _habitsPanel(
          body: const _PanelMessage(
            icon: Icons.spa_outlined,
            text: 'No habits yet. Add your first one in the Growth Center.',
          ),
        );
      }

      final done = growth.habits.where((h) => h.isCompletedToday).length;
      return _habitsPanel(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final habit in habits)
              _HabitRow(
                habit: habit,
                onToggle: () =>
                    growth.toggleHabit(habit.id, !habit.isCompletedToday),
              ),
            if (growth.habits.length > habits.length)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+ ${growth.habits.length - habits.length} more',
                  style: TextStyle(
                      fontSize: 11, color: context.textSecondaryColor),
                ),
              ),
          ],
        ),
        trailing: '$done/${growth.habits.length} done',
      );
    });
  }

  /// Habits for the Home preview: scheduled habits first, then everything
  /// else, alphabetical. Capped so Home stays a summary.
  static List<HabitModel> _previewHabits(List<HabitModel> habits) {
    final sorted = habits.toList()
      ..sort((a, b) {
        final aHour = a.scheduledHour;
        final bHour = b.scheduledHour;
        if (aHour == null && bHour != null) return 1;
        if (bHour == null && aHour != null) return -1;
        if (aHour != null && bHour != null && aHour != bHour) {
          return aHour.compareTo(bHour);
        }
        return a.title.compareTo(b.title);
      });
    return sorted.take(3).toList();
  }

  Widget _habitsPanel({
    required Widget body,
    String? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
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
              if (trailing != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F8EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trailing,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          body,
          TextButton(
            onPressed: widget.onViewAllHabits,
            child: const Text('View all habits →'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- recent activity

  /// Real transactions from [FinanceController]. Tapping a row opens the
  /// existing transaction detail flow rather than a Home-only screen.
  Widget _buildRecentActivity() {
    return Obx(() {
      _sessionTick;
      final finance = _finance;
      if (finance == null) {
        return _activityPanel(
          body: const _PanelMessage(
            icon: Icons.cloud_off,
            text: 'Finance is unavailable right now.',
          ),
        );
      }
      if (finance.loading.value) {
        return _activityPanel(body: const _PanelMessage(icon: null, loading: true));
      }
      if (finance.error.value != null) {
        return _activityPanel(
          body: const _PanelMessage(
            icon: Icons.cloud_off,
            text: 'Could not load your transactions. Open Finance to retry.',
          ),
        );
      }

      final txs = finance.recentTransactions;
      if (txs.isEmpty) {
        return _activityPanel(
          body: const _PanelMessage(
            icon: Icons.receipt_long_outlined,
            text: 'No transactions yet. Add one in the Finance tab.',
          ),
        );
      }

      return _activityPanel(
        body: Column(
          children: [
            for (final tx in txs)
              _ActivityRow(
                tx: tx,
                category: finance.resolveCategory(tx),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailPage(transactionId: tx.id),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _activityPanel({required Widget body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: body,
        ),
      ],
    );
  }

  // ---------------------------------------------------- community preview

  /// Real posts from [CommunityController], newest first.
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
            TextButton(
              onPressed: widget.onSeeAllCommunity,
              child: const Text('See All'),
            ),
          ],
        ),
        Obx(() {
          _sessionTick;
          final community = _community;
          if (community == null || community.loading.value) {
            return const _PanelMessage(icon: null, loading: true);
          }
          if (community.feedError.value != null) {
            return const _PanelMessage(
              icon: Icons.cloud_off,
              text: 'Could not load the feed. Open Community to retry.',
            );
          }
          if (community.posts.isEmpty) {
            return const _PanelMessage(
              icon: Icons.forum_outlined,
              text: 'No posts yet. Start the conversation in Community.',
            );
          }
          final posts = community.posts.take(2).toList();
          return Column(
            children: [
              for (final post in posts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CommunityPost.fromModel(post),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------- rows

/// One real habit with its real completion state. Ticking it calls the Growth
/// controller, which persists through the existing repository.
class _HabitRow extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onToggle;

  const _HabitRow({required this.habit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(habit.emoji, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done
                          ? context.textSecondaryColor
                          : context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    habit.streak > 0
                        ? '${habit.frequencyLabel} · ${habit.streak} streak'
                        : habit.frequencyLabel,
                    style: TextStyle(
                        fontSize: 11, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFF10B981) : Colors.transparent,
                border: Border.all(
                  color: done ? const Color(0xFF10B981) : context.borderColor,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 15)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// One real transaction row.
class _ActivityRow extends StatelessWidget {
  final TransactionModel tx;
  final TransactionCategory category;
  final VoidCallback onTap;

  const _ActivityRow({
    required this.tx,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type.toLowerCase() == 'income';
    final label = (tx.note == null || tx.note!.trim().isEmpty)
        ? category.name
        : tx.note!.trim();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFEF6C6C))
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(category.icon.isEmpty ? '•' : category.icon,
                  style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${category.name} · ${_dayMonth.format(tx.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${_money(tx.amount.abs())}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isIncome ? const Color(0xFF10B981) : context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared loading / empty / error body for a Home section.
class _PanelMessage extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final bool loading;

  const _PanelMessage({this.icon, this.text, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon ?? Icons.info_outline,
              size: 22, color: context.textSecondaryColor),
          const SizedBox(height: 8),
          Text(
            text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- cards

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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: 10, color: context.textSecondaryColor),
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

  /// Builds the preview from a real community post, so no copy is invented.
  /// Author initials and avatar colour come from the post's own
  /// [UserModel], which already implements both.
  factory _CommunityPost.fromModel(PostModel post) {
    final author = post.author;
    return _CommunityPost(
      initials: author.initials,
      name: author.name.trim().isEmpty ? 'YOUTHX member' : author.name.trim(),
      time: timeago.format(post.createdAt),
      text: post.caption,
      tags: post.tags,
      avatarColor: author.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
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
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style:
                    TextStyle(fontSize: 11, color: context.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
