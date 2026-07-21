import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/fill_pattern.dart';
import 'package:pixiepaint/models/draw_op.dart';
import 'package:pixiepaint/models/tool.dart';

void main() {
  test('stroke op round-trips through JSON', () {
    final op = StrokeOp(
      toolKind: ToolKind.glitter,
      color: 0xFFE53935,
      baseWidth: 28.04,
      seed: 12345,
      symmetryFolds: 6,
      points: [10.04, 20.06, 0.5, 30.0, 40.0, 0.75],
    );
    final decoded =
        decodeOps(encodeOps([op])).single as StrokeOp;
    expect(decoded.toolKind, ToolKind.glitter);
    expect(decoded.color, 0xFFE53935);
    expect(decoded.baseWidth, closeTo(28.0, 0.1));
    expect(decoded.seed, 12345);
    expect(decoded.symmetryFolds, 6);
    expect(decoded.points, hasLength(6));
    expect(decoded.points[0], closeTo(10.0, 0.1));
    expect(decoded.points[5], closeTo(0.75, 0.01));
  });

  test('stamp, shape, fill and clear ops round-trip', () {
    final ops = [
      StampOp(emoji: '🦄', x: 100, y: 200, size: 220, symmetryFolds: 2),
      StampOp(
          imagePath: '/x/sticker.png', x: 1, y: 2, size: 140, symmetryFolds: 1),
      ShapeOp(
          kind: ShapeKind.star,
          x: 512,
          y: 384,
          radius: 99,
          color: 0xFF00FF00,
          strokeWidth: 11.2),
      FillOp(x: 5, y: 6, color: 0xFF123456, pattern: FillPattern.hearts),
      const ClearOp(),
    ];
    final decoded = decodeOps(encodeOps(ops));
    expect(decoded, hasLength(5));
    expect((decoded[0] as StampOp).emoji, '🦄');
    expect((decoded[1] as StampOp).imagePath, '/x/sticker.png');
    expect((decoded[2] as ShapeOp).kind, ShapeKind.star);
    expect((decoded[3] as FillOp).pattern, FillPattern.hearts);
    expect(decoded[4], isA<ClearOp>());
  });

  test('unknown tool/shape/pattern names fall back to safe defaults', () {
    final json =
        '{"v":1,"ops":[{"t":"s","k":"laserPen","c":1,"w":10,"sd":0,"p":[]},'
        '{"t":"h","k":"hexagon","x":0,"y":0,"r":10,"c":2,"w":4},'
        '{"t":"f","x":0,"y":0,"c":3,"pt":"plaid"}]}';
    final ops = decodeOps(json);
    expect((ops[0] as StrokeOp).toolKind, ToolKind.brush);
    expect((ops[1] as ShapeOp).kind, ShapeKind.heart);
    expect((ops[2] as FillOp).pattern, FillPattern.solid);
  });

  test('unknown op types are skipped, not fatal', () {
    const json =
        '{"v":1,"ops":[{"t":"z","weird":true},{"t":"c"}]}';
    final ops = decodeOps(json);
    expect(ops, hasLength(1));
    expect(ops.single, isA<ClearOp>());
  });

  test('garbage input decodes to an empty list', () {
    expect(decodeOps('not json'), isEmpty);
    expect(decodeOps('{"v":1}'), isEmpty);
    expect(decodeOps('[]'), isEmpty);
  });

  test('default symmetry and solid pattern are omitted from JSON', () {
    final stroke = StrokeOp(
        toolKind: ToolKind.brush,
        color: 1,
        baseWidth: 10,
        seed: 0,
        symmetryFolds: 1,
        points: []);
    expect(stroke.toJson().containsKey('sy'), isFalse);
    final fill =
        FillOp(x: 0, y: 0, color: 1, pattern: FillPattern.solid);
    expect(fill.toJson().containsKey('pt'), isFalse);
  });
}
