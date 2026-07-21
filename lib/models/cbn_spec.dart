import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// Sidecar data for a color-by-number page: the numbered palette and the
/// label positions (canvas coordinates, 2048×1536).
class CbnLabel {
  final int number;
  final Offset pos;

  const CbnLabel(this.number, this.pos);
}

class CbnSpec {
  final List<int> numbers; // sorted, unique
  final Map<int, Color> colorOf;
  final List<CbnLabel> labels;

  const CbnSpec({
    required this.numbers,
    required this.colorOf,
    required this.labels,
  });

  static Future<CbnSpec?> load(String pageId) async {
    try {
      final raw = await rootBundle
          .loadString('assets/coloring_pages/cbn/$pageId.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final colorOf = <int, Color>{};
      for (final e in (json['palette'] as List)) {
        final n = e['n'] as int;
        final hex = (e['color'] as String).replaceFirst('#', '');
        colorOf[n] = Color(int.parse(hex, radix: 16) | 0xFF000000);
      }
      final labels = <CbnLabel>[
        for (final e in (json['labels'] as List))
          CbnLabel(
            e['n'] as int,
            Offset((e['x'] as num).toDouble(), (e['y'] as num).toDouble()),
          ),
      ];
      final numbers = colorOf.keys.toList()..sort();
      return CbnSpec(numbers: numbers, colorOf: colorOf, labels: labels);
    } catch (_) {
      return null;
    }
  }
}
