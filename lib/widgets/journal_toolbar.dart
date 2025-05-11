import 'package:flutter/material.dart';
import 'package:genesis_f1/constant/size.dart'; // Import SizeConstants
import '../services/auth_manager.dart';
import '../screens/auth_screen.dart';

class JournalToolbar extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onToggleFavorites;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenDatePicker;

  const JournalToolbar({
    super.key,
    required this.onSearch,
    required this.onToggleFavorites,
    required this.onOpenSettings,
    required this.onOpenDatePicker,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('genesis', style: theme.textTheme.titleMedium),
          Row(
            children: [
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
                icon: const Icon(
                  Icons.search,
                  size: SizeConstants.iconMedium,
                ), // Use constant
                onPressed: onSearch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity:
                    VisualDensity.compact, // Added for closer spacing
              ),
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
              PopupMenuButton(
                icon: const Icon(
                  Icons.more_vert,
                  size: SizeConstants.iconMedium,
                ), // Use constant
                // visualDensity: VisualDensity.compact, // Removed, not a property of PopupMenuButton
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(value: 'settings', child: Text('Settings')),
                      PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authManager.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  } else {
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
