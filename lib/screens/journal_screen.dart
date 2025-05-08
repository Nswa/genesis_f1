import 'package:flutter/material.dart';
import 'package:genesis_f1/utils/system_ui_helper.dart';
import '../widgets/journal_input.dart';
import '../widgets/journal_entry.dart';
import '../widgets/journal_entry_shimmer.dart';
import '../widgets/journal_toolbar.dart';
import '../controller/journal_controller.dart';

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
          // ✅ Top toolbar
          SafeArea(
            bottom: false,
            child: JournalToolbar(
              onSearch: () {},
              onToggleFavorites: () {},
              onOpenSettings: () {},
            ),
          ),

          // ✅ Scrollable entries
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: jc.isLoading ? 5 : jc.entries.length,
                  itemBuilder: (_, index) {
                    if (jc.isLoading) return const JournalEntryShimmer();
                    final entry = jc.entries[index];
                    return JournalEntryWidget(
                      entry: entry,
                      onToggleFavorite: () {
                        setState(() => entry.isFavorite = !entry.isFavorite);
                      },
                    );
                  },
                ),
                _buildEdgeFade(top: true, background: background),
                _buildEdgeFade(top: false, background: background),
              ],
            ),
          ),

          // ✅ Sticky journal input at bottom
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

          // ✅ Progress bar (under input)
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
              colors: [background, background.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
