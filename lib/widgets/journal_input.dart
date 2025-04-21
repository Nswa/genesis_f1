import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // for ImageFilter

class JournalInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double dragOffsetY;
  final bool isDragging;
  final double swipeThreshold;
  final VoidCallback onHashtagInsert;
  final AnimationController handlePulseController;
  final bool showRipple;

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
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timestamp = DateFormat('h:mm a • MMMM d, yyyy').format(now);

    double fadeValue = (1 + (dragOffsetY / swipeThreshold)).clamp(0.0, 1.0);
    double scaleValue = (1 + (dragOffsetY / (swipeThreshold * 2))).clamp(0.96, 1.0);

    return Transform.translate(
      offset: Offset(0, dragOffsetY),
      child: Transform.scale(
        scale: scaleValue,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Stack(
            children: [
              // ✨ Full acrylic shimmer effect
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: showRipple ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.06),
                              Colors.transparent,
                            ],
                            center: Alignment.center,
                            radius: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ✍️ Input content with drag-fade
              Opacity(
                opacity: fadeValue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ScaleTransition(
                        scale: handlePulseController,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
