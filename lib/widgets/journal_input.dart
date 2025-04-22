// journal_input.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../utils/mood_utils.dart';

class JournalInputWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timestamp = DateFormat('h:mm a • MMMM d, yyyy').format(now);

    double fadeValue = (1 + (dragOffsetY / swipeThreshold)).clamp(0.0, 1.0);
    double scaleValue = (1 + (dragOffsetY / (swipeThreshold * 2))).clamp(0.96, 1.0);
    double dragProgress = (-dragOffsetY / swipeThreshold).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, dragOffsetY),
      child: Transform.scale(
        scale: scaleValue,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: fadeValue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, -20 * dragProgress),
                        child: Transform.rotate(
                          angle: dragProgress * 0.5,
                          child: Transform.scale(
                            scale: 0.8 + 0.2 * dragProgress,
                            child: Icon(
                              Icons.arrow_upward,
                              size: 15,
                              color: Colors.white.withOpacity(dragProgress),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              timestamp,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white30,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (selectedMood != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                selectedMood!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                        const Icon(Icons.star, color: Colors.white24, size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
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
                    Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableMoods.map((emoji) {
                              return GestureDetector(
                                onTap: () => onMoodSelected(emoji),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    emoji,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white.withOpacity(
                                        selectedMood == emoji ? 1.0 : 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedOpacity(
                              opacity: isDragging ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: const Text(
                                "⬆️ Swipe up to save",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: onHashtagInsert,
                              child: const Text(
                                "# TAG",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
