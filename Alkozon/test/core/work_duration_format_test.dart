import 'package:alkozon/features/work_time/presentation/controllers/work_timer_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDurationSeconds', () {
    test('formats zero', () {
      expect(formatDurationSeconds(0), '00:00:00');
    });

    test('formats hours minutes and seconds', () {
      expect(formatDurationSeconds(3661), '01:01:01');
    });

    test('pads single digit segments', () {
      expect(formatDurationSeconds(65), '00:01:05');
    });
  });
}
