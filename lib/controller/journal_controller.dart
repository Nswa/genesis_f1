import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/entry.dart';
import '../utils/mood_utils.dart';
import '../utils/tag_utils.dart';
import '../utils/date_formatter.dart';
import '../utils/firestore_paths.dart';
import '../utils/animation_utils.dart';

class JournalController {
  final List<Entry> entries = [];
  final List<Entry> selectedEntries = [];
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController;

  final double swipeThreshold = 120.0;
  final TickerProvider vsync;
  final VoidCallback onUpdate;

  double dragOffsetY = 0.0;
  String? selectedMood;
  bool isDragging = false;
  bool hasTriggeredSave = false;
  bool showRipple = false;
  bool isLoading = false;

  late final AnimationController snapBackController;
  late final AnimationController handlePulseController;

  bool get isSelectionMode => selectedEntries.isNotEmpty;

  JournalController({
    required this.vsync,
    required this.onUpdate,
    required this.scrollController,
  }) {
    snapBackController = AnimationUtils.createSnapBackController(vsync)
      ..addListener(() {
        dragOffsetY = snapBackController.value * 0;
        onUpdate();
      });

    handlePulseController = AnimationUtils.createPulseController(vsync)
      ..repeat(reverse: true);
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
            .collection(FirestorePaths.userEntriesPath())
            .orderBy('timestamp', descending: false)
            .get();

    final loaded =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final parsedTimestamp = DateTime.parse(data['timestamp']);
          return Entry(
            text: data['text'] ?? '',
            timestamp: DateFormatter.formatTime(parsedTimestamp),
            rawDateTime: parsedTimestamp,
            animController: AnimationUtils.createDefaultController(vsync)
              ..forward(),
            mood: data['mood'] ?? '😐',
            tags: List<String>.from(data['tags'] ?? []),
            wordCount: data['wordCount'] ?? 0,
          );
        }).toList();

    entries.addAll(loaded);
    isLoading = false;
    onUpdate();
  }

  Future<void> _saveEntry() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final animationController = AnimationUtils.createDefaultController(vsync);

    final mood = selectedMood ?? analyzeMood(text);
    final tags = extractTags(text);
    final wordCount = text.split(RegExp(r'\s+')).length;
    final timestamp = DateTime.now();

    final entry = Entry(
      text: text,
      timestamp: DateFormatter.formatTime(timestamp),
      rawDateTime: timestamp,
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

    // Scroll to bottom after adding new entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.userEntriesPath())
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

  void toggleEntrySelection(Entry entry) {
    entry.isSelected = !entry.isSelected;
    if (entry.isSelected) {
      selectedEntries.add(entry);
    } else {
      selectedEntries.remove(entry);
    }
    onUpdate();
  }

  void clearSelection() {
    for (var entry in selectedEntries) {
      entry.isSelected = false;
    }
    selectedEntries.clear();
    onUpdate();
  }

  Future<void> deleteSelectedEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Or handle error

    final batch = FirebaseFirestore.instance.batch();
    final entriesToRemove = List<Entry>.from(selectedEntries); // Create a copy

    for (var entry in entriesToRemove) {
      // Assuming entries have a unique ID or can be identified for deletion in Firestore
      // For this example, we'll assume we need to query by text and timestamp,
      // which is not ideal for production but works for this context.
      // A better approach would be to store Firestore document IDs in the Entry model.
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .where('text', isEqualTo: entry.text)
              .where(
                'timestamp',
                isEqualTo: entry.rawDateTime.toIso8601String(),
              )
              .limit(
                1,
              ) // Expecting unique entries based on text and exact timestamp
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        batch.delete(querySnapshot.docs.first.reference);
      }
      entries.remove(entry); // Remove from local list
      entry.animController.dispose(); // Dispose animation controller
    }

    await batch.commit();
    selectedEntries.clear();
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
