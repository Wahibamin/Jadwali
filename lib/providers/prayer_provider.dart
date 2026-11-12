import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/prayer_model.dart';

class PrayerProvider extends ChangeNotifier {
  PrayerProvider({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
      _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  static const List<({String name, int totalRakat})> _defaultPrayers =
      <({String name, int totalRakat})>[
        (name: 'الفجر', totalRakat: 2),
        (name: 'الظهر', totalRakat: 4),
        (name: 'العصر', totalRakat: 4),
        (name: 'المغرب', totalRakat: 3),
        (name: 'العشاء', totalRakat: 4),
      ];

  final DatabaseHelper _databaseHelper;

  List<Prayer> _prayers = <Prayer>[];
  String _selectedDate;

  List<Prayer> get prayers => List<Prayer>.unmodifiable(_prayers);
  String get selectedDate => _selectedDate;

  Future<void> loadPrayers() async {
    final dateBeingLoaded = _selectedDate;
    var loadedPrayers = await _databaseHelper.getPrayersByDate(dateBeingLoaded);

    if (loadedPrayers.isEmpty) {
      for (final defaultPrayer in _defaultPrayers) {
        await _databaseHelper.insertPrayer(
          Prayer(
            name: defaultPrayer.name,
            date: dateBeingLoaded,
            status: Prayer.pendingStatus,
            isCongregation: false,
            rakatCaught: 0,
            totalRakat: defaultPrayer.totalRakat,
          ),
        );
      }

      loadedPrayers = await _databaseHelper.getPrayersByDate(dateBeingLoaded);
    }

    if (dateBeingLoaded != _selectedDate) {
      return;
    }

    _prayers = loadedPrayers;
    notifyListeners();
  }

  Future<void> changeDate(String newDate) async {
    _validateDate(newDate);
    _selectedDate = newDate;
    await loadPrayers();
  }

  Future<void> logPrayer(
    Prayer prayer, {
    required String status,
    required bool isCongregation,
    required int rakatCaught,
  }) async {
    final updatedPrayer = Prayer(
      id: prayer.id,
      name: prayer.name,
      date: prayer.date,
      status: status,
      isCongregation: isCongregation,
      rakatCaught: rakatCaught,
      totalRakat: prayer.totalRakat,
    );

    await _databaseHelper.updatePrayer(updatedPrayer);
    await loadPrayers();
  }

  Future<Map<String, double>> getCongregationStats() async {
    final allPrayers = await _databaseHelper.getAllPrayers();
    final totals = <String, int>{
      for (final prayer in _defaultPrayers) prayer.name: 0,
    };
    final congregationTotals = <String, int>{
      for (final prayer in _defaultPrayers) prayer.name: 0,
    };

    for (final prayer in allPrayers) {
      if (!totals.containsKey(prayer.name)) {
        continue;
      }

      totals[prayer.name] = totals[prayer.name]! + 1;
      if (prayer.isCongregation) {
        congregationTotals[prayer.name] = congregationTotals[prayer.name]! + 1;
      }
    }

    return <String, double>{
      for (final prayer in _defaultPrayers)
        prayer.name: totals[prayer.name] == 0
            ? 0
            : congregationTotals[prayer.name]! / totals[prayer.name]! * 100,
    };
  }

  static void _validateDate(String date) {
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null ||
        DateFormat('yyyy-MM-dd').format(parsedDate) != date) {
      throw ArgumentError.value(
        date,
        'newDate',
        'Must be a valid date in YYYY-MM-DD format.',
      );
    }
  }
}
