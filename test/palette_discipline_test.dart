import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `pixie_palette.dart` calls itself *the one* color source, and the README
/// repeats it. Twice now that has quietly stopped being true — da6fbdf
/// gathered one batch of colors that had wandered off, and a second batch
/// had grown back by v8.6.
///
/// A claim that needs re-checking by hand is a claim that will be wrong
/// again. This is the check.
///
/// Every file that may still hold a raw value stands below **with the
/// reason it may**. Adding a file here is allowed — the point is not that
/// nobody ever writes a hex value again, it is that nobody writes one
/// without saying why.
const Map<String, String> _allowed = {
  'lib/ui/pixie_palette.dart': 'the source itself',
  'lib/ui/app_theme.dart':
      'the Material 3 seed — never painted, only divided into tones',
  'lib/util/color_utils.dart':
      'the sixteen paint colors and the grid neutrals: content, not surface',
  'lib/canvas/canvas_painter.dart':
      'the ink of a number chip, painted onto the picture',
  'lib/canvas/canvas_controller.dart':
      'white as the paper an export is laid on',
  'lib/canvas/shape_renderer.dart': 'the rainbow bands of a shape',
  'lib/canvas/stroke_renderer.dart': 'glitter, and the white a stroke fades into',
  'lib/trace/trace_template.dart': 'the tracing guide and its start dot',
  'lib/util/image_io.dart': 'white as the paper an export is laid on',
  'lib/photo/photo_lineart.dart': 'white as the paper a photo is laid on',
  'lib/widgets/fill_pattern_picker.dart':
      'an opaque alpha OR-ed onto a value that comes in at runtime',
};

/// Generated translations are none of this test's business.
bool _skip(String path) => path.startsWith('lib/l10n/');

void main() {
  final offenders = <String, int>{};
  final seen = <String>{};

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
    if (_skip(path)) continue;
    final hits = RegExp(r'Color\(0x').allMatches(entity.readAsStringSync());
    if (hits.isEmpty) continue;
    if (_allowed.containsKey(path)) {
      seen.add(path);
    } else {
      offenders[path] = hits.length;
    }
  }

  test('no colour lives outside the palette without a reason', () {
    expect(offenders, isEmpty,
        reason: 'These files hold raw colour values. Either derive them from '
            'PixiePalette, or add the file to _allowed with the reason it '
            'has to stay free.');
  });

  test('every reason on the list is still doing work', () {
    // Otherwise the list slowly becomes a list of places colours used to be,
    // and stops describing the app.
    expect(seen, unorderedEquals(_allowed.keys),
        reason: 'A file on the allow-list no longer holds a raw colour. '
            'Remove its entry.');
  });
}
