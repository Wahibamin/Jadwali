class Prayer {
  Prayer({
    this.id,
    required this.name,
    required this.date,
    required this.status,
    required this.isCongregation,
    required this.rakatCaught,
    required this.totalRakat,
  }) {
    if (!validStatuses.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Must be pending, completed, or missed.',
      );
    }

    if (!_isValidDate(date)) {
      throw ArgumentError.value(
        date,
        'date',
        'Must be a valid date in YYYY-MM-DD format.',
      );
    }

    if (totalRakat <= 0 || rakatCaught < 0 || rakatCaught > totalRakat) {
      throw ArgumentError(
        'rakatCaught must be between 0 and totalRakat, and totalRakat '
        'must be positive.',
      );
    }
  }

  static const String pendingStatus = 'pending';
  static const String completedStatus = 'completed';
  static const String missedStatus = 'missed';

  static const Set<String> validStatuses = <String>{
    pendingStatus,
    completedStatus,
    missedStatus,
  };

  final int? id;
  final String name;
  final String date;
  final String status;
  final bool isCongregation;
  final int rakatCaught;
  final int totalRakat;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'date': date,
      'status': status,
      'isCongregation': isCongregation ? 1 : 0,
      'rakatCaught': rakatCaught,
      'totalRakat': totalRakat,
    };
  }

  factory Prayer.fromMap(Map<String, Object?> map) {
    return Prayer(
      id: (map['id'] as num?)?.toInt(),
      name: map['name'] as String,
      date: map['date'] as String,
      status: map['status'] as String,
      isCongregation: (map['isCongregation'] as num).toInt() == 1,
      rakatCaught: (map['rakatCaught'] as num).toInt(),
      totalRakat: (map['totalRakat'] as num).toInt(),
    );
  }

  static bool _isValidDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return false;
    }

    final parsedDate = DateTime.tryParse(value);
    return parsedDate != null &&
        parsedDate.year == int.parse(match.group(1)!) &&
        parsedDate.month == int.parse(match.group(2)!) &&
        parsedDate.day == int.parse(match.group(3)!);
  }
}
