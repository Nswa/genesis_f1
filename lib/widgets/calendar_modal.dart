import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/entry.dart';

void showCalendarModal(
  BuildContext context,
  List<Entry> entries,
  ScrollController scrollController,
) {
  FocusScope.of(context).unfocus();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "calendar",
    barrierColor: Colors.black.withOpacity(0.25),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder:
        (_, __, ___) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.transparent),
                ),
                GestureDetector(
                  onTap: () {},
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 330,
                      maxHeight: 360,
                    ),
                    child: Material(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 16,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                        child: CalendarView(
                          entries: entries,
                          scrollController: scrollController,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

class CalendarView extends StatelessWidget {
  final List<Entry> entries;
  final ScrollController scrollController;

  const CalendarView({
    super.key,
    required this.entries,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final validDates =
        entries
            .map(
              (e) => DateTime(
                e.rawDateTime.year,
                e.rawDateTime.month,
                e.rawDateTime.day,
              ),
            )
            .toSet();

    return SizedBox(
      height: 280, // 👈 tighter fit
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now(),
        focusedDay: DateTime.now(),
        sixWeekMonthsEnforced: false, // 👈 don't over-expand height
        rowHeight: 32,
        daysOfWeekHeight: 20,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBM Plex Sans',
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, size: 18),
          rightChevronIcon: const Icon(Icons.chevron_right, size: 18),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
          ),
          weekendTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: Theme.of(context).hintColor,
          ),
          disabledTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: Theme.of(context).disabledColor.withOpacity(0.2),
          ),
          outsideTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: Theme.of(context).hintColor.withOpacity(0.2),
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
          ),
        ),
        enabledDayPredicate:
            (day) =>
                validDates.contains(DateTime(day.year, day.month, day.day)),
        onDaySelected: (selectedDay, _) {
          Navigator.of(context).pop();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              FocusScope.of(context).unfocus();
            }
            final index = entries.indexWhere(
              (e) =>
                  e.rawDateTime.year == selectedDay.year &&
                  e.rawDateTime.month == selectedDay.month &&
                  e.rawDateTime.day == selectedDay.day,
            );
            if (index >= 0) {
              scrollController.animateTo(
                index *
                    180.0, // This magic number might need context or be a constant
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              );
            }
          });
        },
      ),
    );
  }
}
