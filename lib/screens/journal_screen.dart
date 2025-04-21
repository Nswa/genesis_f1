import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
  final List<Entry> _entries = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  double _dragOffsetY = 0.0;
  bool _isDragging = false;
  final double _swipeThreshold = 120.0;

  late AnimationController _snapBackController;
  late AnimationController _handlePulseController;

  @override
  void initState() {
    super.initState();

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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

    HapticFeedback.lightImpact();

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final mood = analyzeMood(text);
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
    });

    animationController.forward();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey[900],
        content: const Text('Entry saved'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amber,
          onPressed: () {
            setState(() {
              _entries.remove(entry);
              _controller.text = entry.text;
              _controller.selection = TextSelection.collapsed(offset: entry.text.length);
              _focusNode.requestFocus();
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
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
            ),
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _dragOffsetY += details.delta.dy;
                  _dragOffsetY = _dragOffsetY.clamp(-300.0, 0.0);
                  _isDragging = true;
                });
              },
              onVerticalDragEnd: (_) {
                if (_dragOffsetY < -_swipeThreshold) {
                  _saveEntry();
                } else {
                  _snapBackController.forward(from: 0);
                  setState(() {
                    _dragOffsetY = 0;
                    _isDragging = false;
                  });
                }
              },
              child: JournalInputWidget(
                controller: _controller,
                focusNode: _focusNode,
                dragOffsetY: _dragOffsetY,
                isDragging: _isDragging,
                swipeThreshold: _swipeThreshold,
                onHashtagInsert: _insertHashtag,
                handlePulseController: _handlePulseController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
