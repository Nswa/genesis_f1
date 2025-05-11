import 'package:flutter/material.dart';
import '../models/entry.dart';

class JournalEntryWidget extends StatelessWidget {
  final Entry entry;
  final void Function(Entry) onToggleFavorite;
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
    // final hintColor = theme.hintColor; // No longer used directly for timestamp
    // final metaColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8); // Will use theme.textTheme.bodySmall directly

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
            padding: const EdgeInsets.fromLTRB(
              12,
              8, // Further reduced top padding
              12,
              8, // Further reduced bottom padding
            ),
            decoration: BoxDecoration(
              color:
                  entry.isSelected
                      ? theme
                          .highlightColor // Use defined highlightColor directly
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
                  padding: const EdgeInsets.only(bottom: 0), // Removed left: 4
                  child: Text(
                    entry.timestamp,
                    style:
                        theme.textTheme.bodySmall, // Use bodySmall from theme
                  ),
                ),
                if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200, // Max height for the displayed image
                        minWidth: double.infinity, // Try to take full width
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              height: 100, // Placeholder height on error
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[600],
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${entry.mood} • ${entry.tags.join(" ")} • ${entry.wordCount} words',
                        style:
                            theme
                                .textTheme
                                .bodySmall, // Use bodySmall from theme
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
                      onTap: () => onToggleFavorite(entry),
                      behavior:
                          HitTestBehavior
                              .opaque, // Ensure tap registers on padding
                      child: Padding(
                        // Add padding to increase touch target
                        padding: const EdgeInsets.all(
                          8.0,
                        ), // 8dp padding around icon
                        child: Icon(
                          entry.isFavorite
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          size: 18, // Icon size remains 18
                          color:
                              entry.isFavorite
                                  ? Colors
                                      .amber // Or another color for selected bookmark
                                  : theme
                                      .iconTheme
                                      .color, // Use iconTheme color directly
                        ),
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 4), // Removed space for divider
                // Divider Removed
              ],
            ),
          ),
        ),
      ),
    );
  }
}
