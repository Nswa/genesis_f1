import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/entry.dart';
import '../utils/text_scale_controller.dart';

class JournalEntryWidget extends StatefulWidget {
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
  State<JournalEntryWidget> createState() => _JournalEntryWidgetState();
}

class _JournalEntryWidgetState extends State<JournalEntryWidget> {
  double _baseScale = 1.0;

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = TextScaleController.instance.scale.value;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    TextScaleController.instance.setScale(_baseScale * details.scale);
  }

  @override
  void initState() {
    super.initState();
    TextScaleController.instance.scale.addListener(_onScaleChanged);
  }

  @override
  void dispose() {
    TextScaleController.instance.scale.removeListener(_onScaleChanged);
    super.dispose();
  }

  void _onScaleChanged() {
    setState(() {}); // Rebuild on global scale change
  }  Widget _buildTagsBar(BuildContext context, TextStyle? style) {
    final theme = Theme.of(context);
    // When selected, blend the highlight color with the scaffold background
    // to match the actual visual appearance
    final backgroundColor = widget.entry.isSelected 
        ? Color.alphaBlend(theme.highlightColor, theme.scaffoldBackgroundColor)
        : theme.scaffoldBackgroundColor;
    
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              widget.entry.tags.join(" "),
              style: style,
              softWrap: false,
              maxLines: 1,
            ),
          ),
        ),        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 16,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    backgroundColor.withOpacity(0.0),
                    backgroundColor.withOpacity(0.6),
                    backgroundColor.withOpacity(0.9),
                    backgroundColor,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
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
      Text(widget.entry.timestamp, style: timestampStyle),
      widget.entry.mood?.isNotEmpty == true
          ? Text(widget.entry.mood!, style: regularStyle)
          : null,
      widget.entry.tags.isNotEmpty
          ? Flexible(child: _buildTagsBar(context, regularStyle))
          : null,
      widget.entry.wordCount > 0
          ? Text('${widget.entry.wordCount} words', style: regularStyle)
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
        parent: widget.entry.animController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(widget.entry.animController),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          behavior: HitTestBehavior.opaque, // Improve hit detection
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: widget.entry.isSelected
                  ? theme.highlightColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                widget.entry.isSelected ? 6.0 : 0.0,
              ),
            ),
            transform: Matrix4.identity()..scale(
              widget.entry.isSelected ? 0.97 : 1.0,
            ),
            transformAlignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final scale = TextScaleController.instance.scale.value;
                    final regularStyle = theme.textTheme.bodySmall?.copyWith(
                      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12.0) * scale,
                    );
                    final timestampStyle = regularStyle?.copyWith(
                      fontSize: ((regularStyle.fontSize ?? 12.0) + 1.0),
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
                if ((widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) ||
                    (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty))
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
                            widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.entry.imageUrl!,
                                    key: ValueKey(widget.entry.imageUrl!),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) {
                                      final theme = Theme.of(context);
                                      final isDark = theme.brightness == Brightness.dark;
                                      final baseColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;
                                      final highlightColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;

                                      return Shimmer.fromColors(
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: baseColor,
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                        ),
                                      );
                                    },
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  )
                                : Image.file(
                                    File(widget.entry.localImagePath!),
                                    key: ValueKey(widget.entry.localImagePath!),
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
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.entry.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14.0) * TextScaleController.instance.scale.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => widget.onToggleFavorite(widget.entry),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          widget.entry.isFavorite
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          size: 18,
                          color: widget.entry.isFavorite
                              ? Colors.amber
                              : theme.iconTheme.color,
                        ),
                      ),
                    ),                  ],
                ),
                // Add a thin separator between entries
                Container(
                  height: 0.5,
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12.0),
                  color: theme.dividerColor.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
