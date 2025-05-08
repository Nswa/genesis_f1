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

  @override
  void initState() {
    super.initState();
    _emojiBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _emojiBarController.dispose();
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
    final timestamp = DateFormat('h:mm a • MMMM d, yyyy').format(now);
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleEmojiBar,
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.selectedMood ?? '😊',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          widget.selectedMood != null
                                              ? theme.textTheme.bodyLarge?.color
                                              : theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        //Icon(Icons.star,color: theme.iconTheme.color?.withValues(alpha: 0.24),size: 18,),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      cursorColor:
                          theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,

                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      maxLines: null,
                      autofocus: true,
                      style:
                          theme
                              .textTheme
                              .bodyMedium, // 👈 uses BreeSerif via theme
                      decoration: InputDecoration(
                        hintText: "Write your thoughts...",
                        hintStyle: TextStyle(color: theme.hintColor),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedOpacity(
                          opacity: widget.isDragging ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            "⬆️ Swipe up to save",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onHashtagInsert,
                          child: Text(
                            "# TAG",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.54),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                                      ?.withValues(
                                        alpha:
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
