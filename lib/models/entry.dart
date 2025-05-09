import 'package:flutter/animation.dart';

class Entry {
  final String text;
  final String timestamp;
  bool isFavorite;
  final AnimationController animController;
  final String mood;
  final List<String> tags;
  final int wordCount;
  final DateTime timestampRaw; // Add this line

  Entry({
    required this.timestampRaw, // Add this
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
    required this.animController,
    required this.mood,
    required this.tags,
    required this.wordCount,
  });
}
