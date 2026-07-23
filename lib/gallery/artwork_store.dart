import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/artwork.dart';
import '../util/json_store.dart';

/// What [ArtworkStore.save] managed to put on disk.
///
/// [ok] is false when a file could not be written — full storage is the
/// realistic cause. The artwork on disk is then still the *previous*
/// version, never a half-written one, because meta.json is written last
/// and only after everything else succeeded.
class SaveResult {
  const SaveResult(this.artwork, {required this.ok});

  final Artwork artwork;
  final bool ok;
}

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

  static Future<SaveResult> save({
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
    // Every file goes down atomically and meta.json goes down *last*: it is
    // the commit marker. list() only accepts a directory that has a readable
    // meta.json, so a run that dies halfway leaves the previous version of
    // the picture intact instead of an unreadable one the gallery silently
    // drops — which, for a kid, means the picture is simply gone.
    var ok = true;
    if (paintPng != null) {
      ok &= await atomicWriteBytes(artwork.paintFile, paintPng);
    } else if (await artwork.paintFile.exists()) {
      await artwork.paintFile.delete();
    }
    if (backgroundPng != null) {
      ok &= await atomicWriteBytes(artwork.backgroundFile, backgroundPng);
    }
    if (lineArtPng != null) {
      ok &= await atomicWriteBytes(artwork.lineArtFile, lineArtPng);
    }
    // Mirrors the paint.png handling: an artwork undone back to blank must
    // not keep an old time-lapse that replays strokes it no longer has.
    if (opsJson != null) {
      ok &= await atomicWriteString(artwork.opsFile, opsJson);
    } else if (await artwork.opsFile.exists()) {
      await artwork.opsFile.delete();
    }
    ok &= await atomicWriteBytes(artwork.thumbFile, thumbPng);
    if (!ok) return SaveResult(old ?? artwork, ok: false);
    ok = await atomicWriteString(
        File('${dir.path}/meta.json'), jsonEncode(artwork.toJson()));
    return SaveResult(ok ? artwork : (old ?? artwork), ok: ok);
  }

  /// Rewrites only meta.json (rename/favorite) — PNGs and [Artwork.updatedAt]
  /// stay untouched, so thumbnails keep their cache identity.
  static Future<bool> updateMeta(Artwork artwork) => atomicWriteString(
      File('${artwork.dirPath}/meta.json'), jsonEncode(artwork.toJson()));

  static Future<void> delete(Artwork artwork) async {
    final dir = Directory(artwork.dirPath);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
