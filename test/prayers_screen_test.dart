import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwali/models/prayer_model.dart';
import 'package:jadwali/providers/prayer_provider.dart';
import 'package:jadwali/screens/prayers_screen.dart';
import 'package:provider/provider.dart';

class _ScreenPrayerProvider extends PrayerProvider {
  _ScreenPrayerProvider(this._testPrayers, this._stats);

  final List<Prayer> _testPrayers;
  final Map<String, double> _stats;

  int loadCallCount = 0;
  Prayer? loggedPrayer;
  String? loggedStatus;
  bool? loggedIsCongregation;
  int? loggedRakatCaught;

  @override
  List<Prayer> get prayers => List<Prayer>.unmodifiable(_testPrayers);

  @override
  Future<void> loadPrayers() async {
    loadCallCount++;
  }

  @override
  Future<void> logPrayer(
    Prayer prayer, {
    required String status,
    required bool isCongregation,
    required int rakatCaught,
  }) async {
    loggedPrayer = prayer;
    loggedStatus = status;
    loggedIsCongregation = isCongregation;
    loggedRakatCaught = rakatCaught;
  }

  @override
  Future<Map<String, double>> getCongregationStats() async => _stats;
}

List<Prayer> _dailyPrayers() {
  const specs = <({String name, int rakat})>[
    (name: 'الفجر', rakat: 2),
    (name: 'الظهر', rakat: 4),
    (name: 'العصر', rakat: 4),
    (name: 'المغرب', rakat: 3),
    (name: 'العشاء', rakat: 4),
  ];

  return <Prayer>[
    for (var index = 0; index < specs.length; index++)
      Prayer(
        id: index + 1,
        name: specs[index].name,
        date: '2026-08-28',
        status: Prayer.pendingStatus,
        isCongregation: false,
        rakatCaught: 0,
        totalRakat: specs[index].rakat,
      ),
  ];
}

Widget _buildScreen(_ScreenPrayerProvider provider) {
  return ChangeNotifierProvider<PrayerProvider>.value(
    value: provider,
    child: const MaterialApp(home: PrayersScreen()),
  );
}

void main() {
  testWidgets('shows daily prayers and logs congregation rakah count', (
    tester,
  ) async {
    final provider = _ScreenPrayerProvider(_dailyPrayers(), <String, double>{});
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildScreen(provider));
    await tester.pump();

    expect(provider.loadCallCount, 1);
    expect(find.text('سجل الصلوات'), findsOneWidget);
    for (final prayer in _dailyPrayers()) {
      expect(find.text(prayer.name), findsOneWidget);
    }

    await tester.tap(find.text('الفجر'));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل صلاة الفجر'), findsOneWidget);

    await tester.tap(find.text('جماعة'));
    await tester.pump();
    expect(find.textContaining('عدد الركعات التي أدركتها'), findsOneWidget);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(2);
    await tester.pump();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(provider.loggedPrayer?.name, 'الفجر');
    expect(provider.loggedStatus, Prayer.completedStatus);
    expect(provider.loggedIsCongregation, isTrue);
    expect(provider.loggedRakatCaught, 2);
  });

  testWidgets('renders historical congregation stats with fl_chart', (
    tester,
  ) async {
    final stats = <String, double>{
      'الفجر': 40,
      'الظهر': 60,
      'العصر': 90,
      'المغرب': 20,
      'العشاء': 75,
    };
    final provider = _ScreenPrayerProvider(_dailyPrayers(), stats);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildScreen(provider));
    await tester.pump();
    await tester.tap(find.byTooltip('الإحصائيات الشاملة'));
    await tester.pumpAndSettle();

    expect(find.text('الإحصائيات الشاملة'), findsOneWidget);
    expect(find.text('نسبة أداء كل صلاة جماعة'), findsOneWidget);

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(5));
    expect(
      chart.data.barGroups.map((group) => group.barRods.single.toY),
      <double>[40, 60, 90, 20, 75],
    );
  });
}
