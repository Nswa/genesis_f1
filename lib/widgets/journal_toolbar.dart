import 'package:flutter/material.dart';
import 'package:genesis_f1/constant/size.dart'; // Import SizeConstants
import '../services/auth_manager.dart';
import '../screens/auth_screen.dart';
import '../controller/journal_controller.dart'; // Import SyncStatus

class JournalToolbar extends StatelessWidget {
  final bool isSearching; // To toggle search field visibility
  final VoidCallback onToggleSearch; // Renamed from onSearch
  final VoidCallback onToggleFavorites;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenDatePicker;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final SyncStatus syncStatus; // Added sync status

  const JournalToolbar({
    super.key,
    required this.isSearching,
    required this.onToggleSearch,
    required this.onToggleFavorites,
    required this.onOpenSettings,
    required this.onOpenDatePicker,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.syncStatus, // Added sync status
  });

  Widget _buildSyncStatusIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;
    bool shouldAnimate = false;
    String statusText;

    switch (syncStatus) {
      case SyncStatus.synced:
        iconData = Icons.cloud_done_outlined;
        iconColor = Colors.green;
        statusText = 'Synced';
        break;
      case SyncStatus.syncing:
        iconData = Icons.sync_outlined;
        iconColor = Colors.orange;
        shouldAnimate = true;
        statusText = 'Syncing...';
        break;
      case SyncStatus.offline:
        iconData = Icons.cloud_off_outlined;
        iconColor = Colors.grey;
        statusText = 'Offline';
        break;
      case SyncStatus.error:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        statusText = 'Sync Error';
        break;
    }

    Widget iconWidget = Icon(
      iconData,
      color: iconColor,
      size: SizeConstants.iconSmall,
    );
    if (shouldAnimate) {
      iconWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: value * 6.28319, // 2*pi
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    return Tooltip(
      message: statusText,
      waitDuration: const Duration(milliseconds: 200),
      showDuration: const Duration(seconds: 2),
      triggerMode: TooltipTriggerMode.tap,
      child: iconWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isSearching) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('genesis', style: theme.textTheme.titleMedium),
                const SizedBox(width: 5.0),
                _buildSyncStatusIcon(context),
              ],
            ),
          ],
          if (isSearching)
            Expanded(
              child: SizedBox(
                height: 36, // Consistent height for the TextField
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onChanged: onSearchChanged,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: SizeConstants.textMedium, // Adjusted for input
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search entries...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: (isDarkTheme ? Colors.white : Colors.black)
                          .withOpacity(0.5),
                      fontSize: SizeConstants.textMedium,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConstants.borderRadiusSmall,
                      ),
                      borderSide: BorderSide(
                        color: (isDarkTheme ? Colors.white : Colors.black)
                            .withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConstants.borderRadiusSmall,
                      ),
                      borderSide: BorderSide(
                        color: (isDarkTheme ? Colors.white : Colors.black)
                            .withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConstants.borderRadiusSmall,
                      ),
                      borderSide: BorderSide(
                        color:
                            theme
                                .colorScheme
                                .primary, // Use primary color for focus
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                    ),
                    suffixIcon:
                        searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: SizeConstants.iconSmall,
                                color: (isDarkTheme
                                        ? Colors.white
                                        : Colors.black)
                                    .withOpacity(0.6),
                              ),
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                            )
                            : null,
                  ),
                  cursorColor: theme.colorScheme.primary,
                ),
              ),
            ),
          Row(
            children: [
              if (!isSearching) // Only show calendar if not searching, to save space
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    size: SizeConstants.iconMedium, // Use constant
                  ),
                  onPressed: onOpenDatePicker,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity:
                      VisualDensity.compact, // Added for closer spacing
                ),
              IconButton(
                icon: Icon(
                  isSearching ? Icons.close : Icons.search, // Toggle icon
                  size: SizeConstants.iconMedium,
                ), // Use constant
                onPressed: onToggleSearch, // Use the new callback
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity:
                    VisualDensity.compact, // Added for closer spacing
              ),
              if (!isSearching) // Only show favorites if not searching
                IconButton(
                  icon: const Icon(
                    Icons.bookmark_border,
                    size: SizeConstants.iconMedium, // Use constant
                  ),
                  onPressed: onToggleFavorites,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity:
                      VisualDensity.compact, // Added for closer spacing
                ),
              if (!isSearching) // Only show more_vert if not searching
                PopupMenuButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: SizeConstants.iconMedium,
                  ), // Use constant
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(
                          value: 'settings',
                          child: Text('Settings'),
                        ),
                        PopupMenuItem(value: 'logout', child: Text('Logout')),
                      ],
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await authManager.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    } else if (value == 'settings') {
                      onOpenSettings();
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
