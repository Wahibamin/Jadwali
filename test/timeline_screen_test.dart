import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwali/models/task_model.dart';
import 'package:jadwali/providers/task_provider.dart';
import 'package:jadwali/screens/timeline_screen.dart';
import 'package:provider/provider.dart';

class _TimelineTaskProvider extends TaskProvider {
  _TimelineTaskProvider([List<Task> tasks = const <Task>[]])
    : _testTasks = List<Task>.of(tasks);

  final List<Task> _testTasks;

  int loadCallCount = 0;
  int markCompletedCallCount = 0;
  int clearAllCallCount = 0;
  int clearCompletedCallCount = 0;
  int? deletedTaskId;
  int? hiddenTaskId;
  int? unhiddenTaskId;
  int? mutedTaskId;
  Task? addedTask;
  Task? updatedTask;

  @override
  List<Task> get tasks => List<Task>.unmodifiable(_testTasks);

  @override
  Future<void> loadTasks() async {
    loadCallCount++;
  }

  @override
  Future<void> addTask(Task task) async {
    addedTask = task;
    _testTasks.add(_copyTask(task, id: 100));
    notifyListeners();
  }

  @override
  Future<void> markTaskCompleted(Task task) async {
    if (task.status == Task.completedStatus) {
      return;
    }

    markCompletedCallCount++;
    final index = _testTasks.indexWhere((item) => item.id == task.id);
    _testTasks[index] = _copyTask(task, status: Task.completedStatus);
    notifyListeners();
  }

  @override
  Future<void> hideTask(Task task) async {
    hiddenTaskId = task.id;
    final index = _testTasks.indexWhere((item) => item.id == task.id);
    _testTasks[index] = _copyTask(task, isHidden: true);
    notifyListeners();
  }

  @override
  Future<void> unhideTask(Task task) async {
    unhiddenTaskId = task.id;
    final index = _testTasks.indexWhere((item) => item.id == task.id);
    _testTasks[index] = _copyTask(task, isHidden: false);
    notifyListeners();
  }

  @override
  Future<void> deleteTask(int id) async {
    deletedTaskId = id;
    _testTasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  @override
  Future<void> toggleTaskMute(Task task) async {
    mutedTaskId = task.id;
    final index = _testTasks.indexWhere((item) => item.id == task.id);
    _testTasks[index] = _copyTask(task, isMuted: !task.isMuted);
    notifyListeners();
  }

  @override
  Future<void> updateExistingTask(Task task) async {
    updatedTask = task;
    final index = _testTasks.indexWhere((item) => item.id == task.id);
    _testTasks[index] = task;
    notifyListeners();
  }

  @override
  Future<void> clearAllTasks() async {
    clearAllCallCount++;
    _testTasks.clear();
    notifyListeners();
  }

  @override
  Future<void> clearCompletedTasks() async {
    clearCompletedCallCount++;
    _testTasks.removeWhere((task) => task.status == Task.completedStatus);
    notifyListeners();
  }

  static Task _copyTask(
    Task task, {
    int? id,
    String? status,
    bool? isHidden,
    bool? isMuted,
  }) {
    return Task(
      id: id ?? task.id,
      title: task.title,
      startTime: task.startTime,
      endTime: task.endTime,
      priority: task.priority,
      status: status ?? task.status,
      isHidden: isHidden ?? task.isHidden,
      isMuted: isMuted ?? task.isMuted,
      date: task.date,
    );
  }
}

Widget _buildTimeline(_TimelineTaskProvider provider) {
  return ChangeNotifierProvider<TaskProvider>.value(
    value: provider,
    child: const MaterialApp(home: TimelineScreen()),
  );
}

void main() {
  testWidgets('displays visible tasks and filters hidden tasks', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 1,
        title: 'Visible task',
        startTime: '08:00',
        endTime: '09:00',
        priority: 1,
        status: Task.pendingStatus,
        isHidden: false,
        date: '2026-08-28',
      ),
      Task(
        id: 2,
        title: 'Hidden task',
        startTime: '10:00',
        endTime: '11:00',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: true,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.pump();

    expect(find.text('Visible task'), findsOneWidget);
    expect(find.text('08:00 - 09:00'), findsOneWidget);
    expect(find.text('عادي'), findsOneWidget);
    expect(find.text('Hidden task'), findsNothing);
  });

  testWidgets('loads tasks initially when the provider list is empty', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.pump();

    expect(provider.loadCallCount, 1);
    expect(find.text('لا توجد مهام لهذا التاريخ.'), findsOneWidget);
  });

  testWidgets('adds a pending visible task from the bottom sheet', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.pump();

    await tester.tap(find.byTooltip('إضافة مهمة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Write daily plan');

    await tester.tap(find.text('وقت البداية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('وقت النهاية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ المهمة'));
    await tester.pumpAndSettle();

    final addedTask = provider.addedTask;
    expect(addedTask, isNotNull);
    expect(addedTask!.title, 'Write daily plan');
    expect(addedTask.startTime, matches(RegExp(r'^\d{2}:\d{2}$')));
    expect(addedTask.endTime, matches(RegExp(r'^\d{2}:\d{2}$')));
    expect(addedTask.priority, 1);
    expect(addedTask.status, Task.pendingStatus);
    expect(addedTask.isHidden, isFalse);
    expect(addedTask.date, provider.selectedDate);
  });

  testWidgets('checkbox marks completion once and then becomes disabled', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 10,
        title: 'Complete interaction test',
        startTime: '12:00',
        endTime: '12:30',
        priority: 2,
        status: Task.pendingStatus,
        isHidden: false,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    final title = tester.widget<Text>(find.text('Complete interaction test'));

    expect(provider.markCompletedCallCount, 1);
    expect(checkbox.value, isTrue);
    expect(checkbox.onChanged, isNull);
    expect(title.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(provider.markCompletedCallCount, 1);
  });

  testWidgets('overdue tasks use the error highlight and Arabic label', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 14,
        title: 'Overdue visual task',
        startTime: '08:00',
        endTime: '08:30',
        priority: 3,
        status: Task.overdueStatus,
        isHidden: false,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));

    final titleFinder = find.text('Overdue visual task');
    final cardFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(Card),
    );
    final context = tester.element(titleFinder);
    final colorScheme = Theme.of(context).colorScheme;
    final card = tester.widget<Card>(cardFinder);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));

    expect(find.text('متأخرة'), findsOneWidget);
    expect(card.color, colorScheme.errorContainer.withValues(alpha: 0.3));
    expect(checkbox.value, isFalse);
    expect(checkbox.onChanged, isNotNull);
  });

  testWidgets('toggles task notification mute from the trailing button', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 11,
        title: 'Enabled notification task',
        startTime: '12:00',
        endTime: '12:30',
        priority: 2,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: false,
        date: '2026-08-28',
      ),
      Task(
        id: 12,
        title: 'Muted notification task',
        startTime: '13:00',
        endTime: '13:30',
        priority: 2,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: true,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));

    expect(find.byTooltip('كتم الإشعار'), findsOneWidget);
    expect(find.byTooltip('تفعيل الإشعار'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('كتم الإشعار'));
    await tester.pump();

    expect(provider.mutedTaskId, 11);
    expect(provider.tasks.first.isMuted, isTrue);
    expect(find.byTooltip('تفعيل الإشعار'), findsNWidgets(2));
  });

  testWidgets('long press edits a task while preserving stored state', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 13,
        title: 'Original task title',
        startTime: '09:15',
        endTime: '10:45',
        priority: 2,
        status: Task.pendingStatus,
        isHidden: false,
        isMuted: true,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.longPress(find.text('Original task title'));
    await tester.pumpAndSettle();

    expect(find.text('تعديل المهمة'), findsOneWidget);
    expect(find.text('حفظ التعديلات'), findsOneWidget);
    expect(find.text('09:15'), findsOneWidget);
    expect(find.text('10:45'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Original task title',
    );

    await tester.enterText(find.byType(TextField), 'Updated task title');
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عالي').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    final updatedTask = provider.updatedTask;
    expect(updatedTask, isNotNull);
    expect(updatedTask!.id, 13);
    expect(updatedTask.title, 'Updated task title');
    expect(updatedTask.startTime, '09:15');
    expect(updatedTask.endTime, '10:45');
    expect(updatedTask.priority, 3);
    expect(updatedTask.status, Task.pendingStatus);
    expect(updatedTask.isHidden, isFalse);
    expect(updatedTask.isMuted, isTrue);
    expect(updatedTask.date, '2026-08-28');
  });

  testWidgets('right swipe hides a task', (tester) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 20,
        title: 'Hide interaction test',
        startTime: '13:00',
        endTime: '13:30',
        priority: 1,
        status: Task.pendingStatus,
        isHidden: false,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.drag(find.text('Hide interaction test'), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(provider.hiddenTaskId, 20);
    expect(find.text('Hide interaction test'), findsNothing);
  });

  testWidgets('shows hidden tasks and restores one with a right swipe', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 21,
        title: 'Hidden restore test',
        startTime: '13:30',
        endTime: '14:00',
        priority: 2,
        status: Task.pendingStatus,
        isHidden: true,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.pump();

    expect(find.text('Hidden restore test'), findsNothing);
    expect(find.byTooltip('إظهار المهام المخفية'), findsOneWidget);

    await tester.tap(find.byTooltip('إظهار المهام المخفية'));
    await tester.pump();

    expect(find.text('Hidden restore test'), findsOneWidget);
    expect(find.byTooltip('إخفاء المهام المخفية'), findsOneWidget);

    final hiddenCard = find.ancestor(
      of: find.text('Hidden restore test'),
      matching: find.byType(Card),
    );
    final hiddenOpacity = tester.widget<Opacity>(
      find.descendant(of: hiddenCard, matching: find.byType(Opacity)),
    );
    expect(hiddenOpacity.opacity, 0.5);
    expect(
      find.descendant(
        of: hiddenCard,
        matching: find.byIcon(Icons.visibility_off),
      ),
      findsOneWidget,
    );

    await tester.drag(find.text('Hidden restore test'), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(provider.unhiddenTaskId, 21);
    expect(provider.tasks.single.isHidden, isFalse);

    final restoredCard = find.ancestor(
      of: find.text('Hidden restore test'),
      matching: find.byType(Card),
    );
    final restoredOpacity = tester.widget<Opacity>(
      find.descendant(of: restoredCard, matching: find.byType(Opacity)),
    );
    expect(restoredOpacity.opacity, 1.0);
  });

  testWidgets('left swipe deletes a task and shows confirmation', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 30,
        title: 'Delete interaction test',
        startTime: '14:00',
        endTime: '14:30',
        priority: 3,
        status: Task.pendingStatus,
        isHidden: false,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));
    await tester.drag(
      find.text('Delete interaction test'),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(provider.deletedTaskId, 30);
    expect(find.text('Delete interaction test'), findsNothing);
    expect(find.text('تم حذف المهمة.'), findsOneWidget);
  });

  testWidgets('popup menu executes completed and confirmed bulk deletion', (
    tester,
  ) async {
    final provider = _TimelineTaskProvider(<Task>[
      Task(
        id: 40,
        title: 'Pending bulk task',
        startTime: '15:00',
        endTime: '15:30',
        priority: 1,
        status: Task.pendingStatus,
        isHidden: false,
        date: '2026-08-28',
      ),
      Task(
        id: 41,
        title: 'Completed bulk task',
        startTime: '16:00',
        endTime: '16:30',
        priority: 1,
        status: Task.completedStatus,
        isHidden: false,
        date: '2026-08-28',
      ),
    ]);
    addTearDown(provider.dispose);

    await tester.pumpWidget(_buildTimeline(provider));

    await tester.tap(find.byTooltip('إجراءات المهام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف المهام المنجزة'));
    await tester.pumpAndSettle();

    expect(provider.clearCompletedCallCount, 1);
    expect(find.text('Completed bulk task'), findsNothing);
    expect(find.text('Pending bulk task'), findsOneWidget);

    await tester.tap(find.byTooltip('إجراءات المهام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف كل المهام'));
    await tester.pumpAndSettle();
    expect(
      find.text('هل أنت متأكد من حذف جميع المهام نهائيًا؟'),
      findsOneWidget,
    );

    await tester.tap(find.text('حذف الكل'));
    await tester.pumpAndSettle();

    expect(provider.clearAllCallCount, 1);
    expect(find.text('Pending bulk task'), findsNothing);
  });
}
