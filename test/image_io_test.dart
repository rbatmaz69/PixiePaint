import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/image_io.dart';

void main() {
  group('containRect', () {
    test('wide source letterboxes top/bottom', () {
      final r = containRect(const Size(4000, 1000), const Size(2048, 1536));
      expect(r.width, 2048);
      expect(r.height, closeTo(512, 0.001));
      expect(r.left, 0);
      expect(r.top, closeTo((1536 - 512) / 2, 0.001));
    });

    test('tall source letterboxes left/right', () {
      final r = containRect(const Size(1000, 2000), const Size(2048, 1536));
      expect(r.height, 1536);
      expect(r.width, closeTo(768, 0.001));
      expect(r.top, 0);
      expect(r.left, closeTo((2048 - 768) / 2, 0.001));
    });

    test('same aspect fills exactly', () {
      final r = containRect(const Size(1024, 768), const Size(2048, 1536));
      expect(r, const Rect.fromLTWH(0, 0, 2048, 1536));
    });

    test('preserves aspect ratio', () {
      const src = Size(3123, 1717);
      final r = containRect(src, const Size(2048, 1536));
      expect(r.width / r.height, closeTo(src.width / src.height, 0.0001));
    });
  });
}
