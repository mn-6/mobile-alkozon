class WorkLogEntry {
  const WorkLogEntry({
    required this.id,
    required this.clockInAt,
    this.clockOutAt,
    this.breakStartedAt,
    this.breakEndedAt,
    this.notes,
  });

  final int id;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final DateTime? breakStartedAt;
  final DateTime? breakEndedAt;
  final String? notes;

  bool get isOpenSession => clockOutAt == null;

  factory WorkLogEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.parse(value as String);
    }

    return WorkLogEntry(
      id: json['id'] as int,
      clockInAt: DateTime.parse(json['clockInAt'] as String),
      clockOutAt: parseDate(json['clockOutAt']),
      breakStartedAt: parseDate(json['breakStartedAt']),
      breakEndedAt: parseDate(json['breakEndedAt']),
      notes: json['notes'] as String?,
    );
  }
}
