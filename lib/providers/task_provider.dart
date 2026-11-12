import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

/// Manages task state and keeps it synchronized with the SQLite database.
class TaskProvider extends ChangeNotifier {
  TaskProvider({
    DatabaseHelper? databaseHelper,
    NotificationService? notificationService,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       _notificationService =
           notificationService ?? NotificationService.instance,
       _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final DatabaseHelper _databaseHelper;
  final NotificationService _notificationService;

  List<Task> _tasks = <Task>[];
  String _selectedDate;

  /// A read-only view of the tasks loaded for [selectedDate].
  List<Task> get tasks => List<Task>.unmodifiable(_tasks);

  /// The active date in YYYY-MM-DD format.
  String get selectedDate => _selectedDate;

  /// Loads all tasks belonging to the currently selected date.
  Future<void> loadTasks() async {
    final dateBeingLoaded = _selectedDate;
    await _generateDailyRoutine(dateBeingLoaded);
    final loadedTasks = await _databaseHelper.getTasksByDate(dateBeingLoaded);
    await _evaluateOverdueTasks(loadedTasks);
    final refreshedTasks = await _databaseHelper.getTasksByDate(
      dateBeingLoaded,
    );

    // Ignore an outdated result if the selected date changed during the query.
    if (dateBeingLoaded != _selectedDate) {
      return;
    }

    _tasks = refreshedTasks;
    notifyListeners();
  }

  /// Marks pending tasks as overdue once their stored end time has passed.
  Future<void> _evaluateOverdueTasks(List<Task> tasks) async {
    final now = DateTime.now();

    for (final task in tasks) {
      if (task.status != Task.pendingStatus) {
        continue;
      }

      final endDateTime = _parseTaskEndDateTime(task);
      if (endDateTime != null && endDateTime.isBefore(now)) {
        final overdueTask = _copyTask(task, status: Task.overdueStatus);
        await _databaseHelper.updateTask(overdueTask);
      }
    }
  }

  /// Inserts the default daily routine for [date] without duplicating titles.
  Future<void> _generateDailyRoutine(String date) async {
    final defaultTasks = <Task>[
      Task(
        title: 'صلاة الفجر',
        startTime: '04:30',
        endTime: '05:00',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: false,
        date: date,
      ),
      Task(
        title: 'صلاة الظهر',
        startTime: '12:00',
        endTime: '12:30',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: false,
        date: date,
      ),
      Task(
        title: 'صلاة العصر',
        startTime: '15:30',
        endTime: '16:00',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: false,
        date: date,
      ),
      Task(
        title: 'صلاة المغرب',
        startTime: '18:30',
        endTime: '19:00',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: false,
        date: date,
      ),
      Task(
        title: 'صلاة العشاء',
        startTime: '20:00',
        endTime: '20:30',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: false,
        date: date,
      ),
      Task(
        title: 'تطوير الذات',
        startTime: '21:00',
        endTime: '22:00',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: false,
        date: date,
      ),
    ];

    final existingTasks = await _databaseHelper.getTasksByDate(date);
    final existingTitles = existingTasks.map((task) => task.title).toSet();
    final insertedTitles = <String>{};

    for (final task in defaultTasks) {
      if (!existingTitles.contains(task.title)) {
        await _databaseHelper.insertTask(task);
        existingTitles.add(task.title);
        insertedTitles.add(task.title);
      }
    }

    if (insertedTitles.isEmpty) {
      return;
    }

    final savedTasks = await _databaseHelper.getTasksByDate(date);
    for (final task in savedTasks) {
      if (insertedTitles.contains(task.title)) {
        await _notificationService.scheduleTaskNotification(task);
      }
    }
  }

  /// Changes the active date and loads its tasks from SQLite.
  Future<void> changeDate(String newDate) async {
    _validateDate(newDate);
    _selectedDate = newDate;
    await loadTasks();
  }

  /// Persists a new task and refreshes the selected date's task list.
  Future<void> addTask(Task task) async {
    final insertedId = await _databaseHelper.insertTask(task);
    final insertedTask = _copyTask(task, id: insertedId);
    await _notificationService.scheduleTaskNotification(insertedTask);
    await loadTasks();
  }

  /// Marks a task completed without allowing completion to be reversed.
  Future<void> markTaskCompleted(Task task) async {
    if (task.status == Task.completedStatus) {
      return;
    }

    final completedTask = _copyTask(task, status: Task.completedStatus);
    await _databaseHelper.updateTask(completedTask);
    await _notificationService.cancelNotification(task.id!);
    await loadTasks();
  }

  /// Delays a task's start time and replaces its scheduled notification.
  Future<void> snoozeTask(Task task, int minutes) async {
    final timeParts = task.startTime.split(':');
    if (timeParts.length != 2) {
      throw const FormatException('Task startTime must use HH:mm format.');
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Task startTime must use HH:mm format.');
    }

    final currentStartTime = DateTime(2000, 1, 1, hour, minute);
    final snoozedStartTime = currentStartTime.add(Duration(minutes: minutes));
    final updatedTask = _copyTask(
      task,
      startTime: DateFormat('HH:mm').format(snoozedStartTime),
    );

    await _databaseHelper.updateTask(updatedTask);
    await _notificationService.cancelNotification(task.id!);
    await _notificationService.scheduleTaskNotification(updatedTask);
    await loadTasks();
  }

  /// Hides a task from the timeline without deleting it from SQLite.
  Future<void> hideTask(Task task) async {
    final hiddenTask = _copyTask(task, isHidden: true);
    await _databaseHelper.updateTask(hiddenTask);
    await loadTasks();
  }

  /// Restores a hidden task to the normal timeline view.
  Future<void> unhideTask(Task task) async {
    final visibleTask = _copyTask(task, isHidden: false);
    await _databaseHelper.updateTask(visibleTask);
    await loadTasks();
  }

  /// Enables or disables notifications for one task.
  Future<void> toggleTaskMute(Task task) async {
    final updatedTask = _copyTask(task, isMuted: !task.isMuted);
    await _databaseHelper.updateTask(updatedTask);

    if (updatedTask.isMuted) {
      await _notificationService.cancelNotification(updatedTask.id!);
    } else if (updatedTask.status == Task.pendingStatus) {
      await _notificationService.scheduleTaskNotification(updatedTask);
    }

    await loadTasks();
  }

  /// Persists edits and replaces the task's existing notification schedule.
  Future<void> updateExistingTask(Task updatedTask) async {
    await _databaseHelper.updateTask(updatedTask);
    await _notificationService.cancelNotification(updatedTask.id!);

    if (!updatedTask.isMuted && updatedTask.status == Task.pendingStatus) {
      await _notificationService.scheduleTaskNotification(updatedTask);
    }

    await loadTasks();
  }

  /// Deletes one task and refreshes the selected date's task list.
  Future<void> deleteTask(int id) async {
    await _databaseHelper.deleteTask(id);
    await loadTasks();
  }

  /// Deletes every task and refreshes the current state.
  Future<void> clearAllTasks() async {
    await _databaseHelper.deleteAllTasks();
    await loadTasks();
  }

  /// Deletes completed tasks and refreshes the current state.
  Future<void> clearCompletedTasks() async {
    await _databaseHelper.deleteCompletedTasks();
    await loadTasks();
  }

  static void _validateDate(String date) {
    final parsedDate = DateTime.tryParse(date);
    final isValid =
        parsedDate != null &&
        DateFormat('yyyy-MM-dd').format(parsedDate) == date;

    if (!isValid) {
      throw ArgumentError.value(
        date,
        'newDate',
        'Must be a valid date in YYYY-MM-DD format.',
      );
    }
  }

  static DateTime? _parseTaskEndDateTime(Task task) {
    final timeParts = task.endTime.split(':');
    if (timeParts.length != 2) {
      return null;
    }

    final date = DateTime.tryParse(task.date);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (date == null ||
        hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static Task _copyTask(
    Task task, {
    int? id,
    String? startTime,
    String? status,
    bool? isHidden,
    bool? isMuted,
  }) {
    return Task(
      id: id ?? task.id,
      title: task.title,
      startTime: startTime ?? task.startTime,
      endTime: task.endTime,
      priority: task.priority,
      status: status ?? task.status,
      isHidden: isHidden ?? task.isHidden,
      isMuted: isMuted ?? task.isMuted,
      date: task.date,
    );
  }
}
