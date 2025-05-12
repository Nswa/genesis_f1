import 'package:flutter/animation.dart';

class Entry {
  final String text;
  final String timestamp; // formatted time only: e.g., "3:42 PM"
  final DateTime rawDateTime; // raw full datetime for grouping
  bool isFavorite;
  final AnimationController animController;
  final String? mood; // Changed to nullable String
  final List<String> tags;
  final int wordCount;
  String? imageUrl; // Added for image URL
  bool isSelected;

  Entry({
    required this.text,
    required this.timestamp,
    required this.rawDateTime,
    this.isFavorite = false,
    required this.animController,
    this.mood, // Changed to optional
    required this.tags,
    required this.wordCount,
    this.imageUrl, // Added to constructor
    this.isSelected = false,
  });
}
