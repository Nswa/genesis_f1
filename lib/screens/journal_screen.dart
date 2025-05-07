import 'package:flutter/material.dart';
import 'package:genesis_f1/utils/system_ui_helper.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../widgets/journal_input.dart';
import '../widgets/journal_entry.dart';
import '../utils/mood_utils.dart';
import '../utils/tag_utils.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  final List<Entry> _entries = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  double _dragOffsetY = 0.0;
  String? _selectedMood;
  bool _isDragging = false;
  bool _hasTriggeredSave = false;
  bool _showRipple = false;

  final double _swipeThreshold = 120.0;

  late AnimationController _snapBackController;
  late AnimationController _handlePulseController;

  @override
  void initState() {
    super.initState();

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      setState(() {
        _dragOffsetY = _snapBackController.value * 0;
      });
    });

    _handlePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  void _insertHashtag() {
    final cursorPos = _controller.selection.base.offset;
    final text = _controller.text;
    final newText = text.replaceRange(cursorPos, cursorPos, "#");
    setState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(offset: cursorPos + 1);
    });
  }

  void _saveEntry() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final mood = _selectedMood ?? analyzeMood(text);
    final tags = extractTags(text);
    final wordCount = text.split(RegExp(r'\s+')).length;

    final entry = Entry(
      text: text,
      timestamp: DateFormat('h:mm a • MMMM d, yyyy').format(DateTime.now()),
      animController: animationController,
      mood: mood,
      tags: tags,
      wordCount: wordCount,
    );

    setState(() {
      _entries.insert(0, entry);
      _controller.clear();
      _dragOffsetY = 0;
      _showRipple = true;
      _selectedMood = null;
    });

    animationController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showRipple = false;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var e in _entries) {
      e.animController.dispose();
    }
    _controller.dispose();
    _focusNode.dispose();
    _snapBackController.dispose();
    _handlePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);

    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final background = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;
    final progressBaseColor = isDark ? Colors.black12 : Colors.white12;
    final progressFillColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.zero,
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return JournalEntryWidget(
                        entry: entry,
                        onToggleFavorite: () {
                          setState(() => entry.isFavorite = !entry.isFavorite);
                        },
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [background, background.withOpacity(0.0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (_controller.text.trim().isEmpty) return;

                setState(() {
                  _dragOffsetY += details.delta.dy;
                  _dragOffsetY = _dragOffsetY.clamp(-300.0, 0.0);
                  _isDragging = true;
                });

                if (!_hasTriggeredSave && _dragOffsetY < -_swipeThreshold) {
                  _hasTriggeredSave = true;
                  _saveEntry();

                  _snapBackController.forward(from: 0);
                  setState(() {
                    _dragOffsetY = 0;
                    _isDragging = false;
                  });
                }
              },
              onVerticalDragEnd: (_) {
                _hasTriggeredSave = false;
                if (!_isDragging) return;

                _snapBackController.forward(from: 0);
                setState(() {
                  _dragOffsetY = 0;
                  _isDragging = false;
                });
              },
              child: JournalInputWidget(
                controller: _controller,
                focusNode: _focusNode,
                dragOffsetY: _dragOffsetY,
                isDragging: _isDragging,
                swipeThreshold: _swipeThreshold,
                onHashtagInsert: _insertHashtag,
                handlePulseController: _handlePulseController,
                showRipple: _showRipple,
                onMoodSelected: (mood) {
                  setState(() => _selectedMood = mood);
                },
                selectedMood: _selectedMood,
              ),
            ),
            Container(
              height: 1,
              width: double.infinity,
              color: progressBaseColor,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (-_dragOffsetY / _swipeThreshold).clamp(0.0, 1.0),
                child: Container(height: 1, color: progressFillColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
