import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/artwork.dart';

/// Filesystem-backed store: one directory per artwork containing
/// paint.png (the paint layer), meta.json and thumb.png.
class ArtworkStore {
  static Future<Directory> _root() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/artworks');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String newId() => const Uuid().v4();

  static Future<List<Artwork>> list() async {
    final root = await _root();
    final artworks = <Artwork>[];
    await for (final entry in root.list()) {
      if (entry is! Directory) continue;
      final metaFile = File('${entry.path}/meta.json');
      try {
        if (await metaFile.exists()) {
          final json =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          artworks.add(Artwork.fromJson(json, entry.path));
        }
      } catch (_) {
        // skip corrupt entries
      }
    }
    artworks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return artworks;
  }

  static Future<Artwork> save({
    required String id,
    required String? pageId,
    bool hasPhoto = false,
    required int width,
    required int height,
    required Uint8List? paintPng,
    Uint8List? backgroundPng,
    required Uint8List thumbPng,
  }) async {
    final root = await _root();
    final dir = Directory('${root.path}/$id');
    if (!await dir.exists()) await dir.create();
    final artwork = Artwork(
      id: id,
      pageId: pageId,
      hasPhoto: hasPhoto,
      width: width,
      height: height,
      updatedAt: DateTime.now(),
      dirPath: dir.path,
    );
    if (paintPng != null) {
      await artwork.paintFile.writeAsBytes(paintPng);
    } else if (await artwork.paintFile.exists()) {
      await artwork.paintFile.delete();
    }
    if (backgroundPng != null) {
      await artwork.backgroundFile.writeAsBytes(backgroundPng);
    }
    await artwork.thumbFile.writeAsBytes(thumbPng);
    await File('${dir.path}/meta.json')
        .writeAsString(jsonEncode(artwork.toJson()));
    return artwork;
  }

  static Future<void> delete(Artwork artwork) async {
    final dir = Directory(artwork.dirPath);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
