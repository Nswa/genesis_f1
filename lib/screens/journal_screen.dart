// import 'dart:ui'; // Unnecessary import
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:genesis_f1/widgets/calendar_modal.dart';
// import 'package:shimmer/shimmer.dart'; // No longer needed here
import '../widgets/edge_fade.dart';
import '../widgets/shimmer_sliver.dart';
import '../widgets/indeterminate_progress_bar.dart'; // Import new progress bar

import '../widgets/journal_input.dart';
import '../widgets/journal_entry.dart';
import '../widgets/journal_toolbar.dart';
import '../widgets/journal_selection_toolbar.dart'; // Added import
import '../controller/journal_controller.dart';
import '../utils/system_ui_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    final background = Theme.of(context).scaffoldBackgroundColor;
    final grouped = jc.groupEntriesByDate(jc.entries);

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
                            ? List.generate(5, (_) => const ShimmerSliver())
                                .toList() // Use new widget
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
                                        onToggleFavorite:
                                            jc.toggleFavorite, // Pass the controller's method
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
                EdgeFade(top: true, background: background), // Use new widget
                EdgeFade(top: false, background: background), // Use new widget
              ],
            ),
          ),
          GestureDetector(
            onVerticalDragUpdate: jc.handleDragUpdate,
            onVerticalDragEnd: (_) => jc.handleDragEnd(),
            child: JournalInputWidget(
              journalController: jc, // Pass the full controller instance
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: background.withAlpha(24),
            alignment: Alignment.centerLeft,
            child:
                jc.isSavingEntry
                    ? IndeterminateProgressBar(
                      color: Theme.of(context).hintColor,
                      height: 1.5, // Match thickness
                    )
                    : FractionallySizedBox(
                      widthFactor: (-jc.dragOffsetY / jc.swipeThreshold).clamp(
                        0.0,
                        1.0,
                      ),
                      child: Container(
                        height: 1, // Original height for drag progress
                        color: Theme.of(context).hintColor,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
