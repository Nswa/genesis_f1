import 'dart:async';
import 'package:flutter/material.dart';
import '../controller/journal_controller.dart';
import '../services/analytics_service.dart';
import '../utils/system_ui_helper.dart';
import '../widgets/analytics_topic_card.dart';
import '../widgets/analytics_calendar_view.dart';
import '../widgets/analytics_insights_panel.dart';

class AnalyticsScreen extends StatefulWidget {
  final JournalController journalController;

  const AnalyticsScreen({super.key, required this.journalController});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late final AnalyticsService _analyticsService;
  
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  String _analysisProgress = '';
  List<TopicCluster> _topics = [];
  TopicCluster? _selectedTopic;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Start analysis immediately
    _startAnalysis();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    if (_isAnalyzing) return;
    setState(() {
      _isAnalyzing = true;
      _hasAnalyzed = false;
      _analysisProgress = 'Preparing your journey insights...';
    });

    try {
      // Get all entries for analysis
      final entries = widget.journalController.entries;
      debugPrint('[AnalyticsScreen] Number of entries received: \\${entries.length}');

      if (entries.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _hasAnalyzed = true;
          _analysisProgress = 'No entries found to analyze';
        });
        return;
      }
      // Start the analysis with progress updates
      _analyticsService.analysisProgress.listen((progress) {
        if (mounted) {
          setState(() {
            _analysisProgress = progress.message;
          });
        }
      });

      final topics = await _analyticsService.analyzeTopics(entries);
      debugPrint('[AnalyticsScreen] Number of topics returned: \\${topics.length}');

      setState(() {
        _topics = topics;
        _isAnalyzing = false;
        _hasAnalyzed = true;
      });

      // Animate in the results
      _fadeController.forward();

    } catch (e) {
      debugPrint('Analytics error: $e');
      setState(() {
        _isAnalyzing = false;
        _hasAnalyzed = true;
        _analysisProgress = 'Analysis failed. Please try again.';
      });
    }
  }

  void _selectTopic(TopicCluster topic) {
    setState(() {
      _selectedTopic = topic;
    });
    _slideController.forward();
  }

  void _goBackToTopics() {
    _slideController.reverse().then((_) {
      setState(() {
        _selectedTopic = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme),
            
            // Content
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Text(
            _selectedTopic != null ? _selectedTopic!.name : 'Journey Analytics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          if (_selectedTopic != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _goBackToTopics,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isAnalyzing) {
      return _buildAnalyzingState(theme);
    }
    
    if (!_hasAnalyzed || _topics.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (_selectedTopic != null) {
      return _buildTopicDetailView(theme);
    }
    
    return _buildTopicsOverview(theme);
  }

  Widget _buildAnalyzingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Your Journey',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _analysisProgress,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.hintColor,
          ),
          const SizedBox(height: 24),
          Text(
            'No Insights Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start journaling to discover patterns and insights in your thoughts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsOverview(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have ${_topics.length} ${_topics.length == 1 ? 'topic' : 'topics'} to reflect on',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap a topic to explore your journey',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: AnalyticsTopicCard(
                    topic: topic,
                    onTap: () => _selectTopic(topic),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicDetailView(ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Column(
        children: [
          // Calendar View
          Expanded(
            flex: 2,
            child: AnalyticsCalendarView(
              topic: _selectedTopic!,
              journalController: widget.journalController,
            ),
          ),
          
          // Insights Panel
          Expanded(
            flex: 3,
            child: AnalyticsInsightsPanel(
              topic: _selectedTopic!,
              journalController: widget.journalController,
            ),
          ),
        ],
      ),
    );
  }
}
