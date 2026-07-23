import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

/// How much of the device PixiePaint is using, for the parents' section.
///
/// The app never deletes anything on its own — a picture a kid painted is
/// not the app's to throw away — so this exists to let a parent see where
/// the space went and decide for themselves.
class StorageUsage {
  const StorageUsage({
    required this.artworkBytes,
    required this.stickerBytes,
    required this.artworkCount,
  });

  static const empty =
      StorageUsage(artworkBytes: 0, stickerBytes: 0, artworkCount: 0);

  final int artworkBytes;
  final int stickerBytes;

  /// Directories under `artworks/`, i.e. saved pictures including their
  /// thumbnails, photo backgrounds and time-lapse logs.
  final int artworkCount;

  int get totalBytes => artworkBytes + stickerBytes;
}

/// Walks the documents dir off the UI thread — a full gallery is thousands
/// of files and `statSync` on every one of them would drop frames.
Future<StorageUsage> readStorageUsage() async {
  final docs = await getApplicationDocumentsDirectory();
  final docsPath = docs.path;
  return Isolate.run(() => measureStorageUsage(docsPath));
}

/// Runs in an isolate. A file that vanishes mid-walk (a save finishing
/// alongside) is worth zero, never a crash.
StorageUsage measureStorageUsage(String docsPath) {
  var artworkBytes = 0;
  var stickerBytes = 0;
  var artworkCount = 0;

  final artworks = Directory('$docsPath/artworks');
  if (artworks.existsSync()) {
    for (final entry in artworks.listSync()) {
      if (entry is! Directory) continue;
      artworkCount++;
      for (final file in entry.listSync(recursive: true)) {
        if (file is File) artworkBytes += _sizeOf(file);
      }
    }
  }

  final stickers = Directory('$docsPath/stickers');
  if (stickers.existsSync()) {
    for (final file in stickers.listSync()) {
      if (file is File) stickerBytes += _sizeOf(file);
    }
  }

  return StorageUsage(
    artworkBytes: artworkBytes,
    stickerBytes: stickerBytes,
    artworkCount: artworkCount,
  );
}

int _sizeOf(File file) {
  try {
    return file.lengthSync();
  } catch (_) {
    return 0;
  }
}

/// Parent-facing size, one decimal from MB upwards. Deliberately plain
/// numbers — this is the one screen in the app written for an adult in a
/// hurry.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.round()} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(1)} GB';
}
