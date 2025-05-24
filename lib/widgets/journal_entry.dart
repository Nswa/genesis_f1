import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/entry.dart';
import '../utils/text_scale_controller.dart';
import 'custom_image_viewer.dart';

class JournalEntryWidget extends StatefulWidget {
  final Entry entry;
  final void Function(Entry) onToggleFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onInsight;
  final bool Function()? isSelectionMode;
  final VoidCallback? onToggleSelection;

  const JournalEntryWidget({
    super.key,
    required this.entry,
    required this.onToggleFavorite,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onInsight,
    this.isSelectionMode,
    this.onToggleSelection,
  });

  @override
  State<JournalEntryWidget> createState() => _JournalEntryWidgetState();
}

class _JournalEntryWidgetState extends State<JournalEntryWidget> {
  double _baseScale = 1.0;
  late ScrollController _tagsScrollController;
  bool _showStartFade = false;
  Offset? _lastFocalPoint;
  RenderBox? _widgetRenderBox;

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = TextScaleController.instance.scale.value;
    _lastFocalPoint = details.focalPoint;
    // Capture the render box for position calculations
    _widgetRenderBox = context.findRenderObject() as RenderBox?;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final newScale = _baseScale * details.scale;
    final oldScale = TextScaleController.instance.scale.value;
    
    // Calculate the focal point relative to the widget
    if (_widgetRenderBox != null && _lastFocalPoint != null) {
      final localFocalPoint = _widgetRenderBox!.globalToLocal(_lastFocalPoint!);
      
      // Set the new scale
      TextScaleController.instance.setScale(newScale);
        // Calculate scroll offset adjustment to keep focal point stable
      final scaleDelta = newScale - oldScale;
      if (scaleDelta.abs() > 0.001) { // Only adjust for meaningful scale changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Adjust scroll position based on focal point to keep it stable
          final scrollController = Scrollable.of(context).widget.controller;
          if (scrollController != null && scrollController.hasClients) {
            final currentOffset = scrollController.offset;
            final focalRatio = localFocalPoint.dy / (_widgetRenderBox!.size.height);
            final offsetAdjustment = focalRatio * 50 * scaleDelta; // Adjust multiplier as needed
            
            final newOffset = currentOffset + offsetAdjustment;
            scrollController.animateTo(
              newOffset,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } else {
      // Fallback to simple scaling
      TextScaleController.instance.setScale(newScale);
    }
  }

  void _onTagsScroll() {
    if (_tagsScrollController.hasClients) {
      setState(() {
        _showStartFade = _tagsScrollController.offset > 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tagsScrollController = ScrollController();
    _tagsScrollController.addListener(_onTagsScroll);
    TextScaleController.instance.scale.addListener(_onScaleChanged);
  }

  @override
  void dispose() {
    _tagsScrollController.removeListener(_onTagsScroll);
    _tagsScrollController.dispose();
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
      children: [        SingleChildScrollView(
          controller: _tagsScrollController,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              widget.entry.tags.join(" "),
              style: style,
              softWrap: false,
              maxLines: 1,
            ),
          ),
        ),
        // Start fade (only when scrolled)
        if (_showStartFade)
          Positioned(
            left: 0,
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
                      backgroundColor,
                      backgroundColor.withOpacity(0.9),
                      backgroundColor.withOpacity(0.6),
                      backgroundColor.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
        // End fade (always visible)
        Positioned(
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
  void _showImageViewer(BuildContext context) {
    ImageProvider? imageProvider;
    String? heroTag;
    
    if (widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) {
      // Use network image for Firebase stored images
      imageProvider = CachedNetworkImageProvider(widget.entry.imageUrl!);
      heroTag = 'entry_image_${widget.entry.localId}_${widget.entry.imageUrl!}';
    } else if (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty) {
      // Use file image for local images
      imageProvider = FileImage(File(widget.entry.localImagePath!));
      heroTag = 'entry_image_${widget.entry.localId}_${widget.entry.localImagePath!}';
    }
    
    if (imageProvider != null) {
      showCustomImageViewer(
        context, 
        imageProvider,
        heroTag: heroTag,
      );
    }
  }  void _showContextMenu(BuildContext context, TapDownDetails details) {
    // If in selection mode, toggle selection instead of showing context menu
    if (widget.isSelectionMode?.call() == true) {
      widget.onToggleSelection?.call();
      return;
    }

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        details.globalPosition,
        details.globalPosition,
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'insight',
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insight',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 12),
              Text(
                'Edit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'insight':
            widget.onInsight?.call();
            break;
          case 'edit':
            widget.onEdit?.call();
            break;
          case 'delete':
            widget.onDelete?.call();
            break;
        }
      }
    });
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
        ).animate(widget.entry.animController),        child: GestureDetector(
          onTapDown: (details) => _showContextMenu(context, details),
          onLongPress: widget.onLongPress,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          behavior: HitTestBehavior.opaque, // Improve hit detection
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
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
                ),                if ((widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) ||
                    (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 2.5),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200 * TextScaleController.instance.scale.value,
                        minWidth: double.infinity,
                      ),                      child: GestureDetector(
                        onTap: () => _showImageViewer(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Hero(
                            tag: widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
                                ? 'entry_image_${widget.entry.localId}_${widget.entry.imageUrl!}'
                                : 'entry_image_${widget.entry.localId}_${widget.entry.localImagePath!}',
                            child: widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
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
                    ),                  ),
                const SizedBox(height: 3),
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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onToggleFavorite(widget.entry),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
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
                ),                // Add a thin separator between entries
                Container(
                  height: 0.5,
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8.0),
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
