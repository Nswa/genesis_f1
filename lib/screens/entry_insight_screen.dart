import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/entry.dart';
import '../controller/journal_controller.dart';
import '../services/deepseek_service.dart';
import '../widgets/indeterminate_progress_bar.dart';

class EntryInsightScreen extends StatefulWidget {
  final Entry entry;
  final JournalController journalController;

  const EntryInsightScreen({
    super.key, 
    required this.entry,
    required this.journalController,
  });

  @override
  State<EntryInsightScreen> createState() => _EntryInsightScreenState();
}

class _EntryInsightScreenState extends State<EntryInsightScreen> {
  late List<Entry> relatedEntries = [];
  bool isLoading = true;
  String _briefInsight = '';
  bool _loadingInsight = true;
  final DeepseekService _deepseekService = DeepseekService();

  // Static cache for insights and related entry IDs
  static final Map<String, String> _insightCache = {};
  static final Map<String, List<String>> _relatedIdsCache = {};

  // AnimatedList key for related entries
  final GlobalKey<AnimatedListState> _relatedListKey = GlobalKey<AnimatedListState>();

  // For animated headers
  final ValueNotifier<int> _relatedDots = ValueNotifier<int>(0);
  final ValueNotifier<int> _insightDots = ValueNotifier<int>(0);
  bool _fetchingRelated = false;
  bool _generatingInsight = false;
  Timer? _relatedTimer;
  Timer? _insightTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startPhasedLoading();
  }

  @override
  void dispose() {
    _relatedTimer?.cancel();
    _insightTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPhasedLoading({bool forceRefresh = false}) async {
    setState(() {
      isLoading = false;
      relatedEntries = [];
      _briefInsight = '';
      _loadingInsight = true;
      _fetchingRelated = true;
      _generatingInsight = false;
    });
    final entryId = widget.entry.localId;
    final allEntries = widget.journalController.entries;
    // --- Caching logic ---
    if (!forceRefresh && entryId != null && _insightCache.containsKey(entryId) && _relatedIdsCache.containsKey(entryId)) {
      // Use cached related entries
      final related = allEntries.where((e) => _relatedIdsCache[entryId]!.contains(e.localId)).toList();
      setState(() {
        relatedEntries = related;
        _briefInsight = _insightCache[entryId]!;
        _loadingInsight = false;
        _fetchingRelated = false;
        _generatingInsight = false;
      });
      // Scroll to bottom after build
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      return;
    }
    // --- Animated header for related entries ---
    _relatedDots.value = 0;
    _relatedTimer?.cancel();
    _relatedTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_fetchingRelated) _relatedDots.value = (_relatedDots.value + 1) % 4;
    });
    // 2. List related entries one by one, with animation
    List<Entry> related = [];
    if (_relatedListKey.currentState != null) {
      final len = relatedEntries.length;
      for (int i = len - 1; i >= 0; i--) {
        _relatedListKey.currentState!.removeItem(i, (context, animation) => const SizedBox());
      }
    }
    if (!forceRefresh && entryId != null && _relatedIdsCache.containsKey(entryId)) {
      for (final id in _relatedIdsCache[entryId]!) {
        final matches = allEntries.where((e) => e.localId == id);
        if (matches.isEmpty) continue;
        final match = matches.first;
        related.add(match);
        setState(() { relatedEntries = List.from(related); });
        if (_relatedListKey.currentState != null) {
          _relatedListKey.currentState!.insertItem(related.length - 1);
        }
        await Future.delayed(const Duration(milliseconds: 120));
        _scrollToBottom();
      }
    } else {
      final fetched = await _deepseekService.fetchRelatedEntriesFromDeepseek(widget.entry, allEntries);
      for (final e in fetched) {
        related.add(e);
        setState(() { relatedEntries = List.from(related); });
        if (_relatedListKey.currentState != null) {
          _relatedListKey.currentState!.insertItem(related.length - 1);
        }
        await Future.delayed(const Duration(milliseconds: 120));
        _scrollToBottom();
      }
      if (entryId != null) {
        _relatedIdsCache[entryId] = related.map((e) => e.localId ?? '').where((id) => id.isNotEmpty).toList();
      }
    }
    setState(() { _fetchingRelated = false; });
    _relatedTimer?.cancel();
    // 3. Show animated header before streaming insight
    setState(() { _briefInsight = ''; _loadingInsight = true; _generatingInsight = true; });
    _insightDots.value = 0;
    _insightTimer?.cancel();
    _insightTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_generatingInsight) _insightDots.value = (_insightDots.value + 1) % 4;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    // 4. Stream insight generation
    await for (final chunk in _streamInsight(widget.entry, related)) {
      setState(() { _briefInsight += chunk; });
      _scrollToBottom(); // Always scroll on new chunk
      await Future.delayed(const Duration(milliseconds: 30));
    }
    setState(() { _loadingInsight = false; _generatingInsight = false; });
    _insightTimer?.cancel();
    if (entryId != null) {
      _insightCache[entryId] = _briefInsight;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Use true streaming from DeepSeek
  Stream<String> _streamInsight(Entry entry, List<Entry> related) async* {
    await for (final chunk in _deepseekService.streamBriefInsight(entry, related)) {
      yield chunk;
    }
  }

  Future<void> _refresh() async {
    await _startPhasedLoading(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCursor = _loadingInsight && _briefInsight.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Insight'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.only(top: 64.0),
              child: Center(
                child: IndeterminateProgressBar(color: theme.colorScheme.primary),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainEntryCard(theme),
                  const SizedBox(height: 24),
                  // Related Entries Section (always shown)
                  ValueListenableBuilder<int>(
                    valueListenable: _relatedDots,
                    builder: (context, dots, _) {
                      String header;
                      if (_fetchingRelated) {
                        header = 'Fetching related entries' + '.' * dots;
                      } else {
                        header = 'Related Entries';
                      }
                      return Text(header, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
                    },
                  ),
                  const SizedBox(height: 12),
                  relatedEntries.isEmpty
                      ? Text(_fetchingRelated ? '' : 'No related entries found', style: TextStyle(color: theme.hintColor))
                      : AnimatedList(
                          key: _relatedListKey,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          initialItemCount: relatedEntries.length,
                          itemBuilder: (context, index, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: _buildRelatedEntryCard(relatedEntries[index], theme),
                            );
                          },
                        ),
                  if (!_fetchingRelated) ...[
                    const SizedBox(height: 24),
                    // Insight Section
                    ValueListenableBuilder<int>(
                      valueListenable: _insightDots,
                      builder: (context, dots, _) {
                        String header;
                        if (_generatingInsight && _briefInsight.isEmpty) {
                          header = 'Generating insight' + '.' * dots;
                        } else {
                          header = 'Insight';
                        }
                        return Text(header, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
                      },
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _briefInsight.isEmpty && _loadingInsight
                            ? const SizedBox(height: 24) // Empty space while waiting for stream
                            : Stack(
                                children: [
                                  MarkdownBody(
                                    data: _briefInsight,
                                    styleSheet: MarkdownStyleSheet(
                                      p: theme.textTheme.bodySmall?.copyWith(
                                        fontFamily: 'IBMPlexSans',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (showCursor)
                                    Positioned(
                                      left: _calculateCursorOffset(_briefInsight, theme),
                                      bottom: 8,
                                      child: _BlinkingCursor(),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // Helper to estimate cursor offset (optional, can be improved for perfect placement)
  double _calculateCursorOffset(String text, ThemeData theme) {
    // This is a rough estimate; for perfect placement, use a TextPainter
    final avgCharWidth = 8.0;
    return (text.length * avgCharWidth) % 400;
  }

  Widget _buildMainEntryCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and metadata
            Row(
              children: [
                Text(
                  widget.entry.timestamp,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.entry.mood != null && widget.entry.mood!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(widget.entry.mood!, style: theme.textTheme.bodySmall),
                ],
                const Spacer(),
                Icon(
                  widget.entry.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                  color: widget.entry.isFavorite ? Colors.amber : theme.iconTheme.color,
                  size: 20,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Image if exists
            if ((widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) ||
                (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    minWidth: double.infinity,
                  ),
                  child: widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.entry.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) {
                            final isDark = theme.brightness == Brightness.dark;
                            final baseColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;
                            final highlightColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;

                            return Shimmer.fromColors(
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        )
                      : Image.file(
                          File(widget.entry.localImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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
            
            if ((widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) ||
                (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty))
              const SizedBox(height: 12),
            
            // Entry text
            Text(
              widget.entry.text,
              style: theme.textTheme.bodyLarge,
            ),
            
            const SizedBox(height: 8),
            
            // Tags
            if (widget.entry.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: widget.entry.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    labelStyle: theme.textTheme.bodySmall,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedEntryCard(Entry entry, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntryInsightScreen(
                entry: entry,
                journalController: widget.journalController,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and relation type
              Row(
                children: [
                  Text(
                    entry.timestamp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.entry.tags.any((tag) => entry.tags.contains(tag)))
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: theme.hintColor,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Preview of text (limit length)
              Text(
                entry.text.length > 120 
                    ? '${entry.text.substring(0, 120)}...' 
                    : entry.text,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text('|', style: TextStyle(fontSize: 16, fontFamily: 'IBMPlexSans', color: Theme.of(context).colorScheme.primary)),
    );
  }
}
