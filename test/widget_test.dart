import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jadwali/main.dart';
import 'package:jadwali/providers/prayer_provider.dart';
import 'package:jadwali/providers/task_provider.dart';
import 'package:jadwali/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestTaskProvider extends TaskProvider {
  @override
  Future<void> loadTasks() async {}
}

class _TestPrayerProvider extends PrayerProvider {
  @override
  Future<void> loadPrayers() async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('ar_AE'));

  testWidgets('shows splash and switches between the four planner tabs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final provider = _TestTaskProvider();
    final prayerProvider = _TestPrayerProvider();
    final themeProvider = ThemeProvider(preferences);
    addTearDown(provider.dispose);
    addTearDown(prayerProvider.dispose);
    addTearDown(themeProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskProvider>.value(value: provider),
          ChangeNotifierProvider<PrayerProvider>.value(value: prayerProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('ar', 'AE'));
    expect(find.text('المهندس وهيب الكبودي'), findsOneWidget);
    expect(find.text('لا تنسونا من صالح دعائكم'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.text('لا تنسونا من صالح دعائكم'));
    await tester.pumpAndSettle();

    final homeContext = tester.element(find.byType(HomeScreen));
    expect(Localizations.localeOf(homeContext), const Locale('ar', 'AE'));
    expect(Directionality.of(homeContext), TextDirection.rtl);

    expect(find.text('الجدول اليومي'), findsNWidgets(2));
    expect(find.text('التقويم'), findsOneWidget);
    expect(find.text('الإحصائيات'), findsOneWidget);
    expect(find.text('الصلوات'), findsOneWidget);

    BottomNavigationBar navigationBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigationBar.currentIndex, 0);

    await tester.tap(find.text('التقويم'));
    await tester.pump();
    navigationBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigationBar.currentIndex, 1);

    await tester.tap(find.text('الإحصائيات'));
    await tester.pump();
    navigationBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigationBar.currentIndex, 2);

    await tester.tap(find.text('الصلوات'));
    await tester.pump();
    navigationBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigationBar.currentIndex, 3);

    await themeProvider.toggleDarkMode(true);
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });
}
