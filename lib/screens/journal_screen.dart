import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:genesis_f1/utils/system_ui_helper.dart';
import '../widgets/journal_input.dart';
import '../widgets/journal_entry.dart';
import '../widgets/journal_entry_shimmer.dart';
import '../widgets/journal_toolbar.dart';
import '../controller/journal_controller.dart';
import '../models/entry.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  late final JournalController jc;

  @override
  void initState() {
    super.initState();
    jc = JournalController(vsync: this, onUpdate: () => setState(() {}));
    jc.loadEntriesFromFirestore();
  }

  @override
  void dispose() {
    jc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = theme.scaffoldBackgroundColor;
    final progressBaseColor = isDark ? Colors.black12 : Colors.white12;
    final progressFillColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: JournalToolbar(
              onSearch: () {},
              onToggleFavorites: () {},
              onOpenSettings: () {},
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                jc.isLoading
                    ? ListView.builder(
                      itemCount: 5,
                      itemBuilder: (_, __) => const JournalEntryShimmer(),
                    )
                    : CustomScrollView(slivers: _buildSliverJournal(context)),
                _buildEdgeFade(top: true, background: background),
                _buildEdgeFade(top: false, background: background),
              ],
            ),
          ),
          GestureDetector(
            onVerticalDragUpdate: jc.handleDragUpdate,
            onVerticalDragEnd: (_) => jc.handleDragEnd(),
            child: JournalInputWidget(
              controller: jc.controller,
              focusNode: jc.focusNode,
              dragOffsetY: jc.dragOffsetY,
              isDragging: jc.isDragging,
              swipeThreshold: jc.swipeThreshold,
              onHashtagInsert: jc.insertHashtag,
              handlePulseController: jc.handlePulseController,
              showRipple: jc.showRipple,
              onMoodSelected: (mood) => setState(() => jc.selectedMood = mood),
              selectedMood: jc.selectedMood,
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: progressBaseColor,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (-jc.dragOffsetY / jc.swipeThreshold).clamp(
                0.0,
                1.0,
              ),
              child: Container(height: 1, color: progressFillColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSliverJournal(BuildContext context) {
    final List<Widget> slivers = [];
    final theme = Theme.of(context);

    if (jc.entries.isEmpty) return [];

    final grouped = <DateTime, List<Entry>>{};

    for (final entry in jc.entries) {
      final date = DateTime(
        entry.timestampRaw.year,
        entry.timestampRaw.month,
        entry.timestampRaw.day,
      );
      grouped.putIfAbsent(date, () => []).add(entry);
    }

    grouped.forEach((date, entries) {
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          floating: false, // ensure it's not stacking
          delegate: _DateHeaderDelegate(date: date, theme: theme),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final entry = entries[index];
            return JournalEntryWidget(
              entry: entry,
              onToggleFavorite: () {
                setState(() => entry.isFavorite = !entry.isFavorite);
              },
            );
          }, childCount: entries.length),
        ),
      );
    });

    return slivers;
  }

  Widget _buildEdgeFade({required bool top, required Color background}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: 12,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [background, background.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;
  final ThemeData theme;

  _DateHeaderDelegate({required this.date, required this.theme});

  @override
  double get minExtent => 32;
  @override
  double get maxExtent => 32;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        DateFormat('EEEE, MMMM d').format(date),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.hintColor,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) {
    return date != oldDelegate.date;
  }
}
