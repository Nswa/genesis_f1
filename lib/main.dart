import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() => runApp(const JournalApp());

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal Dark',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Georgia',
      ),
      home: const JournalScreen(),
    );
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
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
                itemBuilder: (context, index) => _buildEntry(_entries[index]),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }
  final List<_Entry> _entries = [];
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

  String _analyzeMood(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("happy") || lower.contains("excited") || lower.contains("love")) return "😊";
    if (lower.contains("tired") || lower.contains("ok") || lower.contains("fine")) return "😐";
    if (lower.contains("sad") || lower.contains("stress") || lower.contains("hate")) return "😔";
    return "😐";
  }

  List<String> _extractTags(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 4).toList();
    words.sort((a, b) => b.length.compareTo(a.length));
    return words.take(2).map((e) => '#$e').toList();
  }

  void _saveEntry() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final mood = _analyzeMood(text);
    final tags = _extractTags(text);
    final wordCount = text.split(RegExp(r'\s+')).length;

    final entry = _Entry(
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

  Widget _buildEntry(_Entry entry) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: entry.animController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(entry.animController),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  entry.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white30,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${entry.mood} • ${entry.tags.join(" ")} • ${entry.wordCount} words',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.text,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.55,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() => entry.isFavorite = !entry.isFavorite);
                    },
                    child: Icon(
                      Icons.star,
                      size: 18,
                      color: entry.isFavorite ? Colors.amber : Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final now = DateTime.now();
    final timestamp = DateFormat('h:mm a • MMMM d, yyyy').format(now);

    double fadeValue = (1 + (_dragOffsetY / _swipeThreshold)).clamp(0.0, 1.0);
    double scaleValue = (1 + (_dragOffsetY / (_swipeThreshold * 2))).clamp(0.96, 1.0);

    return GestureDetector(
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
      child: Transform.translate(
        offset: Offset(0, _dragOffsetY),
        child: Transform.scale(
          scale: scaleValue,
          child: Opacity(
            opacity: fadeValue,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ScaleTransition(
                      scale: _handlePulseController,
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white30,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.white24, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.55,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Write your thoughts...",
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedOpacity(
                        opacity: _isDragging ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Text(
                          "⬆️ Swipe up to save",
                          style: TextStyle(fontSize: 11, color: Colors.white30),
                        ),
                      ),
                      GestureDetector(
                        onTap: _insertHashtag,
                        child: const Text(
                          "# TAG",
                          style: TextStyle(fontSize: 13, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Entry {
  final String text;
  final String timestamp;
  bool isFavorite;
  final AnimationController animController;
  final String mood;
  final List<String> tags;
  final int wordCount;

  _Entry({
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
    required this.animController,
    required this.mood,
    required this.tags,
    required this.wordCount,
  });
}
