import 'package:alkozon/features/work_time/domain/entities/work_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkLogEntry', () {
    test('fromJson parses open session with active break', () {
      final entry = WorkLogEntry.fromJson({
        'id': 12,
        'clockInAt': '2026-05-20T08:00:00.000Z',
        'clockOutAt': null,
        'breakStartedAt': '2026-05-20T09:00:00.000Z',
        'breakEndedAt': null,
        'notes': 'Zmiana poranna',
      });

      expect(entry.id, 12);
      expect(entry.isOpenSession, isTrue);
      expect(entry.breakStartedAt, isNotNull);
      expect(entry.breakEndedAt, isNull);
      expect(entry.notes, 'Zmiana poranna');
    });

    test('fromJson parses closed session', () {
      final entry = WorkLogEntry.fromJson({
        'id': 13,
        'clockInAt': '2026-05-19T08:00:00.000Z',
        'clockOutAt': '2026-05-19T16:00:00.000Z',
        'breakStartedAt': '2026-05-19T12:00:00.000Z',
        'breakEndedAt': '2026-05-19T12:30:00.000Z',
      });

      expect(entry.isOpenSession, isFalse);
      expect(entry.clockOutAt, isNotNull);
    });
  });
}
