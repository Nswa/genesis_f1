import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/entry.dart';
import '../controller/journal_controller.dart';
import '../services/deepseek_service.dart';

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
  
  // For storing API-generated insights
  String _entryContextInsight = '';
  String _overallInsight = '';
  bool _loadingEntryInsight = true;
  bool _loadingOverallInsight = true;
    // DeepSeek service initialized with embedded API key
  final DeepseekService _deepseekService = DeepseekService();
  
  @override
  void initState() {
    super.initState();
    _loadRelatedEntries();
  }

  Future<void> _loadRelatedEntries() async {
    // Start with loading state
    setState(() {
      isLoading = true;
      _loadingEntryInsight = true;
      _loadingOverallInsight = true;
    });

    // Find related entries based on tags, dates, or content similarity
    final relatedByTags = _findRelatedByTags();
    final relatedByDate = _findRelatedByDate();
    final relatedByContent = _findRelatedByContent();

    // Combine all related entries, remove duplicates and the original entry
    final allRelated = {...relatedByTags, ...relatedByDate, ...relatedByContent}
        .where((e) => e.localId != widget.entry.localId)
        .toList();

    // Sort by relevance or date
    allRelated.sort((a, b) => b.rawDateTime.compareTo(a.rawDateTime));
    
    // Limit to top 5 most relevant
    final limitedRelated = allRelated.take(5).toList();

    setState(() {
      relatedEntries = limitedRelated;
      isLoading = false;
    });
    
    // Once we have related entries, fetch AI insights
    if (limitedRelated.isNotEmpty) {
      // Get entry context insight
      try {
        final contextInsight = await _deepseekService.analyzeEntryContext(
          widget.entry,
          limitedRelated,
        );
        
        setState(() {
          _entryContextInsight = contextInsight;
          _loadingEntryInsight = false;
        });
      } catch (e) {
        setState(() {
          _entryContextInsight = "Unable to generate insights at this time.";
          _loadingEntryInsight = false;
        });
      }
      
      // Get overall insight about all entries together
      try {
        final overallInsight = await _deepseekService.generateOverallInsights(
          widget.entry,
          limitedRelated,
        );
        
        setState(() {
          _overallInsight = overallInsight;
          _loadingOverallInsight = false;
        });
      } catch (e) {
        setState(() {
          _overallInsight = "Unable to generate overall insights at this time.";
          _loadingOverallInsight = false;
        });
      }
    } else {
      setState(() {
        _entryContextInsight = "No related entries found to analyze.";
        _overallInsight = "";
        _loadingEntryInsight = false;
        _loadingOverallInsight = false;
      });
    }
  }

  Set<Entry> _findRelatedByTags() {
    // Find entries that share tags with the current entry
    if (widget.entry.tags.isEmpty) return {};
    
    return widget.journalController.entries
        .where((e) => e.localId != widget.entry.localId &&
            e.tags.any((tag) => widget.entry.tags.contains(tag)))
        .toSet();
  }

  Set<Entry> _findRelatedByDate() {
    // Find entries from the same day or adjacent days
    final targetDate = widget.entry.rawDateTime;
    final sameDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final dayBefore = sameDay.subtract(const Duration(days: 1));
    final dayAfter = sameDay.add(const Duration(days: 1));

    return widget.journalController.entries
        .where((e) {
          final entryDate = DateTime(
            e.rawDateTime.year, 
            e.rawDateTime.month, 
            e.rawDateTime.day
          );
          return e.localId != widget.entry.localId && 
            (entryDate.isAtSameMomentAs(sameDay) ||
             entryDate.isAtSameMomentAs(dayBefore) ||
             entryDate.isAtSameMomentAs(dayAfter));
        })
        .toSet();
  }

  Set<Entry> _findRelatedByContent() {
    // Simple content similarity (check for word overlap)
    if (widget.entry.text.isEmpty) return {};
    
    final mainWords = widget.entry.text
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((word) => word.length > 4) // Only consider substantial words
        .toSet();
    
    if (mainWords.isEmpty) return {};
    
    return widget.journalController.entries
        .where((e) {
          if (e.localId == widget.entry.localId) return false;
          
          final otherWords = e.text
              .toLowerCase()
              .split(RegExp(r'\W+'))
              .where((word) => word.length > 4)
              .toSet();
          
          final commonWords = mainWords.intersection(otherWords);
          // If at least 3 substantial words match
          return commonWords.length >= 3;
        })
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Insight'),
        backgroundColor: background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,          children: [
            // Main Entry Section
            _buildMainEntryCard(theme),
            
            const SizedBox(height: 24),
            
            // Brief Insight Section
            _buildInsightSection(theme),
            
            const SizedBox(height: 24),
            
            // Related Entries Section
            Text(
              'Related Entries',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Related entries list
            isLoading 
                ? const Center(child: CircularProgressIndicator())
                : relatedEntries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No related entries found',
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ),
                      )
                    : Column(
                        children: relatedEntries
                            .map((entry) => _buildRelatedEntryCard(entry, theme))
                            .toList(),
                      ),
            
            // Only show overall insights if we have related entries
            if (relatedEntries.isNotEmpty) ...[
              const SizedBox(height: 32),
              
              // Overall Insights Section
              _buildOverallInsightsSection(theme),
            ],
          ],
        ),
      ),
    );
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
  Widget _buildInsightSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entry Context',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          color: theme.colorScheme.primary.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _loadingEntryInsight
                ? Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analyzing entry...',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic entry information
                      _buildBasicInsights(theme),
                      
                      if (_entryContextInsight.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        // AI-generated insights
                        Text(
                          _entryContextInsight,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInsights(ThemeData theme) {
    final List<Widget> insights = [];
    
    // Mood insight
    if (widget.entry.mood != null && widget.entry.mood!.isNotEmpty) {
      insights.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.mood,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Mood: ${widget.entry.mood}",
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    // Word count insight
    if (widget.entry.wordCount > 0) {
      final String lengthDescription = widget.entry.wordCount > 100 
          ? 'detailed' 
          : widget.entry.wordCount > 50 
              ? 'moderate-length' 
              : 'brief';
              
      insights.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "$lengthDescription entry (${widget.entry.wordCount} words)",
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    // Related entries count
    if (relatedEntries.isNotEmpty) {
      insights.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.connecting_airports,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Found ${relatedEntries.length} related entries",
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights,
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

  Widget _buildOverallInsightsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Insights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          color: theme.colorScheme.primary.withOpacity(0.075),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _loadingOverallInsight
                ? Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analyzing patterns across entries...',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ],
                    ),
                  )
                : Text(
                    _overallInsight,
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ),
      ],
    );
  }
}
