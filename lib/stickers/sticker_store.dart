import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Filesystem store for the kid's own stickers: 512 px RGBA PNGs with a
/// circular mask, one file per sticker in `<docs>/stickers/`.
class StickerStore {
  static const int maxStickers = 24;

  static Future<Directory> _root() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/stickers');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Newest first.
  static Future<List<File>> list() async {
    final root = await _root();
    final files = <File>[];
    await for (final entry in root.list()) {
      if (entry is File && entry.path.endsWith('.png')) files.add(entry);
    }
    files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  static Future<File> save(Uint8List png) async {
    final root = await _root();
    final file = File('${root.path}/${const Uuid().v4()}.png');
    await file.writeAsBytes(png);
    return file;
  }

  /// Deleting a sticker never touches artworks — stamped copies are baked
  /// into their paint layers.
  static Future<void> delete(File file) async {
    if (await file.exists()) await file.delete();
  }
}
