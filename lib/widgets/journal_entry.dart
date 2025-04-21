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
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  entry.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white30,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${entry.mood} • ${entry.tags.join(" ")} • ${entry.wordCount} words',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.text,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.55,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onToggleFavorite,
                    child: Icon(
                      Icons.star,
                      size: 18,
                      color: entry.isFavorite ? Colors.amber : Colors.white24,
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
