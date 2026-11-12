import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwali/models/task_model.dart';
import 'package:jadwali/providers/task_provider.dart';
import 'package:jadwali/providers/theme_provider.dart';
import 'package:jadwali/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DashboardTaskProvider extends TaskProvider {
  _DashboardTaskProvider(this._testTasks);

  final List<Task> _testTasks;

  @override
  List<Task> get tasks => List<Task>.unmodifiable(_testTasks);
}

Widget _buildDashboard(List<Task> tasks) {
  return ChangeNotifierProvider<TaskProvider>(
    create: (_) => _DashboardTaskProvider(tasks),
    child: const MaterialApp(home: DashboardScreen()),
  );
}

Task _task({required String status, bool isHidden = false}) {
  return Task(
    id: 1,
    title: 'Task',
    startTime: '09:00',
    endTime: '10:00',
    priority: 1,
    status: status,
    isHidden: isHidden,
    date: '2026-08-28',
  );
}

void main() {
  testWidgets('summarizes visible tasks and renders both pie sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDashboard(<Task>[
        _task(status: Task.completedStatus),
        _task(status: Task.pendingStatus),
        _task(status: Task.overdueStatus),
        _task(status: Task.completedStatus, isHidden: true),
      ]),
    );

    expect(find.text('الإحصائيات'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('total_tasks_count')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('completed_tasks_count')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('pending_tasks_count')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey<String>('total_tasks_count')))
          .data,
      '3',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('completed_tasks_count')),
          )
          .data,
      '1',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('pending_tasks_count')),
          )
          .data,
      '2',
    );

    final chart = tester.widget<PieChart>(find.byType(PieChart));
    expect(chart.data.sections, hasLength(2));
    expect(chart.data.sections[0].value, 1);
    expect(chart.data.sections[0].color, Colors.green);
    expect(chart.data.sections[0].title, 'المنجزة\n1 (33%)');
    expect(chart.data.sections[1].value, 2);
    expect(chart.data.sections[1].color, Colors.orange);
    expect(chart.data.sections[1].title, 'المتبقية\n2 (67%)');
  });

  testWidgets('shows an empty message when there are no visible tasks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDashboard(<Task>[
        _task(status: Task.completedStatus, isHidden: true),
      ]),
    );

    expect(find.text('لا توجد بيانات لهذا التاريخ.'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('renders safely when one pie value is zero', (tester) async {
    await tester.pumpWidget(
      _buildDashboard(<Task>[
        _task(status: Task.pendingStatus),
        _task(status: Task.overdueStatus),
      ]),
    );

    final chart = tester.widget<PieChart>(find.byType(PieChart));
    expect(chart.data.sections, hasLength(1));
    expect(chart.data.sections.single.value, 2);
    expect(chart.data.sections.single.color, Colors.orange);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings sheet updates and persists theme choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final taskProvider = _DashboardTaskProvider(<Task>[]);
    final themeProvider = ThemeProvider(preferences);
    addTearDown(taskProvider.dispose);
    addTearDown(themeProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('الوضع الداكن'), findsOneWidget);
    expect(find.text('لون التطبيق'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(themeProvider.isDarkMode, isTrue);
    expect(preferences.getBool('is_dark_mode'), isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('theme_color_teal')));
    await tester.pumpAndSettle();
    expect(themeProvider.primaryColorValue, Colors.teal.toARGB32());
    expect(preferences.getInt('primary_color_value'), Colors.teal.toARGB32());

    final aboutFinder = find.text('عن التطبيق');
    await tester.ensureVisible(aboutFinder);
    await tester.tap(aboutFinder);
    await tester.pumpAndSettle();

    expect(find.text('عن التطبيق'), findsOneWidget);
    expect(find.text('المخطط اليومي الذكي'), findsOneWidget);
    expect(find.text('تطوير: وهيب الكبودي'), findsOneWidget);
    expect(find.text('تواصل معي عبر واتساب'), findsOneWidget);
  });
}
