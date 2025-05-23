//
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:genesis_f1/widgets/calendar_modal.dart';
import 'favorites_screen.dart';
import 'entry_insight_screen.dart';
import '../widgets/edge_fade.dart';
import '../widgets/shimmer_sliver.dart';
import '../widgets/indeterminate_progress_bar.dart';

import '../widgets/journal_input.dart';
import '../widgets/journal_entry.dart';
import '../widgets/journal_toolbar.dart';
import '../widgets/journal_selection_toolbar.dart';
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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    jc = JournalController(
      vsync: this,
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      }, // Ensure mounted check
      scrollController: scrollController,
    );
    jc.loadEntriesFromFirestore();
    _searchController.addListener(() {
      // Listener to update UI when search text changes
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    jc.dispose();
    scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        jc.updateSearchTerm(''); // Clear search term in controller
      }
    });
  }

  void _onSearchChanged(String query) {
    jc.updateSearchTerm(query);
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    final background = Theme.of(context).scaffoldBackgroundColor;
    // Use filteredEntries for display
    // Ensure grouped entries are ordered with latest date first
    final grouped = jc.groupEntriesByDate(jc.filteredEntries);
    final groupedEntriesDesc = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

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
                      isSearching: _isSearching,
                      onToggleSearch: _toggleSearch,
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      onSearchChanged: _onSearchChanged,
                      syncStatus: jc.syncStatus, // Pass syncStatus
                      onToggleFavorites: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FavoritesScreen(
                                  journalController: jc, // Pass the controller
                                ),
                          ),
                        );
                      },
                      onOpenSettings: () {},
                      onOpenDatePicker: () {
                        showCalendarModal(
                          context,
                          jc.entries, // show all entries in calendar, not filtered
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
                    reverse: true, // Show latest at bottom and scroll there
                    slivers:
                        jc.isLoading
                            ? List.generate(5, (_) => const ShimmerSliver())
                                .toList()
                            : groupedEntriesDesc.map((entryGroup) {
                              return SliverStickyHeader(
                                header: GestureDetector(
                                  onLongPress: () {
                                    jc.selectEntriesByDate(entryGroup.value);
                                  },
                                  onTap: () {
                                    if (jc.isSelectionMode) {
                                      jc.deselectEntriesByDate(
                                        entryGroup.value,
                                      );
                                    }
                                  },
                                  child: Container(
                                    color: background,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      0,
                                      4,
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
                                  key: PageStorageKey(entryGroup.key),
                                  initialItemCount: entryGroup.value.length,
                                  itemBuilder: (context, index, animation) {
                                    return SizeTransition(
                                      sizeFactor: animation,
                                      axisAlignment: 0.0,
                                      child: JournalEntryWidget(
                                        entry: entryGroup.value[index],
                                        onToggleFavorite: jc.toggleFavorite,
                                        onTap: () {
                                          if (jc.isSelectionMode) {
                                            setState(() => jc.toggleEntrySelection(entryGroup.value[index]));
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EntryInsightScreen(
                                                  entry: entryGroup.value[index],
                                                  journalController: jc,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        onLongPress: () {
                                          setState(() => jc.toggleEntrySelection(entryGroup.value[index]));
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                  ),
                ),
                EdgeFade(top: true, background: background),
                EdgeFade(top: false, background: background),
              ],
            ),
          ),
          GestureDetector(
            onVerticalDragUpdate: jc.handleDragUpdate,
            onVerticalDragEnd: (_) => jc.handleDragEnd(),
            child: JournalInputWidget(
              journalController: jc,
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: background.withAlpha(24),
            alignment: Alignment.centerLeft,
            child: jc.isSavingEntry
                ? IndeterminateProgressBar(
                    color: Theme.of(context).hintColor,
                    height: 1.5,
                  )
                : FractionallySizedBox(
                    widthFactor: (-jc.dragOffsetY / jc.swipeThreshold).clamp(0.0, 1.0),
                    child: Container(
                      height: 1,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
