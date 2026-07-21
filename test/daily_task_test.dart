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
}
