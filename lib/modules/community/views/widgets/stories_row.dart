import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../data/models/story_model.dart';

class StoriesRow extends StatelessWidget {
  final List<StoryModel> stories;
  final VoidCallback onAddStory;
  final ValueChanged<StoryModel> onOpenStory;

  const StoriesRow({
    super.key,
    required this.stories,
    required this.onAddStory,
    required this.onOpenStory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StoryItem(
            label: 'Add Story',
            onTap: onAddStory,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
          ),
          ...stories.map((s) => _StoryItem(
                label: s.author.name.split(' ').first,
                onTap: () => onOpenStory(s),
                child: UserAvatar(
                  user: s.author,
                  size: 56,
                  border: Border.all(
                    color: s.viewed ? context.borderColor : AppColors.primary,
                    width: 2,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;

  const _StoryItem({required this.child, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            child,  
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, color: context.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}

