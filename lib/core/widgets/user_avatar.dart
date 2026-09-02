import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double size;
  final VoidCallback? onTap;
  final Border? border;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 40,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: user.color,
        shape: BoxShape.circle,
        border: border,
        image: user.avatarUrl != null
            ? DecorationImage(
                image: user.avatarUrl!.startsWith('http')
                    ? NetworkImage(user.avatarUrl!)
                    : FileImage(File(user.avatarUrl!)) as ImageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.avatarUrl == null
          ? Text(
              user.initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.35,
              ),
            )
          : null,
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
