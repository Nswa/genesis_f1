import 'package:flutter/animation.dart';

class Entry {
  final String text;
  final String timestamp; // formatted time only: e.g., "3:42 PM"
  final DateTime rawDateTime; // raw full datetime for grouping
  bool isFavorite;
  final AnimationController animController;
  final String mood;
  final List<String> tags;
  final int wordCount;

  Entry({
    required this.text,
    required this.timestamp,
    required this.rawDateTime,
    this.isFavorite = false,
    required this.animController,
    required this.mood,
    required this.tags,
    required this.wordCount,
  });
}
