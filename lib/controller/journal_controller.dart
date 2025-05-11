import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:image_picker/image_picker.dart'; // For ImagePicker
import 'package:firebase_app_check/firebase_app_check.dart'; // Import App Check
import 'package:fuzzy/fuzzy.dart';

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
  bool isSavingEntry = false; // New flag for saving state
  File? pickedImageFile; // Moved from JournalInputWidget
  final ImagePicker _picker = ImagePicker(); // Moved from JournalInputWidget

  String _searchTerm = ''; // Added for search

  late final AnimationController snapBackController;
  late final AnimationController handlePulseController;

  bool get isSelectionMode => selectedEntries.isNotEmpty;

  List<Entry> get filteredEntries {
    if (_searchTerm.isEmpty) {
      return List<Entry>.from(
        entries,
      ); // Return a copy to avoid direct modification
    }
    final fuse = Fuzzy(
      entries,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'text',
            getter: (entry) => (entry as Entry).text,
            weight: 0.7,
          ),
          WeightedKey(
            name: 'tags',
            getter:
                (entry) => (entry as Entry).tags.join(
                  ' ',
                ), // Join tags into a single string
            weight: 0.3,
          ),
        ],
        threshold: 0.6, // Adjust threshold as needed
      ),
    );
    final results = fuse.search(_searchTerm);
    return results.map((r) => r.item as Entry).toList();
  }

  Map<String, List<Entry>> groupEntriesByDate(List<Entry> entriesToGroup) {
    final Map<String, List<Entry>> map = {};
    for (var e in entriesToGroup) {
      final dateStr = DateFormatter.formatForGrouping(e.rawDateTime);
      map.putIfAbsent(dateStr, () => []).add(e);
    }
    return map;
  }

  void updateSearchTerm(String term) {
    _searchTerm = term;
    onUpdate();
  }

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

  // Methods moved from JournalInputWidget's state
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      pickedImageFile = File(image.path);
      onUpdate(); // Notify UI to update
    }
  }

  void clearImage() {
    pickedImageFile = null;
    onUpdate(); // Notify UI to update
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
            imageUrl: data['imageUrl'] as String?, // Load imageUrl
          );
        }).toList();

    entries.addAll(loaded);
    isLoading = false;
    onUpdate();
  }

  Future<void> _saveEntry() async {
    if (isSavingEntry) return; // Prevent concurrent saves

    isSavingEntry = true;
    onUpdate();

    final text = controller.text.trim();
    // Allow saving even if text is empty, if there's an image
    if (text.isEmpty && pickedImageFile == null) {
      isSavingEntry = false;
      onUpdate();
      return;
    }

    final animationController = AnimationUtils.createDefaultController(vsync);
    String? uploadedImageUrl;
    final user = FirebaseAuth.instance.currentUser;

    try {
      // Upload image if one is picked
      if (pickedImageFile != null && user != null) {
        debugPrint("Attempting to upload image: ${pickedImageFile!.path}");
        // try/catch for image upload specifically
        try {
          debugPrint(
            "Forcing App Check token refresh before storage operation...",
          );
          String? currentToken = await FirebaseAppCheck.instance.getToken(true);
          debugPrint("Token before storage op: $currentToken");
          if (currentToken == null) {
            debugPrint(
              "Failed to get a fresh App Check token. Upload will likely fail.",
            );
          }

          final fileName =
              '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child(user.uid)
              .child(fileName);
          debugPrint("Storage reference: ${storageRef.fullPath}");
          UploadTask uploadTask = storageRef.putFile(pickedImageFile!);
          TaskSnapshot snapshot = await uploadTask;
          uploadedImageUrl = await snapshot.ref.getDownloadURL();
          debugPrint("Image uploaded successfully. URL: $uploadedImageUrl");
        } catch (e) {
          debugPrint("Error uploading image: $e");
        }
      } else {
        if (pickedImageFile == null) {
          debugPrint("No image picked to upload.");
        }
        if (user == null) {
          debugPrint("User not authenticated, cannot upload image.");
        }
      }

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
        imageUrl: uploadedImageUrl,
      );

      entries.add(entry);
      controller.clear();
      pickedImageFile = null;
      dragOffsetY = 0;
      selectedMood = null;
      showRipple = true;

      animationController.forward();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Make callback async
        // Add a small delay to allow the list to build and dimensions to settle
        await Future.delayed(const Duration(milliseconds: 100));
        if (scrollController.hasClients) {
          // Check again if mounted or if scrollController is still valid if issues persist
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });

      if (user != null) {
        final Map<String, dynamic> firestoreData = {
          'text': text,
          'timestamp': timestamp.toIso8601String(),
          'mood': mood,
          'tags': tags,
          'wordCount': wordCount,
          'isFavorite': false,
          'imageUrl': uploadedImageUrl,
        };
        debugPrint("Data to save to Firestore: $firestoreData");
        await FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .add(firestoreData);
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        showRipple = false;
        // onUpdate is called in finally
      });
    } finally {
      isSavingEntry = false;
      onUpdate();
    }
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (isSavingEntry || controller.text.trim().isEmpty)
      return; // Check isSavingEntry

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

  void selectEntriesByDate(List<Entry> entriesInGroup) {
    bool changed = false;
    for (var entry in entriesInGroup) {
      if (!entry.isSelected) {
        entry.isSelected = true;
        selectedEntries.add(entry);
        changed = true;
      }
    }
    if (changed) {
      onUpdate();
    }
  }

  void deselectEntriesByDate(List<Entry> entriesInGroup) {
    bool changed = false;
    for (var entry in entriesInGroup) {
      if (entry.isSelected) {
        entry.isSelected = false;
        selectedEntries.remove(entry);
        changed = true;
      }
    }
    if (changed) {
      onUpdate();
    }
  }

  Future<void> toggleFavorite(Entry entry) async {
    entry.isFavorite = !entry.isFavorite;
    onUpdate();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("User not logged in, cannot update favorite status.");
      // Optionally revert local change if Firestore update fails
      // entry.isFavorite = !entry.isFavorite;
      // onUpdate();
      return;
    }

    // Find the document to update. This requires entries to have a Firestore ID.
    // Assuming entry.id holds the Firestore document ID.
    // This part needs to be adjusted based on how Firestore IDs are managed.
    // For now, let's assume we query by timestamp and text, similar to delete.
    // THIS IS NOT IDEAL AND SHOULD BE REPLACED WITH DOCUMENT ID LOOKUP.
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .where(
                'timestamp',
                isEqualTo: entry.rawDateTime.toIso8601String(),
              )
              .where(
                'text',
                isEqualTo: entry.text,
              ) // This makes it less reliable
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .doc(docId)
            .update({'isFavorite': entry.isFavorite});
        debugPrint(
          "Updated favorite status for entry $docId to ${entry.isFavorite}",
        );
      } else {
        debugPrint(
          "Could not find entry in Firestore to update favorite status.",
        );
        // Optionally revert local change
        // entry.isFavorite = !entry.isFavorite;
        // onUpdate();
      }
    } catch (e) {
      debugPrint("Error updating favorite status in Firestore: $e");
      // Optionally revert local change
      // entry.isFavorite = !entry.isFavorite;
      // onUpdate();
    }
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
