import 'dart:io'; // Added for File type
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added image_picker
import '../controller/journal_controller.dart'; // Added controller import
import '../utils/mood_utils.dart';
import '../utils/date_formatter.dart';

class JournalInputWidget extends StatefulWidget {
  // final TextEditingController controller; // Will use widget.journalController.controller
  // final FocusNode focusNode; // Will use widget.journalController.focusNode
  final double dragOffsetY;
  final bool isDragging;
  final double swipeThreshold;
  final VoidCallback onHashtagInsert;
  final AnimationController handlePulseController;
  final bool showRipple;
  final Function(String) onMoodSelected;
  final String? selectedMood;
  // final TextEditingController controller; // Will use widget.journalController.controller
  // final FocusNode focusNode; // Will use widget.journalController.focusNode
  // final double dragOffsetY; // Will use widget.journalController.dragOffsetY
  // final bool isDragging; // Will use widget.journalController.isDragging
  // final double swipeThreshold; // Will use widget.journalController.swipeThreshold
  // final VoidCallback onHashtagInsert; // Will use widget.journalController.insertHashtag
  // final AnimationController handlePulseController; // Will use widget.journalController.handlePulseController
  // final bool showRipple; // Will use widget.journalController.showRipple
  // final String? selectedMood; // Will use widget.journalController.selectedMood
  // final Function(String) onMoodSelected; // Will use widget.journalController.selectedMood setter

  final JournalController journalController; // Added JournalController instance

  const JournalInputWidget({
    super.key,
    required this.journalController, // Changed to accept JournalController
    // Keep these for now as they are directly used by parent for other things or passed down
    required this.dragOffsetY,
    required this.isDragging,
    required this.swipeThreshold,
    required this.onHashtagInsert,
    required this.handlePulseController,
    required this.showRipple,
    required this.onMoodSelected,
    this.selectedMood,
    // controller and focusNode are no longer passed directly
  });

  @override
  State<JournalInputWidget> createState() => _JournalInputWidgetState();
}

class _JournalInputWidgetState extends State<JournalInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _emojiBarController;
  bool _isEmojiBarExpanded = false;
  // File? _pickedImageFile; // Removed, will use widget.journalController.pickedImageFile
  // final ImagePicker _picker = ImagePicker(); // Removed, logic in JournalController

  late AnimationController _arrowAnimController;

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
  }

  @override
  void dispose() {
    _emojiBarController.dispose();
    _arrowAnimController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage() async { // Moved to JournalController
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     setState(() {
  //       _pickedImageFile = File(image.path);
  //     });
  //   }
  // }

  // void _clearImage() { // Moved to JournalController
  //   setState(() {
  //     _pickedImageFile = null;
  //   });
  // }

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
                              DateFormatter.formatTime(now),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              // Changed from GestureDetector(Text(...)) to IconButton
                              icon: Icon(
                                Icons.mood,
                                size: 14, // Adjusted size to match nearby text
                                color:
                                    widget.journalController.selectedMood !=
                                            null // Use controller's state
                                        ? theme.textTheme.bodyLarge?.color
                                        : theme.hintColor,
                              ),
                              onPressed: _toggleEmojiBar,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              // Added image picker button
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 20,
                              ),
                              onPressed:
                                  widget
                                      .journalController
                                      .pickImage, // Call controller's method
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              color: theme.hintColor,
                            ),
                            const Spacer(),
                            Text(
                              DateFormatter.formatFullDate(now),
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
                      controller:
                          widget
                              .journalController
                              .controller, // Use controller's TextEditingController
                      focusNode:
                          widget
                              .journalController
                              .focusNode, // Use controller's FocusNode
                      maxLines: null,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: "Write your thoughts...",
                        hintStyle: TextStyle(color: theme.hintColor),
                        border: InputBorder.none,
                      ),
                    ),
                    if (widget
                            .journalController
                            .pickedImageFile != // Use controller's pickedImageFile
                        null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              constraints: const BoxConstraints(
                                maxHeight: 100, // Max height for thumbnail
                                maxWidth: 150, // Max width for thumbnail
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: theme.dividerColor,
                                  width: 0.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.5),
                                child: Image.file(
                                  widget
                                      .journalController
                                      .pickedImageFile!, // Use controller's pickedImageFile
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  widget
                                      .journalController
                                      .clearImage, // Call controller's method
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
