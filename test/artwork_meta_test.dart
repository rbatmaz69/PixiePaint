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
  });
}
