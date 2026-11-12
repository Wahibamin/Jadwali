import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/task_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.onNavigateToTimeline});

  final VoidCallback onNavigateToTimeline;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // These bounds match the date range supported by the hijri package.
  static final DateTime _firstDay = DateTime(1937, 3, 14);
  static final DateTime _lastDay = DateTime(2077, 11, 16);

  Future<void> _selectDay(TaskProvider provider, DateTime selectedDay) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    await provider.changeDate(formattedDate);

    if (mounted) {
      widget.onNavigateToTimeline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقويم')),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          final selectedDay = DateTime.parse(provider.selectedDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: TableCalendar<Object?>(
                  locale: Localizations.localeOf(context).toString(),
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  focusedDay: selectedDay,
                  calendarFormat: CalendarFormat.month,
                  rowHeight: 58,
                  daysOfWeekHeight: 28,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  onDaySelected: (day, focusedDay) {
                    _selectDay(provider, day);
                  },
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronMargin: EdgeInsets.zero,
                    rightChevronMargin: EdgeInsets.zero,
                  ),
                  calendarStyle: const CalendarStyle(
                    cellMargin: EdgeInsets.all(3),
                    outsideDaysVisible: true,
                  ),
                  calendarBuilders: CalendarBuilders<Object?>(
                    defaultBuilder: (context, day, focusedDay) {
                      return _CalendarDayCell(day: day);
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _CalendarDayCell(day: day, isSelected: true);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _CalendarDayCell(day: day, isToday: true);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return _CalendarDayCell(day: day, isOutside: true);
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hijriDay = HijriCalendar.fromDate(day).hDay;

    final backgroundColor = isSelected
        ? colorScheme.primary
        : isToday
        ? colorScheme.primaryContainer
        : Colors.transparent;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : isOutside
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.55)
        : colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected
            ? Border.all(color: colorScheme.primary)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '${day.day}',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$hijriDay',
            style: TextStyle(
              color: foregroundColor.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
