 
import 'package:flutter/material.dart';

enum PostTab { myPosts, shared, saved }

 
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
 