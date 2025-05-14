import 'dart:async';
import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:image_picker/image_picker.dart'; // For ImagePicker

import 'package:fuzzy/fuzzy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/sembast_io.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/entry.dart';

import '../utils/tag_utils.dart';
import '../utils/date_formatter.dart';
import '../utils/firestore_paths.dart';
import '../utils/animation_utils.dart';

enum SyncStatus { offline, syncing, synced, error }

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
  bool isSavingEntry = false;
  File? pickedImageFile;
  final ImagePicker _picker = ImagePicker();

  String _searchTerm = '';

  late final AnimationController snapBackController;
  late final AnimationController handlePulseController;

  sembast.Database? _db;
  sembast.StoreRef<String, Map<String, Object?>>? _store;
  SyncStatus _syncStatus = SyncStatus.synced;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  SyncStatus get syncStatus => _syncStatus;

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

  // Getter for favorite entries
  List<Entry> get favoriteEntries {
    return entries.where((entry) => entry.isFavorite).toList();
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

    _initDb();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  Future<void> _initDb() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDocDir.path}/journal.db';
    _db = await databaseFactoryIo.openDatabase(dbPath);
    _store = sembast.stringMapStoreFactory.store('entries');
    await loadEntries(); // Load entries after DB init
  }

  Future<void> _updateConnectivityStatus(ConnectivityResult result) async {
    // Always update sync status instantly on connectivity change
    if (result == ConnectivityResult.none) {
      _syncStatus = SyncStatus.offline;
      onUpdate();
      return;
    }
    await _syncOfflineEntries();
    _updateSyncStatus();
  }

  void _updateSyncStatus() {
    Connectivity().checkConnectivity().then((connectivityResult) {
      if (connectivityResult == ConnectivityResult.none) {
        _syncStatus = SyncStatus.offline;
        onUpdate();
        return;
      }
      if (_store != null && _db != null) {
        _store!
            .query(
              finder: sembast.Finder(
                filter: sembast.Filter.equals('isSynced', false),
              ),
            )
            .count(_db!)
            .then((count) {
              if (count > 0) {
                _syncStatus = SyncStatus.syncing;
              } else {
                _syncStatus = SyncStatus.synced;
              }
              onUpdate();
            });
      } else {
        _syncStatus = SyncStatus.synced;
        onUpdate();
      }
    });
  }

  Future<void> loadEntries() async {
    isLoading = true;
    onUpdate();

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _syncStatus = SyncStatus.offline;
      await _loadEntriesFromDb();
    } else {
      _syncStatus = SyncStatus.synced;
      await loadEntriesFromFirestore();
    }
    isLoading = false;
    onUpdate();
  }

  Future<void> _loadEntriesFromDb() async {
    if (_db == null || _store == null) return;
    final records = await _store!.find(_db!);
    entries.clear();
    for (var record in records) {
      entries.add(_entryFromMap(record.key, record.value));
    }
    entries.sort((a, b) => a.rawDateTime.compareTo(b.rawDateTime));
    onUpdate();
  }

  Future<void> loadEntriesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading = false;
      onUpdate();
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .orderBy('timestamp', descending: false)
              .get();

      final loadedEntries =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final parsedTimestamp = DateTime.parse(data['timestamp']);
            return Entry(
              firestoreId: doc.id,
              text: data['text'] ?? '',
              timestamp: DateFormatter.formatTime(parsedTimestamp),
              rawDateTime: parsedTimestamp,
              animController: AnimationUtils.createDefaultController(vsync)
                ..forward(),
              mood: data['mood'],
              tags: List<String>.from(data['tags'] ?? []),
              wordCount: data['wordCount'] ?? 0,
              imageUrl: data['imageUrl'] as String?,
              isFavorite: data['isFavorite'] ?? false,
              isSynced: true,
              localId: doc.id,
              localImagePath: null,
            );
          }).toList();

      entries.clear();
      entries.addAll(loadedEntries);

      if (_db != null && _store != null) {
        await _store!.delete(_db!);
        for (var entry in entries) {
          await _store!
              .record(entry.firestoreId!)
              .put(_db!, _entryToMap(entry));
        }
      }
      _syncStatus = SyncStatus.synced;
    } catch (e) {
      debugPrint("Error loading from Firestore: $e");
      _syncStatus = SyncStatus.error;
      await _loadEntriesFromDb();
    }

    isLoading = false;
    onUpdate();
  }

  Future<void> _saveEntry() async {
    if (isSavingEntry) return;

    isSavingEntry = true;
    _syncStatus = SyncStatus.syncing;
    onUpdate();

    final text = controller.text.trim();
    if (text.isEmpty && pickedImageFile == null) {
      isSavingEntry = false;
      _updateSyncStatus();
      onUpdate();
      return;
    }

    final animationController = AnimationUtils.createDefaultController(vsync);
    String? uploadedImageUrl;
    String? localImagePath;
    final user = FirebaseAuth.instance.currentUser;
    final timestamp = DateTime.now();
    final localId =
        'local_${timestamp.millisecondsSinceEpoch}_${entries.length}';

    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;

    if (pickedImageFile != null) {
      if (isOnline && user != null) {
        try {
          final fileName =
              '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child(user.uid)
              .child(fileName);
          UploadTask uploadTask = storageRef.putFile(pickedImageFile!);
          TaskSnapshot snapshot = await uploadTask;
          uploadedImageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          debugPrint("Error uploading image: $e");
        }
      } else {
        // Offline: store local image path
        localImagePath = pickedImageFile!.path;
      }
    }

    final mood = selectedMood;
    final List<String> rawTags = extractTags(text);
    final List<String> tags =
        rawTags
            .map((tag) {
              String currentTag = tag.trim();
              if (currentTag.isEmpty) return null;
              String tagName = currentTag;
              while (tagName.startsWith('#')) {
                tagName = tagName.substring(1);
              }
              if (tagName.isEmpty) return null;
              return '#$tagName';
            })
            .whereType<String>()
            .toList();
    final wordCount =
        text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;

    final entry = Entry(
      localId: localId,
      text: text,
      timestamp: DateFormatter.formatTime(timestamp),
      rawDateTime: timestamp,
      animController: animationController,
      mood: mood,
      tags: tags,
      wordCount: wordCount,
      imageUrl: uploadedImageUrl,
      isSynced: false,
      firestoreId: null,
      localImagePath: localImagePath, // Save local image path if offline
    );

    entries.add(entry);
    if (_db != null && _store != null) {
      await _store!.record(localId).put(_db!, _entryToMap(entry));
    }

    controller.clear();
    pickedImageFile = null;
    dragOffsetY = 0;
    selectedMood = null;
    showRipple = true;
    animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    if (isOnline && user != null) {
      try {
        final firestoreData = _entryToFirestoreMap(entry);
        final docRef = await FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .add(firestoreData);

        entry.firestoreId = docRef.id;
        entry.isSynced = true;
        if (_db != null && _store != null) {
          await _store!.record(localId).update(_db!, {
            'firestoreId': docRef.id,
            'isSynced': true,
          });
        }
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        debugPrint("Error saving to Firestore: $e");
        entry.isSynced = false;
        _syncStatus = SyncStatus.error;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      showRipple = false;
      isSavingEntry = false;
      _updateSyncStatus();
      onUpdate();
    });
  }

  Future<void> _syncOfflineEntries() async {
    if (_db == null || _store == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _syncStatus = SyncStatus.offline;
      onUpdate();
      return;
    }

    _syncStatus = SyncStatus.syncing;
    onUpdate();

    final recordsToSync = await _store!
        .query(
          finder: sembast.Finder(
            filter: sembast.Filter.equals('isSynced', false),
          ),
        )
        .getSnapshots(_db!);

    for (var recordSnapshot in recordsToSync) {
      final entryData = recordSnapshot.value;
      final localId = recordSnapshot.key;
      Entry entry = _entryFromMap(localId, entryData);

      // If entry has a local image path but no imageUrl, upload the image
      if (entry.localImagePath != null &&
          (entry.imageUrl == null || entry.imageUrl!.isEmpty)) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final file = File(entry.localImagePath!);
            if (await file.exists()) {
              final fileName =
                  '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('user_images')
                  .child(user.uid)
                  .child(fileName);
              UploadTask uploadTask = storageRef.putFile(file);
              TaskSnapshot snapshot = await uploadTask;
              final url = await snapshot.ref.getDownloadURL();
              entry.imageUrl = url;
              // Optionally clear localImagePath after upload
              entry.localImagePath = null;
            }
          }
        } catch (e) {
          debugPrint("Error uploading offline image for entry $localId: $e");
        }
      }

      try {
        final firestoreData = _entryToFirestoreMap(entry);
        DocumentReference docRef;
        if (entry.firestoreId != null) {
          docRef = FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .doc(entry.firestoreId);
          await docRef.set(firestoreData, SetOptions(merge: true));
        } else {
          docRef = await FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .add(firestoreData);
          entry.firestoreId = docRef.id;
        }

        entry.isSynced = true;

        await _store!.record(localId).update(_db!, {
          'isSynced': true,
          'firestoreId': entry.firestoreId,
          'imageUrl': entry.imageUrl,
          'localImagePath': entry.localImagePath,
        });

        final index = entries.indexWhere((e) => e.localId == localId);
        if (index != -1) {
          entries[index] = entry;
        }
      } catch (e) {
        debugPrint("Error syncing entry $localId to Firestore: $e");
        _syncStatus = SyncStatus.error;
        onUpdate();
      }
    }
    _updateSyncStatus();
  }

  Map<String, Object?> _entryToMap(Entry entry) {
    return {
      'localId': entry.localId,
      'firestoreId': entry.firestoreId,
      'text': entry.text,
      'timestamp': entry.rawDateTime.toIso8601String(),
      'mood': entry.mood,
      'tags': entry.tags,
      'wordCount': entry.wordCount,
      'imageUrl': entry.imageUrl,
      'isFavorite': entry.isFavorite,
      'isSynced': entry.isSynced,
      'localImagePath': entry.localImagePath, // Save local image path
    };
  }

  Entry _entryFromMap(String key, Map<String, Object?> map) {
    return Entry(
      localId: map['localId'] as String? ?? key,
      firestoreId: map['firestoreId'] as String?,
      text: map['text'] as String,
      timestamp: DateFormatter.formatTime(
        DateTime.parse(map['timestamp'] as String),
      ),
      rawDateTime: DateTime.parse(map['timestamp'] as String),
      animController: AnimationUtils.createDefaultController(vsync)..forward(),
      mood: map['mood'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      wordCount: map['wordCount'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isSynced: map['isSynced'] as bool? ?? false,
      localImagePath:
          map['localImagePath'] as String?, // Restore local image path
    );
  }

  Map<String, dynamic> _entryToFirestoreMap(Entry entry) {
    return {
      'text': entry.text,
      'timestamp': entry.rawDateTime.toIso8601String(),
      'mood': entry.mood,
      'tags': entry.tags,
      'wordCount': entry.wordCount,
      'isFavorite': entry.isFavorite,
      'imageUrl': entry.imageUrl,
    };
  }

  void insertHashtag() {
    final cursorPos = controller.selection.base.offset;
    final text = controller.text;

    if (cursorPos > 0 && text[cursorPos - 1] == '#') {
      if (controller.selection.extent.offset != cursorPos) {
        controller.selection = TextSelection.collapsed(offset: cursorPos);
      }
      return;
    }

    final newText = text.replaceRange(cursorPos, cursorPos, "#");
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: cursorPos + 1);
    onUpdate();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      pickedImageFile = File(image.path);
      onUpdate();
    }
  }

  void clearImage() {
    pickedImageFile = null;
    onUpdate();
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (isSavingEntry || controller.text.trim().isEmpty) return;

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
    entry.isSynced = false;
    _syncStatus = SyncStatus.syncing;
    onUpdate();

    final String recordKey = entry.localId ?? entry.firestoreId!;

    if (_db != null && _store != null) {
      await _store!.record(recordKey).update(_db!, {
        'isFavorite': entry.isFavorite,
        'isSynced': false,
      });
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none &&
        entry.firestoreId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _syncStatus = SyncStatus.offline;
        onUpdate();
        return;
      }
      try {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .doc(entry.firestoreId)
            .update({'isFavorite': entry.isFavorite});
        entry.isSynced = true;
        if (_db != null && _store != null) {
          await _store!.record(recordKey).update(_db!, {'isSynced': true});
        }
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        debugPrint("Error updating favorite status in Firestore: $e");
        _syncStatus = SyncStatus.error;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
    _updateSyncStatus();
    onUpdate();
  }

  Future<void> deleteSelectedEntries() async {
    _syncStatus = SyncStatus.syncing;
    onUpdate();

    final entriesToRemove = List<Entry>.from(selectedEntries);
    final List<String> firestoreIdsToDelete = [];

    for (var entry in entriesToRemove) {
      final String recordKey = entry.localId ?? entry.firestoreId!;
      if (_db != null && _store != null) {
        await _store!.record(recordKey).delete(_db!);
      }
      if (entry.firestoreId != null) {
        firestoreIdsToDelete.add(entry.firestoreId!);
      }
      // Animate removal for instant responsiveness illusion
      entry.animController.reverse();
      entry.animController.addStatusListener((status) async {
        if (status == AnimationStatus.dismissed) {
          entries.remove(entry);
          entry.animController.dispose();
          onUpdate();
        }
      });
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final user = FirebaseAuth.instance.currentUser;
    if (connectivityResult != ConnectivityResult.none &&
        user != null &&
        firestoreIdsToDelete.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (var id in firestoreIdsToDelete) {
        batch.delete(
          FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .doc(id),
        );
      }
      try {
        await batch.commit();
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        debugPrint("Error deleting entries from Firestore: $e");
        _syncStatus = SyncStatus.error;
      }
    } else if (connectivityResult == ConnectivityResult.none || user == null) {
      _syncStatus = SyncStatus.offline;
    } else {
      _syncStatus = SyncStatus.synced;
    }

    selectedEntries.clear();
    _updateSyncStatus();
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
    _connectivitySubscription?.cancel();
    _db?.close();
  }
}
