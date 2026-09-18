 
import 'package:flutter/material.dart';

enum PostTab { myPosts, shared, saved }
 
class Post {
  final String id;
  final String authorName;
  final String authorInitials;
  final String timeAgo;
  final String caption;
  final int likeCount;
  bool isSaved;
  bool isLiked;
 
  Post({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.timeAgo,
    required this.caption,
    required this.likeCount,
    this.isSaved = false,
    this.isLiked = false,
  });
}
 
class MenuItemData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final bool isToggle;
  final bool isDanger;
 
  MenuItemData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.isToggle = false,
    this.isDanger = false,
  });
}
 