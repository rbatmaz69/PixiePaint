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
    String? traceId,
    String? sceneId,
    String? profileId,
    List<int>? cbnFilled,
    bool hasPhoto = false,
    bool hasPhotoLineArt = false,
    required int width,
    required int height,
    required Uint8List? paintPng,
    Uint8List? backgroundPng,
    Uint8List? lineArtPng,
    required Uint8List thumbPng,
    String? opsJson,
  }) async {
    final root = await _root();
    final dir = Directory('${root.path}/$id');
    if (!await dir.exists()) await dir.create();
    // save() rebuilds meta.json from scratch, so anything the caller does
    // not pass has to be carried over from the previous version — both the
    // gallery-managed fields (name, favorite) and the mode fields, which a
    // caller could otherwise silently erase on an autosave.
    String? name;
    var favorite = false;
    Artwork? old;
    final metaFile = File('${dir.path}/meta.json');
    try {
      if (await metaFile.exists()) {
        old = Artwork.fromJson(
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>,
            dir.path);
        name = old.name;
        favorite = old.favorite;
      }
    } catch (_) {
      // corrupt meta — rebuild it fresh
    }
    final artwork = Artwork(
      id: id,
      pageId: pageId ?? old?.pageId,
      traceId: traceId ?? old?.traceId,
      sceneId: sceneId ?? old?.sceneId,
      cbnFilled: cbnFilled ?? old?.cbnFilled ?? const [],
      hasPhoto: hasPhoto,
      hasPhotoLineArt: hasPhotoLineArt,
      width: width,
      height: height,
      updatedAt: DateTime.now(),
      dirPath: dir.path,
      name: name,
      favorite: favorite,
      profileId: profileId ?? old?.profileId,
    );
    if (paintPng != null) {
      await artwork.paintFile.writeAsBytes(paintPng);
    } else if (await artwork.paintFile.exists()) {
      await artwork.paintFile.delete();
    }
    if (backgroundPng != null) {
      await artwork.backgroundFile.writeAsBytes(backgroundPng);
    }
    if (lineArtPng != null) {
      await artwork.lineArtFile.writeAsBytes(lineArtPng);
    }
    // Mirrors the paint.png handling: an artwork undone back to blank must
    // not keep an old time-lapse that replays strokes it no longer has.
    if (opsJson != null) {
      await artwork.opsFile.writeAsString(opsJson);
    } else if (await artwork.opsFile.exists()) {
      await artwork.opsFile.delete();
    }
    await artwork.thumbFile.writeAsBytes(thumbPng);
    await File('${dir.path}/meta.json')
        .writeAsString(jsonEncode(artwork.toJson()));
    return artwork;
  }

  /// Rewrites only meta.json (rename/favorite) — PNGs and [Artwork.updatedAt]
  /// stay untouched, so thumbnails keep their cache identity.
  static Future<void> updateMeta(Artwork artwork) async {
    await File('${artwork.dirPath}/meta.json')
        .writeAsString(jsonEncode(artwork.toJson()));
  }

  static Future<void> delete(Artwork artwork) async {
    final dir = Directory(artwork.dirPath);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
