import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/entry.dart';
import '../services/api_key_service.dart';

/// Service for interacting with DeepSeek API to generate intelligent insights
/// about journal entries
class DeepseekService {
  final String _apiKey;
  final String _baseUrl = 'https://api.deepseek.com/v1';

  /// Create a new DeepseekService instance
  DeepseekService() : _apiKey = ApiKeyService.getDeepseekApiKey();

  /// Analyze the contextual relationship between entries
  Future<String> analyzeEntryContext(Entry mainEntry, List<Entry> relatedEntries) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an intelligent journaling assistant that helps analyze journal '
                  'entries. Your task is to provide a brief contextual analysis of how a main '
                  'journal entry relates to other entries. Be concise, insightful, and helpful. '
                  'Focus on themes, emotional patterns, and narrative continuity.'
            },
            {
              'role': 'user',
              'content': _formatEntriesForAnalysis(mainEntry, relatedEntries)
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('DeepSeek API error: ${response.statusCode}, ${response.body}');
        return _generateFallbackEntryContext(mainEntry, relatedEntries);
      }
    } catch (e) {
      debugPrint('Failed to connect to DeepSeek API: $e');
      return _generateFallbackEntryContext(mainEntry, relatedEntries);
    }
  }

  /// Generate overall insights across multiple entries
  Future<String> generateOverallInsights(Entry mainEntry, List<Entry> relatedEntries) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an intelligent journaling assistant that helps users gain '
                  'insights from their journal entries. Your task is to analyze patterns across '
                  'multiple related entries and provide helpful observations about themes, '
                  'emotional patterns, potential growth opportunities, and recurring topics. '
                  'Be concise, thoughtful, and avoid generic responses.'
            },
            {
              'role': 'user',
              'content': _formatEntriesForOverallInsight(mainEntry, relatedEntries)
            }
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('DeepSeek API error: ${response.statusCode}, ${response.body}');
        return _generateFallbackOverallInsights(mainEntry, relatedEntries);
      }
    } catch (e) {
      debugPrint('Failed to connect to DeepSeek API: $e');
      return _generateFallbackOverallInsights(mainEntry, relatedEntries);
    }
  }

  /// Format entries for analyzing contextual relationship
  String _formatEntriesForAnalysis(Entry mainEntry, List<Entry> relatedEntries) {
    final buffer = StringBuffer();

    buffer.writeln('Main Entry (Date: ${mainEntry.timestamp}):');
    buffer.writeln('${mainEntry.text}');
    
    if (mainEntry.mood != null && mainEntry.mood!.isNotEmpty) {
      buffer.writeln('Mood: ${mainEntry.mood}');
    }
    
    if (mainEntry.tags.isNotEmpty) {
      buffer.writeln('Tags: ${mainEntry.tags.join(', ')}');
    }
    
    buffer.writeln('\nRelated Entries:');
    
    for (var entry in relatedEntries) {
      buffer.writeln('Date: ${entry.timestamp}');
      buffer.writeln('${entry.text}');
      
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        buffer.writeln('Mood: ${entry.mood}');
      }
      
      if (entry.tags.isNotEmpty) {
        buffer.writeln('Tags: ${entry.tags.join(', ')}');
      }
      
      buffer.writeln('---');
    }
    
    buffer.writeln('\nPlease provide a brief contextual analysis of how the main entry relates to the related entries. '
        'Focus on themes, emotional patterns, and narrative continuity. Keep it concise (2-3 paragraphs max).');
    
    return buffer.toString();
  }

  /// Format entries for overall insights analysis
  String _formatEntriesForOverallInsight(Entry mainEntry, List<Entry> relatedEntries) {
    final buffer = StringBuffer();
    final allEntries = [mainEntry, ...relatedEntries];
    
    buffer.writeln('Journal Entry Analysis:');
    buffer.writeln('Please analyze the following journal entries and provide insights on themes, patterns, and development.');
    
    for (var entry in allEntries) {
      buffer.writeln('\nDate: ${entry.timestamp}');
      buffer.writeln('${entry.text}');
      
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        buffer.writeln('Mood: ${entry.mood}');
      }
      
      if (entry.tags.isNotEmpty) {
        buffer.writeln('Tags: ${entry.tags.join(', ')}');
      }
      
      buffer.writeln('---');
    }
    
    buffer.writeln('\nPlease provide 3-4 insightful observations about:');
    buffer.writeln('1. Recurring themes or topics');
    buffer.writeln('2. Emotional patterns or development');
    buffer.writeln('3. Potential growth opportunities or areas of focus');
    buffer.writeln('4. Any other notable patterns or connections between these entries');
    
    return buffer.toString();
  }

  /// Generate a fallback context if API call fails
  String _generateFallbackEntryContext(Entry mainEntry, List<Entry> relatedEntries) {
    // Simple fallback algorithm to generate insight without API
    final List<String> insights = [];
    
    // Check for common tags between main entry and related entries
    if (mainEntry.tags.isNotEmpty && relatedEntries.isNotEmpty) {
      final commonTagsEntries = relatedEntries
          .where((e) => e.tags.any((tag) => mainEntry.tags.contains(tag)))
          .toList();
          
      if (commonTagsEntries.isNotEmpty) {
        final commonTags = mainEntry.tags
            .where((tag) => commonTagsEntries
                .any((e) => e.tags.contains(tag)))
            .toList();
            
        if (commonTags.isNotEmpty) {
          insights.add('This entry shares themes with other entries involving: ${commonTags.join(", ")}.');
        }
      }
    }
    
    // Check for date proximity
    final sameDayEntries = relatedEntries
        .where((e) => _isSameDay(e.rawDateTime, mainEntry.rawDateTime))
        .toList();
        
    if (sameDayEntries.isNotEmpty) {
      insights.add('This entry was written on the same day as ${sameDayEntries.length} other entries, suggesting related events or thoughts.');
    }
    
    // Default insight if nothing specific found
    if (insights.isEmpty) {
      insights.add('This entry appears to be part of your ongoing journal narrative.');
      
      if (relatedEntries.isNotEmpty) {
        insights.add('There are ${relatedEntries.length} related entries that provide additional context to this moment in your life.');
      }
    }
    
    return insights.join(' ');
  }

  /// Generate fallback overall insights if API call fails
  String _generateFallbackOverallInsights(Entry mainEntry, List<Entry> relatedEntries) {
    final List<String> insights = [];
    final allEntries = [mainEntry, ...relatedEntries];
    
    // Check for mood patterns
    final moods = allEntries
        .where((e) => e.mood != null && e.mood!.isNotEmpty)
        .map((e) => e.mood!)
        .toList();
        
    if (moods.isNotEmpty) {
      // Simple frequency count
      final moodFrequency = <String, int>{};
      for (final mood in moods) {
        moodFrequency[mood] = (moodFrequency[mood] ?? 0) + 1;
      }
      
      final mostFrequentMood = moodFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
          
      insights.add('Your most frequent mood across these entries was "$mostFrequentMood".');
    }
    
    // Check for common tags
    final allTags = allEntries
        .expand((e) => e.tags)
        .toList();
        
    if (allTags.isNotEmpty) {
      final tagFrequency = <String, int>{};
      for (final tag in allTags) {
        tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
      }
      
      final mostFrequentTags = tagFrequency.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .take(3)
          .toList();
          
      if (mostFrequentTags.isNotEmpty) {
        insights.add('Recurring themes include: ${mostFrequentTags.join(", ")}.');
      }
    }
    
    // Check for time span
    if (relatedEntries.isNotEmpty) {
      final dates = allEntries.map((e) => e.rawDateTime).toList();
      dates.sort();
      
      final firstDate = dates.first;
      final lastDate = dates.last;
      final diffDays = lastDate.difference(firstDate).inDays;
      
      if (diffDays > 0) {
        insights.add('These entries span $diffDays days, showing a period of your journaling experience.');
      } else {
        insights.add('These entries were all written on the same day, representing a snapshot of your thoughts during that time.');
      }
    }
    
    // Default insight
    if (insights.isEmpty) {
      insights.add('These journal entries form part of your ongoing reflection process.');
    }
    
    return insights.join(' ');
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
