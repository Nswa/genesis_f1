import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../controller/journal_controller.dart';
import '../models/entry.dart';

class AnalyticsCalendarView extends StatefulWidget {
  final TopicCluster topic;
  final JournalController journalController;

  const AnalyticsCalendarView({
    super.key,
    required this.topic,
    required this.journalController,
  });

  @override
  State<AnalyticsCalendarView> createState() => _AnalyticsCalendarViewState();
}

class _AnalyticsCalendarViewState extends State<AnalyticsCalendarView> {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Set initial year to the year with the most entries
    _selectedYear = _getMostActiveYear();
  }

  int _getMostActiveYear() {
    final yearCounts = <int, int>{};
    for (final entry in widget.topic.entries) {
      final year = entry.rawDateTime.year;
      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }
    
    if (yearCounts.isEmpty) return DateTime.now().year;
    
    return yearCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Map<int, List<Entry>> _getEntriesByMonth() {
    final monthlyEntries = <int, List<Entry>>{};
    
    for (final entry in widget.topic.entries) {
      if (entry.rawDateTime.year == _selectedYear) {
        final month = entry.rawDateTime.month;
        monthlyEntries.putIfAbsent(month, () => []).add(entry);
      }
    }
    
    return monthlyEntries;
  }

  List<int> _getAvailableYears() {
    final years = widget.topic.entries
        .map((e) => e.rawDateTime.year)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a)); // Recent years first
    return years;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthlyEntries = _getEntriesByMonth();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with year selector
          Row(
            children: [
              Text(
                'Journey Timeline',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildYearSelector(theme),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Calendar grid
          Expanded(
            child: _buildCalendarGrid(theme, monthlyEntries),
          ),
          
          // Legend
          _buildLegend(theme),
        ],
      ),
    );
  }

  Widget _buildYearSelector(ThemeData theme) {
    final availableYears = _getAvailableYears();
    
    if (availableYears.length <= 1) {
      return Text(
        _selectedYear.toString(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      );
    }
    
    return DropdownButton<int>(
      value: _selectedYear,
      items: availableYears.map((year) {
        return DropdownMenuItem(
          value: year,
          child: Text(year.toString()),
        );
      }).toList(),
      onChanged: (year) {
        if (year != null) {
          setState(() {
            _selectedYear = year;
            _selectedMonth = null;
          });
        }
      },
      underline: const SizedBox(),
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, Map<int, List<Entry>> monthlyEntries) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final entries = monthlyEntries[month] ?? [];
        final hasEntries = entries.isNotEmpty;
        final isSelected = _selectedMonth == month;
        
        return _buildMonthCard(
          theme,
          monthNames[index],
          month,
          entries,
          hasEntries,
          isSelected,
        );
      },
    );
  }

  Widget _buildMonthCard(
    ThemeData theme,
    String monthName,
    int month,
    List<Entry> entries,
    bool hasEntries,
    bool isSelected,
  ) {
    final entryCount = entries.length;
    final intensity = hasEntries ? (entryCount / 10).clamp(0.2, 1.0) : 0.0;
    
    return GestureDetector(
      onTap: hasEntries ? () => _selectMonth(month, entries) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasEntries
              ? theme.primaryColor.withOpacity(0.1 + (intensity * 0.2))
              : theme.cardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : hasEntries
                    ? theme.primaryColor.withOpacity(0.3)
                    : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Month content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasEntries 
                          ? theme.textTheme.titleSmall?.color
                          : theme.hintColor,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (hasEntries) ...[
                    Row(
                      children: [
                        ...List.generate(
                          (entryCount / 2).ceil().clamp(1, 5),
                          (index) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(
                                0.4 + (intensity * 0.6),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 10,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'No entries',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            'Tap a month to explore entries',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'Less',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(4, (index) {
                final opacity = 0.2 + (index * 0.2);
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                'More',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectMonth(int month, List<Entry> entries) {
    setState(() {
      _selectedMonth = _selectedMonth == month ? null : month;
    });
    
    // TODO: This will trigger the insights panel to update
    // We'll need to pass this selection up to the parent
  }
}
