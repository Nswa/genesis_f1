import 'package:flutter/material.dart';
import '../models/entry.dart';

class JournalEntryWidget extends StatelessWidget {
  final Entry entry;
  final VoidCallback onToggleFavorite;

  const JournalEntryWidget({
    super.key,
    required this.entry,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = theme.hintColor;
    final metaColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: entry.animController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(entry.animController),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 0, left: 4),
                child: Text(
                  entry.timestamp,
                  style: TextStyle(
                    fontSize: 11,
                    color: hintColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${entry.mood} • ${entry.tags.join(" ")} • ${entry.wordCount} words',
                      style: TextStyle(fontSize: 12, color: metaColor),
                      softWrap: true,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(entry.text, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onToggleFavorite,
                    child: Icon(
                      Icons.star,
                      size: 18,
                      color:
                          entry.isFavorite
                              ? Colors.amber
                              : theme.iconTheme.color?.withValues(alpha: 0.24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
