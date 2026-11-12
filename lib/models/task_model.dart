class Task {
  Task({
    this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.priority,
    required this.status,
    required this.isHidden,
    this.isMuted = false,
    required this.date,
  }) {
    if (!validStatuses.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Must be pending, completed, or overdue.',
      );
    }

    if (!_isValidDate(date)) {
      throw ArgumentError.value(
        date,
        'date',
        'Must be a valid date in YYYY-MM-DD format.',
      );
    }
  }

  static const String pendingStatus = 'pending';
  static const String completedStatus = 'completed';
  static const String overdueStatus = 'overdue';

  static const Set<String> validStatuses = <String>{
    pendingStatus,
    completedStatus,
    overdueStatus,
  };

  final int? id;
  final String title;
  final String startTime;
  final String endTime;
  final int priority;
  final String status;
  final bool isHidden;
  final bool isMuted;
  final String date;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'priority': priority,
      'status': status,
      'isHidden': isHidden ? 1 : 0,
      'isMuted': isMuted ? 1 : 0,
      'date': date,
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      priority: (map['priority'] as num).toInt(),
      status: map['status'] as String,
      isHidden: (map['isHidden'] as num).toInt() == 1,
      isMuted: (map['isMuted'] as num?)?.toInt() == 1,
      date: map['date'] as String,
    );
  }

  static bool _isValidDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return false;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsedDate = DateTime.tryParse(value);

    return parsedDate != null &&
        parsedDate.year == year &&
        parsedDate.month == month &&
        parsedDate.day == day;
  }
}
