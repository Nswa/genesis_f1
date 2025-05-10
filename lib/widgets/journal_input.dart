import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/mood_utils.dart';

class JournalInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double dragOffsetY;
  final bool isDragging;
  final double swipeThreshold;
  final VoidCallback onHashtagInsert;
  final AnimationController handlePulseController;
  final bool showRipple;
  final Function(String) onMoodSelected;
  final String? selectedMood;

  const JournalInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.dragOffsetY,
    required this.isDragging,
    required this.swipeThreshold,
    required this.onHashtagInsert,
    required this.handlePulseController,
    required this.showRipple,
    required this.onMoodSelected,
    this.selectedMood,
  });

  @override
  State<JournalInputWidget> createState() => _JournalInputWidgetState();
}

class _JournalInputWidgetState extends State<JournalInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _emojiBarController;
  bool _isEmojiBarExpanded = false;

  late AnimationController _arrowAnimController;
  late Animation<double> _arrowBounce;

  @override
  void initState() {
    super.initState();
    _emojiBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _arrowBounce = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _arrowAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emojiBarController.dispose();
    _arrowAnimController.dispose();
    super.dispose();
  }

  void _toggleEmojiBar() {
    setState(() {
      _isEmojiBarExpanded = !_isEmojiBarExpanded;
      if (_isEmojiBarExpanded) {
        _emojiBarController.forward();
      } else {
        _emojiBarController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    final fadeValue = (1 + (widget.dragOffsetY / widget.swipeThreshold)).clamp(
      0.0,
      1.0,
    );
    final scaleValue = (1 -
            (widget.dragOffsetY.abs() / (widget.swipeThreshold * 1.5)))
        .clamp(0.8, 1.0);

    return Transform.translate(
      offset: Offset(0, widget.dragOffsetY),
      child: Transform.scale(
        scale: scaleValue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 2),
              child: Opacity(
                opacity: fadeValue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 1),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(now),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _toggleEmojiBar,
                              child: Text(
                                widget.selectedMood ?? '😊',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      widget.selectedMood != null
                                          ? theme.textTheme.bodyLarge?.color
                                          : theme.hintColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('MMMM d, yyyy').format(now),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        IgnorePointer(
                          ignoring: true,
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            size: 18,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      cursorColor:
                          theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      maxLines: null,
                      autofocus: true,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: "Write your thoughts...",
                        hintStyle: TextStyle(color: theme.hintColor),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: _isEmojiBarExpanded ? 33 : 0,
              margin: const EdgeInsets.only(top: 4),
              child: ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children:
                        availableMoods.map((emoji) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              widget.onMoodSelected(emoji);
                              _toggleEmojiBar();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(
                                        widget.selectedMood == emoji
                                            ? 1.0
                                            : 0.8,
                                      ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
