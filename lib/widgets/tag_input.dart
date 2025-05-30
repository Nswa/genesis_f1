import 'package:flutter/material.dart';
import '../controller/journal_controller.dart';
import '../services/deepseek_service.dart';

class TagInputWidget extends StatefulWidget {
  final JournalController journalController;
  final Function(List<String>) onTagsChanged;

  const TagInputWidget({
    super.key,
    required this.journalController,
    required this.onTagsChanged,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  List<String> _currentTags = [];
  List<String> _suggestedTags = [];
  bool _showSuggestions = false;
  bool _showInputField = false; // Add explicit state for input field visibility
  final DeepseekService _deepseekService = DeepseekService();

  @override
  void initState() {
    super.initState();
    _currentTags = List.from(widget.journalController.manualTags);
    _tagController.addListener(_onTagInputChanged);
    _tagFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _onTagInputChanged() {
    final input = _tagController.text.trim();
    if (input.isNotEmpty && input.length >= 2) {
      _generateTagSuggestions(input);
    } else {
      setState(() {
        _showSuggestions = false;
        _suggestedTags.clear();
      });
    }
  }  void _onFocusChanged() {
    setState(() {
      if (!_tagFocusNode.hasFocus) {
        _showSuggestions = false;
        _showInputField = false; // Hide input field when focus is lost
      }
    });
  }
  void _generateTagSuggestions(String input) {
    // Get suggestions from existing tags in all entries
    final existingTags = <String>{};
    for (final entry in widget.journalController.entries) {
      existingTags.addAll(entry.tags);
    }

    // Filter suggestions based on input
    final suggestions = existingTags
        .where((tag) => 
            tag.toLowerCase().contains(input.toLowerCase()) &&
            !_currentTags.contains(tag))
        .take(5)
        .toList();

    // Add some common tag suggestions if input is short
    if (input.length <= 3) {
      final commonTags = ['#work', '#personal', '#travel', '#family', '#goals', '#health', '#thoughts', '#memories'];
      suggestions.addAll(
        commonTags
            .where((tag) => 
                tag.toLowerCase().contains(input.toLowerCase()) &&
                !_currentTags.contains(tag) &&
                !suggestions.contains(tag))
            .take(3)
      );
    }

    setState(() {
      _suggestedTags = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _getAISuggestions() async {
    final text = widget.journalController.controller.text.trim();
    if (text.isEmpty) return;

    try {
      final existingTags = <String>{};
      for (final entry in widget.journalController.entries) {
        existingTags.addAll(entry.tags);
      }

      final aiSuggestions = await _deepseekService.suggestTags(text, existingTags.toList());
      
      // Filter out tags that are already added
      final filteredSuggestions = aiSuggestions
          .where((tag) => !_currentTags.contains(tag))
          .toList();

      setState(() {
        _suggestedTags = filteredSuggestions;
        _showSuggestions = filteredSuggestions.isNotEmpty;
      });
    } catch (e) {
      // Fallback to manual suggestions if AI fails
      _generateTagSuggestions('');
    }
  }
  void _addTag(String tag) {
    print('Debug: _addTag called with: "$tag"');
    if (tag.isEmpty) {
      print('Debug: Tag is empty, returning');
      return;
    }
    
    // Clean and format the tag
    String cleanTag = tag.trim();
    if (!cleanTag.startsWith('#')) {
      cleanTag = '#$cleanTag';
    }
    
    // Remove any extra # symbols
    cleanTag = cleanTag.replaceAll(RegExp(r'#+'), '#');
    print('Debug: Clean tag: "$cleanTag"');
      if (!_currentTags.contains(cleanTag) && cleanTag.length > 1) {
      print('Debug: Adding tag to list: $_currentTags');
      setState(() {
        _currentTags.add(cleanTag);
        _tagController.clear();
        _showSuggestions = false;
        _suggestedTags.clear();
        _showInputField = false; // Hide input field after adding tag
      });
      print('Debug: Updated tags: $_currentTags');
      widget.onTagsChanged(_currentTags);
    } else {
      print('Debug: Tag not added - already exists or too short');
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _currentTags.remove(tag);
    });
    widget.onTagsChanged(_currentTags);
  }  void _onAddButtonPressed() {
    print('Debug: Add button pressed');
    final input = _tagController.text.trim();
    print('Debug: Input text: "$input"');
    
    if (input.isNotEmpty) {
      print('Debug: Adding tag: $input');
      _addTag(input);
    } else {
      print('Debug: Input empty, showing input field and requesting focus');
      setState(() {
        _showInputField = true;
      });
      // Request focus after the widget is rebuilt
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tagFocusNode.requestFocus();
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print('Debug: TagInputWidget build called. Current tags: $_currentTags');    return Container(
      // Add a background for visibility during debugging
      // decoration: BoxDecoration(
      //   border: Border.all(color: Colors.green, width: 1),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [// Tags display and add button row
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Display current tags
                  ..._currentTags.map((tag) => _buildTagChip(tag, theme)),
                  // Add tag button/input
                  _buildAddTagButton(theme),
                ],
              ),
            ),
            // AI suggestion button
            if (widget.journalController.controller.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: _getAISuggestions,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Suggestions dropdown
        if (_showSuggestions && _suggestedTags.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggestions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _suggestedTags.map((tag) => 
                    GestureDetector(
                      onTap: () => _addTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),          ),
      ],
    ),
    );
  }

  Widget _buildTagChip(String tag, ThemeData theme) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }  Widget _buildAddTagButton(ThemeData theme) {
    print('Debug: _buildAddTagButton called. showInputField: $_showInputField, hasFocus: ${_tagFocusNode.hasFocus}');
    return SizedBox(
      height: 28,
      child: _showInputField 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _tagController,
                  focusNode: _tagFocusNode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: '#tag',
                    hintStyle: TextStyle(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    print('Debug: TextField onSubmitted: $value');
                    _addTag(value);
                  },
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  print('Debug: Check button tapped');
                  _onAddButtonPressed();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )        : InkWell(
            onTap: () {
              print('Debug: Add tag button tapped (InkWell)');
              print('Debug: About to show input field and request focus');
              setState(() {
                _showInputField = true;
              });
              // Request focus after the widget is rebuilt
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _tagFocusNode.requestFocus();
                print('Debug: Focus requested in post frame callback');
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add tag',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
