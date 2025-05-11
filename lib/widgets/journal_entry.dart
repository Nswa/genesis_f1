import 'package:flutter/material.dart';
import '../models/entry.dart';

class JournalEntryWidget extends StatelessWidget {
  final Entry entry;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const JournalEntryWidget({
    super.key,
    required this.entry,
    required this.onToggleFavorite,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.hintColor;
    final metaColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: entry.animController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(entry.animController),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          behavior: HitTestBehavior.opaque, // Improve hit detection
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 120,
            ), // Shorter duration for snappier feel
            curve: Curves.easeOutQuart, // Curve for a smooth but quick start
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            decoration: BoxDecoration(
              color:
                  entry.isSelected
                      ? theme.highlightColor.withOpacity(
                        0.3,
                      ) // More subtle contrast
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(
                entry.isSelected ? 6.0 : 0.0, // Slightly smaller radius
              ),
            ),
            transform:
                Matrix4.identity()..scale(
                  entry.isSelected ? 0.97 : 1.0, // Adjusted scale for selection
                ),
            transformAlignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 0, left: 4),
                  child: Text(
                    entry.timestamp,
                    style: TextStyle(
                      fontSize: 11,
                      color: hintColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${entry.mood} • ${entry.tags.join(" ")} • ${entry.wordCount} words',
                        style: TextStyle(fontSize: 12, color: metaColor),
                        softWrap: true,
                        overflow: TextOverflow.fade,
                      ),
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
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onToggleFavorite,
                      child: Icon(
                        Icons.star,
                        size: 18,
                        color:
                            entry.isFavorite
                                ? Colors.amber
                                : theme.iconTheme.color?.withValues(
                                  alpha: 0.24,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
