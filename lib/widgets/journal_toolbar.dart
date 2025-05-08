import 'package:flutter/material.dart';

class JournalToolbar extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onToggleFavorites;
  final VoidCallback onOpenSettings;

  const JournalToolbar({
    super.key,
    required this.onSearch,
    required this.onToggleFavorites,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('genesis', style: theme.textTheme.titleMedium),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
              IconButton(
                icon: const Icon(Icons.star_border),
                onPressed: onToggleFavorites,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
