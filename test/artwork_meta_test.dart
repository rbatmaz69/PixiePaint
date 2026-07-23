import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/models/artwork.dart';

void main() {
  group('Artwork meta json', () {
    test('old-format meta without name/favorite parses with defaults', () {
      final artwork = Artwork.fromJson({
        'id': 'abc',
        'pageId': null,
        'hasPhoto': false,
        'hasPhotoLineArt': false,
        'width': 2048,
        'height': 1536,
        'updatedAt': '2026-01-01T12:00:00.000',
      }, '/tmp/abc');
      expect(artwork.name, isNull);
      expect(artwork.favorite, isFalse);
    });

    test('name and favorite survive a toJson/fromJson round-trip', () {
      final artwork = Artwork(
        id: 'abc',
        pageId: 'unicorn',
        width: 2048,
        height: 1536,
        updatedAt: DateTime(2026, 1, 1, 12),
        dirPath: '/tmp/abc',
        name: 'Mein Einhorn',
        favorite: true,
      );
      final back = Artwork.fromJson(artwork.toJson(), artwork.dirPath);
      expect(back.name, 'Mein Einhorn');
      expect(back.favorite, isTrue);
      expect(back.updatedAt, artwork.updatedAt);
      expect(back.pageId, 'unicorn');
    });

    test('copyWith only touches the given fields', () {
      final artwork = Artwork(
        id: 'abc',
        pageId: null,
        width: 10,
        height: 10,
        updatedAt: DateTime(2026),
        dirPath: '/tmp/abc',
      );
      final favored = artwork.copyWith(favorite: true);
      expect(favored.favorite, isTrue);
      expect(favored.name, isNull);
      expect(favored.id, 'abc');
      final named = favored.copyWith(name: 'Hallo');
      expect(named.name, 'Hallo');
      expect(named.favorite, isTrue);
    });

    test('mode fields round-trip and survive copyWith', () {
      final artwork = Artwork(
        id: 'abc',
        pageId: 'cbn_fish',
        traceId: 'letter_A',
        sceneId: 'meadow',
        cbnFilled: const [3, 7],
        width: 2048,
        height: 1536,
        updatedAt: DateTime(2026, 1, 1, 12),
        dirPath: '/tmp/abc',
      );
      final back = Artwork.fromJson(artwork.toJson(), artwork.dirPath);
      expect(back.traceId, 'letter_A');
      expect(back.sceneId, 'meadow');
      expect(back.cbnFilled, [3, 7]);
      // Renaming must not drop the mode a picture belongs to.
      final renamed = back.copyWith(name: 'Fisch');
      expect(renamed.traceId, 'letter_A');
      expect(renamed.sceneId, 'meadow');
      expect(renamed.cbnFilled, [3, 7]);
    });

    test('an empty cbnFilled is omitted and reads back as empty', () {
      final artwork = Artwork(
        id: 'abc',
        pageId: null,
        width: 10,
        height: 10,
        updatedAt: DateTime(2026),
        dirPath: '/tmp/abc',
      );
      expect(artwork.toJson().containsKey('cbnFilled'), isFalse);
      expect(Artwork.fromJson(artwork.toJson(), '/tmp/abc').cbnFilled, isEmpty);
    });
  });
}
