import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/models/artwork.dart';
import 'package:pixiepaint/canvas/fill_pattern.dart';
import 'package:pixiepaint/models/draw_op.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/story_stages.dart';

/// The film strip turns the op log into pictures. What must hold: the first
/// frame is the empty page, the last frame is the finished picture, and the
/// ones between are actually different from each other — six copies of the
/// same drawing would look like a bug and tell a child nothing about what
/// they did.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('pp_story'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Artwork artworkWith(List<DrawOp> ops, {bool scratch = false}) {
    File('${dir.path}/ops.json').writeAsStringSync(encodeOps(ops));
    return Artwork(
      id: 'a1b2c3d4',
      pageId: null,
      width: 128,
      height: 96,
      updatedAt: DateTime(2026, 7, 28),
      dirPath: dir.path,
      scratch: scratch,
    );
  }

  StrokeOp strokeAt(double y, int color) => StrokeOp(
        toolKind: ToolKind.brush,
        color: color,
        baseWidth: 14,
        seed: 1,
        symmetryFolds: 1,
        points: [8, y, 0.5, 120, y, 0.5],
      );

  test('an empty page first, the finished picture last', () async {
    final stages = await storyStages(
      artworkWith([
        strokeAt(15, 0xFFFF0000),
        strokeAt(30, 0xFF00FF00),
        strokeAt(45, 0xFF0000FF),
        strokeAt(60, 0xFFFF00FF),
        strokeAt(75, 0xFF00FFFF),
      ]),
      count: 4,
    );

    expect(stages.length, 4);
    // Frame one is the blank page: every later frame has more in it, so it
    // is the smallest PNG of the lot.
    expect(stages.first.length, lessThan(stages.last.length));
    expect(stages.first, isNot(stages.last));
  });

  test('every frame differs from the one before it', () async {
    final stages = await storyStages(
      artworkWith([
        strokeAt(15, 0xFFFF0000),
        strokeAt(30, 0xFF00FF00),
        strokeAt(45, 0xFF0000FF),
        strokeAt(60, 0xFFFF00FF),
        strokeAt(75, 0xFF00FFFF),
      ]),
      count: 6,
    );

    for (var i = 1; i < stages.length; i++) {
      expect(stages[i], isNot(stages[i - 1]),
          reason: 'frame ${i + 1} is a copy of frame $i');
    }
  });

  test('a short story gets fewer frames, not repeated ones', () async {
    // The count is a ceiling, not a promise: one stroke can only ever be two
    // pictures, before and after.
    final stages = await storyStages(artworkWith([strokeAt(20, 0xFFFF0000)]),
        count: 6);

    expect(stages.length, 2);
    expect(stages.first, isNot(stages.last));
  });

  test('a scratch picture opens on the covered page, not on the answer',
      () async {
    // Its first op is the cover — how the picture arrived, not something the
    // child did. A frame taken before it would be the bare colour sheet: the
    // one page they never saw, printed above the riddle it answers.
    final cover = FillOp(
        x: 0, y: 0, color: 0xFF15151A, pattern: FillPattern.solid);
    final scratched = await storyStages(
      artworkWith([cover, strokeAt(30, 0xFF000000)], scratch: true),
      count: 4,
    );
    final plain = await storyStages(
      artworkWith([cover, strokeAt(30, 0xFF000000)]),
      count: 4,
    );

    // The plain picture gets the empty page first; the scratch one does not,
    // so it has one frame fewer and starts somewhere else entirely.
    expect(scratched.length, lessThan(plain.length));
    expect(scratched.first, isNot(plain.first));
    expect(scratched.first, plain[1],
        reason: 'it opens on the page as the child found it: covered');
  });

  test('a picture with no story at all still yields the picture', () async {
    // Artworks from before the op log existed have no ops.json; the strip
    // must not come back empty for them.
    final artwork = Artwork(
      id: 'a1b2c3d4',
      pageId: null,
      width: 64,
      height: 48,
      updatedAt: DateTime(2026),
      dirPath: dir.path,
    );
    final stages = await storyStages(artwork, count: 6);

    expect(stages, hasLength(2));
    for (final png in stages) {
      expect(png, isA<Uint8List>());
      expect(png, isNotEmpty);
    }
  });

  test('an op that does nothing does not waste a frame', () async {
    // A fill on an empty free-draw canvas paints the whole page; a *second*
    // identical one changes nothing. The strip must not spend a frame on it.
    final stages = await storyStages(
      artworkWith([
        FillOp(x: 30, y: 30, color: 0xFF2196F3, pattern: FillPattern.solid),
        FillOp(x: 30, y: 30, color: 0xFF2196F3, pattern: FillPattern.solid),
      ]),
      count: 3,
    );
    expect(stages.length, 3);
    expect(stages[1], stages[2],
        reason: 'the repeated fill left the picture exactly as it was');
  });
}
