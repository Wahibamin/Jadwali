import 'package:flutter_test/flutter_test.dart';
import 'package:jadwali/models/prayer_model.dart';

void main() {
  test('converts prayer values to and from SQLite maps', () {
    final prayer = Prayer(
      id: 3,
      name: 'المغرب',
      date: '2026-08-28',
      status: Prayer.completedStatus,
      isCongregation: true,
      rakatCaught: 2,
      totalRakat: 3,
    );

    final map = prayer.toMap();
    final restored = Prayer.fromMap(map);

    expect(map['isCongregation'], 1);
    expect(restored.id, prayer.id);
    expect(restored.name, prayer.name);
    expect(restored.date, prayer.date);
    expect(restored.status, prayer.status);
    expect(restored.isCongregation, isTrue);
    expect(restored.rakatCaught, 2);
    expect(restored.totalRakat, 3);
  });

  test('rejects invalid statuses, dates, and rakah counts', () {
    expect(
      () => Prayer(
        name: 'الفجر',
        date: '2026-08-28',
        status: 'invalid',
        isCongregation: false,
        rakatCaught: 0,
        totalRakat: 2,
      ),
      throwsArgumentError,
    );
    expect(
      () => Prayer(
        name: 'الفجر',
        date: '2026-02-29',
        status: Prayer.pendingStatus,
        isCongregation: false,
        rakatCaught: 0,
        totalRakat: 2,
      ),
      throwsArgumentError,
    );
    expect(
      () => Prayer(
        name: 'الفجر',
        date: '2026-08-28',
        status: Prayer.completedStatus,
        isCongregation: true,
        rakatCaught: 3,
        totalRakat: 2,
      ),
      throwsArgumentError,
    );
  });
}
