import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Parent-facing backup: zips every saved artwork plus the reward progress
/// and hands the archive to the system share sheet. Fully offline; nothing
/// is uploaded anywhere.
///
/// Export only for now — restoring needs a file picker plus merge rules, so
/// the manifest carries a [kBackupFormat] version to make that possible
/// later without guessing.
const int kBackupFormat = 1;

/// Device-specific parent preferences (settings.json) are deliberately
/// excluded — nothing precious, and they should not travel between devices.
Future<File> createBackupZip() async {
  final docs = await getApplicationDocumentsDirectory();
  final tmp = await getTemporaryDirectory();
  final stamp = DateTime.now();
  final name = 'pixiepaint_backup_'
      '${stamp.year}${_two(stamp.month)}${_two(stamp.day)}.zip';
  final outPath = '${tmp.path}/$name';
  final docsPath = docs.path;
  final manifest = jsonEncode({
    'format': kBackupFormat,
    'exportedAt': stamp.toIso8601String(),
  });

  await Isolate.run(() => writeBackupZip(docsPath, outPath, manifest));
  return File(outPath);
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Runs in an isolate: streams file by file into the archive so a big
/// gallery never sits in memory at once. Paths inside the archive are
/// relative to the documents dir — that layout is the contract a future
/// restore will rely on, so it is covered by tests.
void writeBackupZip(String docsPath, String outPath, String manifest) {
  final encoder = ZipFileEncoder();
  encoder.create(outPath);
  try {
    final artworks = Directory('$docsPath/artworks');
    if (artworks.existsSync()) {
      for (final entry in artworks.listSync(recursive: true)) {
        if (entry is! File) continue;
        final rel = entry.path.substring(docsPath.length + 1);
        encoder.addFileSync(entry, rel);
      }
    }
    final progress = File('$docsPath/progress.json');
    if (progress.existsSync()) {
      encoder.addFileSync(progress, 'progress.json');
    }
    final stickers = Directory('$docsPath/stickers');
    if (stickers.existsSync()) {
      for (final entry in stickers.listSync()) {
        if (entry is! File) continue;
        encoder.addFileSync(entry, entry.path.substring(docsPath.length + 1));
      }
    }
    encoder.addArchiveFile(
        ArchiveFile.string('manifest.json', manifest));
  } finally {
    encoder.closeSync();
  }
}

/// Shares the archive, then removes the temp copy.
Future<void> shareBackupZip(File zip) async {
  try {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(zip.path, mimeType: 'application/zip')]),
    );
  } finally {
    if (await zip.exists()) await zip.delete();
  }
}
