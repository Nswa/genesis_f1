import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/entry.dart';
import '../utils/mood_utils.dart';
import '../utils/tag_utils.dart';

class JournalController {
  final List<Entry> entries = [];
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final double swipeThreshold = 120.0;
  final TickerProvider vsync;
  final VoidCallback onUpdate;

  double dragOffsetY = 0.0;
  String? selectedMood;
  bool isDragging = false;
  bool hasTriggeredSave = false;
  bool showRipple = false;

  late final AnimationController snapBackController;
  late final AnimationController handlePulseController;
  bool isLoading = false;

  JournalController({required this.vsync, required this.onUpdate}) {
    snapBackController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      dragOffsetY = snapBackController.value * 0;
      onUpdate();
    });

    handlePulseController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  void insertHashtag() {
    final cursorPos = controller.selection.base.offset;
    final text = controller.text;
    final newText = text.replaceRange(cursorPos, cursorPos, "#");
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: cursorPos + 1);
    onUpdate();
  }

  Future<void> loadEntriesFromFirestore() async {
    isLoading = true;
    onUpdate();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading = false;
      onUpdate();
      return;
    }

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('entries')
            .orderBy('timestamp', descending: false)
            .get();

    final loaded =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final rawTime = DateTime.parse(data['timestamp']);

          return Entry(
            text: data['text'] ?? '',
            timestamp: DateFormat('h:mm a • MMMM d, yyyy').format(rawTime),
            timestampRaw: rawTime,
            animController: AnimationController(
              vsync: vsync,
              duration: const Duration(milliseconds: 400),
            )..forward(),
            mood: data['mood'] ?? '😐',
            tags: List<String>.from(data['tags'] ?? []),
            wordCount: data['wordCount'] ?? 0,
          );
        }).toList();

    entries.clear();
    entries.addAll(loaded);
    isLoading = false;
    onUpdate();
  }

  Future<void> _saveEntry() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    );

    final mood = selectedMood ?? analyzeMood(text);
    final tags = extractTags(text);
    final wordCount = text.split(RegExp(r'\s+')).length;
    final timestamp = DateTime.now();

    final entry = Entry(
      text: text,
      timestamp: DateFormat('h:mm a • MMMM d, yyyy').format(timestamp),
      timestampRaw: timestamp,
      animController: animationController,
      mood: mood,
      tags: tags,
      wordCount: wordCount,
    );

    entries.add(entry);
    controller.clear();
    dragOffsetY = 0;
    selectedMood = null;
    showRipple = true;
    onUpdate();

    animationController.forward();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('entries')
          .add({
            'text': text,
            'timestamp': timestamp.toIso8601String(),
            'mood': mood,
            'tags': tags,
            'wordCount': wordCount,
            'isFavorite': false,
          });
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      showRipple = false;
      onUpdate();
    });
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (controller.text.trim().isEmpty) return;

    dragOffsetY += details.delta.dy;
    dragOffsetY = dragOffsetY.clamp(-300.0, 0.0);
    isDragging = true;
    onUpdate();

    if (!hasTriggeredSave && dragOffsetY < -swipeThreshold) {
      hasTriggeredSave = true;
      _saveEntry();
      snapBackController.forward(from: 0);
      dragOffsetY = 0;
      isDragging = false;
      onUpdate();
    }
  }

  void handleDragEnd() {
    hasTriggeredSave = false;
    if (!isDragging) return;

    snapBackController.forward(from: 0);
    dragOffsetY = 0;
    isDragging = false;
    onUpdate();
  }

  void dispose() {
    for (var e in entries) {
      e.animController.dispose();
    }
    controller.dispose();
    focusNode.dispose();
    snapBackController.dispose();
    handlePulseController.dispose();
  }
}
