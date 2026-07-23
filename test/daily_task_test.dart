import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/models/daily_task.dart';

void main() {
  test('same date always yields the same task', () {
    final a = taskForDate(DateTime(2026, 7, 21));
    final b = taskForDate(DateTime(2026, 7, 21, 23, 59));
    expect(a.id, b.id);
  });

  test('consecutive days never repeat', () {
    var date = DateTime(2026, 1, 1);
    for (var i = 0; i < 400; i++) {
      final next = date.add(const Duration(days: 1));
      expect(taskForDate(date).id, isNot(taskForDate(next).id));
      date = next;
    }
  });

  test('the whole catalog is used before anything comes back', () {
    final seen = <String>{};
    var date = DateTime(2026, 3, 1);
    for (var i = 0; i < kDailyTasks.length; i++) {
      seen.add(taskForDate(date).id);
      date = date.add(const Duration(days: 1));
    }
    expect(seen.length, kDailyTasks.length);
  });

  test('dates before the epoch still resolve to a task', () {
    expect(() => taskForDate(DateTime(2020, 5, 4)), returnsNormally);
    expect(taskForDate(DateTime(2020, 5, 4)).id, isNotEmpty);
  });

  test('dayKey is zero-padded and stable within a day', () {
    expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    expect(dayKey(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
    expect(dayKey(DateTime(2026, 7, 4, 0, 1)), dayKey(DateTime(2026, 7, 4, 22)));
  });

  test('catalog entries are unique and fully bilingual', () {
    final ids = kDailyTasks.map((t) => t.id).toSet();
    expect(ids.length, kDailyTasks.length);
    for (final task in kDailyTasks) {
      expect(task.emoji, isNotEmpty);
      expect(task.titleFor('de'), isNotEmpty);
      expect(task.titleFor('en'), isNotEmpty);
      expect(task.titleFor('en'), isNot(task.titleFor('de')));
    }
  });

  group('isDayAfter', () {
    test('recognises the very next day', () {
      expect(isDayAfter('2026-07-21', '2026-07-22'), isTrue);
    });

    test('a gap is not a continuation', () {
      expect(isDayAfter('2026-07-21', '2026-07-23'), isFalse);
      expect(isDayAfter('2026-07-21', '2026-07-21'), isFalse);
      expect(isDayAfter('2026-07-22', '2026-07-21'), isFalse);
    });

    test('crosses month and year boundaries', () {
      expect(isDayAfter('2026-07-31', '2026-08-01'), isTrue);
      expect(isDayAfter('2026-12-31', '2027-01-01'), isTrue);
      expect(isDayAfter('2028-02-28', '2028-02-29'), isTrue,
          reason: '2028 is a leap year');
    });

    test('survives a daylight-saving switch', () {
      // Central European DST ends on 2026-10-25; that local day is 25 hours
      // long. Local-time arithmetic would drop it to zero days.
      expect(isDayAfter('2026-10-25', '2026-10-26'), isTrue);
      expect(isDayAfter('2026-03-29', '2026-03-30'), isTrue);
    });

    test('a missing or damaged key just means "not yesterday"', () {
      expect(isDayAfter('', '2026-07-22'), isFalse);
      expect(isDayAfter('gestern', '2026-07-22'), isFalse);
      expect(isDayAfter('2026-07', '2026-07-22'), isFalse);
    });
  });
}
