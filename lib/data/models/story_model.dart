import 'package:flutter/material.dart';
import 'user_model.dart';

/// Serializes a [Color] to a `#RRGGBBAA` hex string.
String colorToHex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Parses a `#RRGGBB` or `#RRGGBBAA` hex string back into a [Color].
Color colorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.parse(cleaned, radix: 16);
  return Color(cleaned.length == 8 ? value : (0xFF000000 | value));
}

/// A single piece of text placed anywhere on top of a story image,
/// draggable by the user (Instagram-style).
class StoryTextOverlay {
  final String id;
  Offset position; // normalized 0..1 of canvas width/height
  String text;
  Color color;
  double fontSize;

  StoryTextOverlay({
    required this.id,
    required this.position,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 22,
  });
}

class StoryModel {
  final String id;
  final UserModel author;
  final String imagePath;
  final List<StoryTextOverlay> textOverlays;
  final DateTime createdAt;

  /// Solid background shown behind the image (or as the full background for
  /// a text-only story). Hex string like `#FF2F80ED`; null = transparent/
  /// black fallback.
  final String? backgroundColorHex;
  bool viewed;

  StoryModel({
    required this.id,
    required this.author,
    required this.imagePath,
    this.textOverlays = const [],
    required this.createdAt,
    this.backgroundColorHex,
    this.viewed = false,
  });

  /// Stories are only visible for 24 hours after they're posted.
  bool get isExpired =>
      DateTime.now().difference(createdAt) > const Duration(hours: 24);
}
