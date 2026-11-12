import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:jadwali/database/database_helper.dart';
import 'package:jadwali/models/task_model.dart';
import 'package:jadwali/providers/task_provider.dart';

void main() {
  group('Task', () {
    test('converts to and from SQLite values', () {
      final task = Task(
        id: 7,
        title: 'Plan the day',
        startTime: '08:00',
        endTime: '08:30',
        priority: 2,
        status: Task.pendingStatus,
        isHidden: true,
        isMuted: true,
        date: '2026-08-28',
      );

      final map = task.toMap();
      final restoredTask = Task.fromMap(map);

      expect(map['isHidden'], 1);
      expect(map['isMuted'], 1);
      expect(restoredTask.id, task.id);
      expect(restoredTask.title, task.title);
      expect(restoredTask.startTime, task.startTime);
      expect(restoredTask.endTime, task.endTime);
      expect(restoredTask.priority, task.priority);
      expect(restoredTask.status, task.status);
      expect(restoredTask.isHidden, isTrue);
      expect(restoredTask.isMuted, isTrue);
      expect(restoredTask.date, task.date);
    });

    test('defaults legacy SQLite rows to unmuted', () {
      final task = Task.fromMap(<String, Object?>{
        'id': 8,
        'title': 'Legacy task',
        'startTime': '09:00',
        'endTime': '09:30',
        'priority': 1,
        'status': Task.pendingStatus,
        'isHidden': 0,
        'date': '2026-08-28',
      });

      expect(task.isMuted, isFalse);
    });

    test('rejects unsupported statuses', () {
      expect(
        () => Task(
          title: 'Invalid task',
          startTime: '08:00',
          endTime: '08:30',
          priority: 1,
          status: 'cancelled',
          isHidden: false,
          date: '2026-08-28',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid dates', () {
      expect(
        () => Task(
          title: 'Invalid date',
          startTime: '08:00',
          endTime: '08:30',
          priority: 1,
          status: Task.pendingStatus,
          isHidden: false,
          date: '2026-02-29',
        ),
        throwsArgumentError,
      );
    });
  });

  group('DatabaseHelper', () {
    test('always returns the same singleton', () {
      expect(identical(DatabaseHelper(), DatabaseHelper.instance), isTrue);
    });

    test('requires an id when updating a task', () async {
      final task = Task(
        title: 'New task',
        startTime: '08:00',
        endTime: '08:30',
        priority: 1,
        status: Task.pendingStatus,
        isHidden: false,
        date: '2026-08-28',
      );

      await expectLater(
        DatabaseHelper.instance.updateTask(task),
        throwsArgumentError,
      );
    });
  });

  group('TaskProvider', () {
    test('starts with today selected and an empty task list', () {
      final provider = TaskProvider();
      addTearDown(provider.dispose);

      expect(
        provider.selectedDate,
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      expect(provider.tasks, isEmpty);
    });

    test('rejects an invalid selected date before querying SQLite', () async {
      final provider = TaskProvider();
      addTearDown(provider.dispose);
      final originalDate = provider.selectedDate;

      await expectLater(provider.changeDate('2026-02-29'), throwsArgumentError);
      expect(provider.selectedDate, originalDate);
    });
  });
}
