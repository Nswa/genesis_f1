import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Import Shimmer
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
                // Timestamp Padding removed - will be added to the metadata row below
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
                          key: ValueKey(entry.imageUrl!),
                          fit: BoxFit.cover,
                          frameBuilder: (
                            BuildContext context,
                            Widget child,
                            int? frame,
                            bool wasSynchronouslyLoaded,
                          ) {
                            if (wasSynchronouslyLoaded) {
                              return child;
                            }
                            if (frame == null) {
                              // Image is still loading, show shimmer
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final baseColor =
                                  isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!;
                              final highlightColor =
                                  isDark
                                      ? Colors.grey[600]!
                                      : Colors.grey[100]!;
                              return Shimmer.fromColors(
                                baseColor: baseColor,
                                highlightColor: highlightColor,
                                period: const Duration(milliseconds: 1000),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                              );
                            }
                            return child; // Image is loaded, display it
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
                Builder(
                  // Use Builder to compute widgets conditionally
                  builder: (context) {
                    final regularStyle = theme.textTheme.bodySmall;
                    // Create timestamp style: copy bodySmall, increase size by 1, keep color
                    final timestampStyle = regularStyle?.copyWith(
                      fontSize:
                          (regularStyle.fontSize ?? 12.0) +
                          1.0, // Default to 12 if null
                    );
                    final separator = Text(' • ', style: regularStyle);

                    // 1. Build the list of actual metadata widgets to display
                    final List<Widget> actualMetadataWidgets = [];

                    // Add Timestamp
                    actualMetadataWidgets.add(
                      Text(entry.timestamp, style: timestampStyle),
                    );

                    // Add Mood if available
                    if (entry.mood != null && entry.mood!.isNotEmpty) {
                      actualMetadataWidgets.add(
                        Text(entry.mood!, style: regularStyle),
                      );
                    }

                    // Add Tags if available (using a Key for identification)
                    const tagsKey = ValueKey('tags');
                    if (entry.tags.isNotEmpty) {
                      actualMetadataWidgets.add(
                        Flexible(
                          key: tagsKey, // Add key to identify the tags widget
                          child: Text(
                            entry.tags.join(" "),
                            style: regularStyle,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                          ),
                        ),
                      );
                    }

                    // Add Word Count if available
                    if (entry.wordCount > 0) {
                      actualMetadataWidgets.add(
                        Text('${entry.wordCount} words', style: regularStyle),
                      );
                    }

                    // 2. Build the final list for the Row, inserting separators conditionally
                    final List<Widget> rowChildren = [];
                    for (int i = 0; i < actualMetadataWidgets.length; i++) {
                      rowChildren.add(
                        actualMetadataWidgets[i],
                      ); // Add the widget itself

                      // Check if a separator is needed *after* this item
                      if (i < actualMetadataWidgets.length - 1) {
                        // Get the next widget
                        final nextWidget = actualMetadataWidgets[i + 1];
                        // Check if the next widget is the Tags widget (using the key)
                        if (!(nextWidget is Flexible &&
                            nextWidget.key == tagsKey)) {
                          // Only add separator if the *next* item is NOT tags
                          rowChildren.add(separator);
                        } else {
                          // If next item IS tags, add a slightly wider space instead of '•'
                          rowChildren.add(Text(' ', style: regularStyle));
                        }
                      }
                    }

                    // 3. Return the Row
                    // Only show the row if there's more than just the timestamp potentially
                    if (rowChildren.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: rowChildren,
                    );
                  },
                ),
                const SizedBox(height: 4), // Keep spacing consistent
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
