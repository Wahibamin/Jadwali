import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:jadwali/providers/task_provider.dart';
import 'package:jadwali/screens/calendar_screen.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class _CalendarTaskProvider extends TaskProvider {
  _CalendarTaskProvider(this._testSelectedDate);

  String _testSelectedDate;
  String? changedDate;

  @override
  String get selectedDate => _testSelectedDate;

  @override
  Future<void> changeDate(String newDate) async {
    changedDate = newDate;
    _testSelectedDate = newDate;
    notifyListeners();
  }
}

Widget _buildCalendar(
  _CalendarTaskProvider provider, {
  required VoidCallback onNavigateToTimeline,
}) {
  return ChangeNotifierProvider<TaskProvider>.value(
    value: provider,
    child: MaterialApp(
      home: CalendarScreen(onNavigateToTimeline: onNavigateToTimeline),
    ),
  );
}

void main() {
  testWidgets('uses provider selection and renders Gregorian and Hijri days', (
    tester,
  ) async {
    final provider = _CalendarTaskProvider('2026-08-15');
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      _buildCalendar(provider, onNavigateToTimeline: () {}),
    );

    final calendarFinder = find.byType(TableCalendar<Object?>);
    final calendar = tester.widget<TableCalendar<Object?>>(calendarFinder);
    final selectedDate = DateTime(2026, 8, 15);

    expect(isSameDay(calendar.focusedDay, selectedDate), isTrue);
    expect(calendar.selectedDayPredicate!(selectedDate), isTrue);
    expect(calendar.calendarBuilders.defaultBuilder, isNotNull);
    expect(calendar.calendarBuilders.selectedBuilder, isNotNull);
    expect(calendar.calendarBuilders.todayBuilder, isNotNull);

    final day = DateTime(2026, 8, 20);
    final cell = calendar.calendarBuilders.defaultBuilder!(
      tester.element(calendarFinder),
      day,
      selectedDate,
    );
    final expectedHijriDay = HijriCalendar.fromDate(day).hDay;

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: cell)));

    expect(find.text('20'), findsOneWidget);
    expect(find.text('$expectedHijriDay'), findsOneWidget);
  });

  testWidgets(
    'selecting a day changes provider date and navigates to Timeline',
    (tester) async {
      final provider = _CalendarTaskProvider('2026-08-15');
      addTearDown(provider.dispose);
      var navigationCount = 0;

      await tester.pumpWidget(
        _buildCalendar(
          provider,
          onNavigateToTimeline: () {
            navigationCount++;
          },
        ),
      );

      final calendar = tester.widget<TableCalendar<Object?>>(
        find.byType(TableCalendar<Object?>),
      );
      calendar.onDaySelected!(DateTime(2026, 8, 21), DateTime(2026, 8, 21));
      await tester.pump();

      expect(provider.changedDate, '2026-08-21');
      expect(navigationCount, 1);
    },
  );
}
