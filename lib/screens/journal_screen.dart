import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:genesis_f1/widgets/calendar_modal.dart';

import '../widgets/journal_input.dart';
import '../widgets/journal_entry.dart';
import '../widgets/journal_entry_shimmer.dart';
import '../widgets/journal_toolbar.dart';
import '../widgets/journal_selection_toolbar.dart'; // Added import
import '../controller/journal_controller.dart';
import '../models/entry.dart';
import '../utils/system_ui_helper.dart';
import '../utils/date_formatter.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  late final JournalController jc;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    jc = JournalController(
      vsync: this,
      onUpdate: () => setState(() {}),
      scrollController: scrollController,
    );
    jc.loadEntriesFromFirestore();
  }

  @override
  void dispose() {
    jc.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Map<String, List<Entry>> groupEntriesByDate(List<Entry> entries) {
    final Map<String, List<Entry>> map = {};
    for (var e in entries) {
      final dateStr = DateFormatter.formatForGrouping(e.rawDateTime);
      map.putIfAbsent(dateStr, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    final background = Theme.of(context).scaffoldBackgroundColor;
    final grouped = groupEntriesByDate(jc.entries);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child:
                jc.isSelectionMode
                    ? JournalSelectionToolbar(
                      selectedCount: jc.selectedEntries.length,
                      onClearSelection:
                          () => setState(() => jc.clearSelection()),
                      onDeleteSelected: () async {
                        await jc.deleteSelectedEntries();
                        // setState is called by jc.onUpdate via deleteSelectedEntries
                      },
                    )
                    : JournalToolbar(
                      onSearch: () {},
                      onToggleFavorites: () {},
                      onOpenSettings: () {},
                      onOpenDatePicker: () {
                        showCalendarModal(
                          context,
                          jc.entries,
                          scrollController,
                        );
                      },
                    ),
          ),
          Expanded(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: CustomScrollView(
                    key: ValueKey(jc.isLoading),
                    controller: scrollController,
                    slivers:
                        jc.isLoading
                            ? List.generate(5, (_) => _shimmerSliver()).toList()
                            : grouped.entries.map((entryGroup) {
                              return SliverStickyHeader(
                                header: GestureDetector(
                                  onLongPress: () {
                                    jc.selectEntriesByDate(entryGroup.value);
                                  },
                                  onTap: () {
                                    // Added onTap for deselection
                                    if (jc.isSelectionMode) {
                                      jc.deselectEntriesByDate(
                                        entryGroup.value,
                                      );
                                    }
                                  },
                                  child: Container(
                                    color:
                                        background, // Ensure background for tap area
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8, // Reduced top padding
                                      0,
                                      4, // Reduced bottom padding
                                    ),
                                    child: Text(
                                      entryGroup.key,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).hintColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                sliver: SliverAnimatedList(
                                  key: GlobalKey<SliverAnimatedListState>(),
                                  initialItemCount: entryGroup.value.length,
                                  itemBuilder: (context, index, animation) {
                                    return SizeTransition(
                                      sizeFactor: animation,
                                      axisAlignment: 0.0,
                                      child: JournalEntryWidget(
                                        entry: entryGroup.value[index],
                                        onToggleFavorite: () {
                                          // TODO: Handle favorite toggle in selection mode?
                                          if (!jc.isSelectionMode) {
                                            setState(() {
                                              entryGroup
                                                  .value[index]
                                                  .isFavorite = !entryGroup
                                                      .value[index]
                                                      .isFavorite;
                                            });
                                          }
                                        },
                                        onTap: () {
                                          if (jc.isSelectionMode) {
                                            setState(
                                              () => jc.toggleEntrySelection(
                                                entryGroup.value[index],
                                              ),
                                            );
                                          } else {
                                            // Optional: Handle tap when not in selection mode
                                          }
                                        },
                                        onLongPress: () {
                                          setState(
                                            () => jc.toggleEntrySelection(
                                              entryGroup.value[index],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                  ),
                ),
                _buildEdgeFade(top: true, background: background),
                _buildEdgeFade(top: false, background: background),
              ],
            ),
          ),
          GestureDetector(
            onVerticalDragUpdate: jc.handleDragUpdate,
            onVerticalDragEnd: (_) => jc.handleDragEnd(),
            child: JournalInputWidget(
              journalController: jc, // Pass the full controller instance
              // controller: jc.controller, // No longer passed directly
              // focusNode: jc.focusNode, // No longer passed directly
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
            color: background.withAlpha(24),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (-jc.dragOffsetY / jc.swipeThreshold).clamp(
                0.0,
                1.0,
              ),
              child: Container(height: 1, color: Theme.of(context).hintColor),
            ),
          ),
        ],
      ),
    );
  }

  SliverStickyHeader _shimmerSliver() => SliverStickyHeader(
    header: Container(height: 32, color: Colors.transparent),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, __) => const JournalEntryShimmer(),
        childCount: 1,
      ),
    ),
  );

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
              colors: [background, background.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }
}
