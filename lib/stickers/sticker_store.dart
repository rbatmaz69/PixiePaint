import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../util/json_store.dart';

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

  /// Writes a new sticker, or returns null when it could not be stored
  /// (full disk, unwritable directory). Atomic on purpose: a sticker
  /// interrupted halfway through would sit in the album as an undecodable
  /// file forever, and unlike an artwork there is no older version to fall
  /// back to.
  ///
  /// Null covers the whole operation, not just the last step — creating the
  /// directory can fail for exactly the same reasons as writing into it,
  /// and the capture screen has one way to say "that didn't work".
  static Future<File?> save(Uint8List png) async {
    try {
      final root = await _root();
      final file = File('${root.path}/${const Uuid().v4()}.png');
      if (!await atomicWriteBytes(file, png)) return null;
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Deleting a sticker never touches artworks — stamped copies are baked
  /// into their paint layers.
  static Future<void> delete(File file) async {
    if (await file.exists()) await file.delete();
  }
}
