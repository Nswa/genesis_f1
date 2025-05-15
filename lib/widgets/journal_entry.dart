import 'package:flutter/material.dart';
import 'dart:io'; // Import for File
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage
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

  Widget _buildTagsBar(BuildContext context, TextStyle? style) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              entry.tags.join(" "),
              style: style,
              softWrap: false,
              maxLines: 1,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 10,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    theme.scaffoldBackgroundColor.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMetadata(
    BuildContext context,
    TextStyle? regularStyle,
    TextStyle? timestampStyle,
  ) {
    final List<Widget?> widgets = [
      Text(entry.timestamp, style: timestampStyle),
      entry.mood?.isNotEmpty == true
          ? Text(entry.mood!, style: regularStyle)
          : null,
      entry.tags.isNotEmpty
          ? Flexible(child: _buildTagsBar(context, regularStyle))
          : null,
      entry.wordCount > 0
          ? Text('${entry.wordCount} words', style: regularStyle)
          : null,
    ];
    // Remove nulls
    return widgets.whereType<Widget>().toList();
  }

  Widget _joinWithSeparator(
    List<Widget> widgets,
    Widget separator,
    Widget tagsSpacer,
  ) {
    if (widgets.isEmpty) return const SizedBox.shrink();
    final List<Widget> children = [];
    for (int i = 0; i < widgets.length; i++) {
      children.add(widgets[i]);
      if (i < widgets.length - 1) {
        // If next is tags, use tagsSpacer
        if (widgets[i + 1] is Flexible) {
          children.add(tagsSpacer);
        } else {
          children.add(separator);
        }
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Builder(
                  builder: (context) {
                    final regularStyle = theme.textTheme.bodySmall;
                    final timestampStyle = regularStyle?.copyWith(
                      fontSize: (regularStyle.fontSize ?? 12.0) + 1.0,
                    );
                    final separator = Text(' • ', style: regularStyle);
                    final tagsSpacer = Text(' ', style: regularStyle);
                    final metadataWidgets = _buildMetadata(
                      context,
                      regularStyle,
                      timestampStyle,
                    );
                    return _joinWithSeparator(
                      metadataWidgets,
                      separator,
                      tagsSpacer,
                    );
                  },
                ),
                if ((entry.imageUrl != null && entry.imageUrl!.isNotEmpty) ||
                    (entry.localImagePath != null &&
                        entry.localImagePath!.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        minWidth: double.infinity,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child:
                            entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: entry.imageUrl!,
                                    key: ValueKey(entry.imageUrl!),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  )
                                : Image.file(
                                    File(entry.localImagePath!),
                                    key: ValueKey(entry.localImagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      BuildContext context,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) {
                                      return Container(
                                        height: 100,
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
