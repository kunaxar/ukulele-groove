import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele_groove/data.dart';

void main() {
  test('Every lesson has an available best-fit pattern and playable cycle', () {
    expect(lessons.length, 5);
    for (final lesson in lessons) {
      final best = patterns.firstWhere((p) => p['id'] == lesson['best']);
      expect(best['meter'], lesson['meter']);
      expect((best['steps'] as List).length, (lesson['meter'] as int) * 2);
      expect(lesson['options'] as List, contains(lesson['best']));
    }
  });
  test('Skips and mutes stay different', () {
    final island = patterns.firstWhere((p) => p['id'] == 'island');
    final chuck = patterns.firstWhere((p) => p['id'] == 'chuck');
    expect(island['steps'], contains('-'));
    expect(chuck['steps'], contains('X'));
  });
  test('Every lab slot can reach all four strokes from any starting value', () {
    expect(labStrokeCycle, ['D', 'U', 'X', '-']);
    for (final start in labStrokeCycle) {
      var stroke = start;
      final seen = <String>{};
      for (var tap = 0; tap < labStrokeCycle.length; tap++) {
        seen.add(stroke);
        stroke = nextLabStroke(stroke);
      }
      expect(seen, labStrokeCycle.toSet());
      expect(stroke, start);
    }
  });
  test('Lab supports up-first alternation in both lesson meters', () {
    for (final beats in [3, 4]) {
      final slots = List.generate(beats * 2, (i) => i.isEven ? 'D' : 'U');
      final upFirst = slots
          .map(
            (s) => s == 'D'
                ? nextLabStroke(s)
                : nextLabStroke(nextLabStroke(nextLabStroke(s))),
          )
          .toList();
      expect(upFirst, List.generate(beats * 2, (i) => i.isEven ? 'U' : 'D'));
    }
  });
}
