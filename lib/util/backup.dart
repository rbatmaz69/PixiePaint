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
/// format 1: single progress.json. format 2 (v6.6): per-profile
/// `progress_<id>.json` plus profiles.json.
const int kBackupFormat = 2;

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
    // Profiles and every per-profile progress file, plus the legacy
    // progress.json if a pre-profiles backup is ever restored onto an old
    // build. `listSync` on the docs root keeps this to one directory scan.
    for (final entry in Directory(docsPath).listSync()) {
      if (entry is! File) continue;
      final rel = entry.path.substring(docsPath.length + 1);
      if (rel == 'profiles.json' ||
          rel == 'progress.json' ||
          (rel.startsWith('progress_') && rel.endsWith('.json'))) {
        encoder.addFileSync(entry, rel);
      }
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

/// Why a chosen file could not be restored. The UI turns these into one
/// sentence each — a parent picking the wrong file from their downloads is
/// the expected case, not an exception.
enum BackupRejection {
  /// Not a ZIP, or damaged beyond reading.
  unreadable,

  /// A ZIP, but not one of ours (no manifest.json).
  notABackup,

  /// Written by a newer PixiePaint than this one.
  tooNew,

  /// Absurdly large or with absurdly many entries — refused before unpacking.
  tooLarge,
}

class BackupRejected implements Exception {
  const BackupRejected(this.reason);
  final BackupRejection reason;
}

class RestoreResult {
  const RestoreResult({required this.restored, required this.skipped});

  /// Artworks written to disk.
  final int restored;

  /// Artworks already present under the same id and therefore left alone.
  final int skipped;
}

/// Where a restore parks the backup's kid list for [ProfileStore] to merge.
/// Never `profiles.json` itself — that one belongs to this device.
const String kRestoredProfilesFile = 'profiles.restored.json';

/// Hard ceilings, checked before a single byte is unpacked. A backup of a
/// full gallery is a few hundred MB at most; anything beyond this is either
/// broken or hostile (a zip bomb).
const int _kMaxEntries = 20000;
const int _kMaxTotalBytes = 2 * 1024 * 1024 * 1024;

/// Restores a backup ZIP into the documents dir. Additive: an artwork whose
/// id already exists is left untouched, so restoring onto a device that has
/// been painted on never destroys the newer pictures.
Future<RestoreResult> restoreBackup(String zipPath) async {
  final docs = await getApplicationDocumentsDirectory();
  final docsPath = docs.path;
  return Isolate.run(() => restoreBackupZip(zipPath, docsPath));
}

/// Runs in an isolate. Throws [BackupRejected] for a file we refuse to
/// unpack.
///
/// The ZIP arrives from outside the app — cloud storage, mail, another
/// device — so every entry is treated as hostile until proven otherwise:
/// the resolved destination has to sit inside [docsPath] (that is what
/// stops `../../` escapes), and the path has to match one of the shapes the
/// export actually produces.
RestoreResult restoreBackupZip(String zipPath, String docsPath) {
  final input = InputFileStream(zipPath);
  final Archive archive;
  try {
    archive = ZipDecoder().decodeStream(input);
  } catch (_) {
    throw const BackupRejected(BackupRejection.unreadable);
  }

  if (archive.files.length > _kMaxEntries) {
    throw const BackupRejected(BackupRejection.tooLarge);
  }
  var totalBytes = 0;
  for (final file in archive.files) {
    totalBytes += file.size;
    if (totalBytes > _kMaxTotalBytes) {
      throw const BackupRejected(BackupRejection.tooLarge);
    }
  }

  final manifests = archive.files.where((f) => f.name == 'manifest.json');
  if (manifests.isEmpty) {
    throw const BackupRejected(BackupRejection.notABackup);
  }
  try {
    final manifest = jsonDecode(utf8.decode(manifests.first.readBytes()!))
        as Map<String, dynamic>;
    final format = manifest['format'];
    if (format is! int) throw const BackupRejected(BackupRejection.notABackup);
    if (format > kBackupFormat) {
      throw const BackupRejected(BackupRejection.tooNew);
    }
  } on BackupRejected {
    rethrow;
  } catch (_) {
    throw const BackupRejected(BackupRejection.notABackup);
  }

  final docsDir = Directory(docsPath);
  // Resolving the root once lets every entry be checked against the real
  // path, so a symlinked documents dir cannot be used to slip outside.
  final rootPath = docsDir.absolute.path;
  // An artwork id we have already decided to skip: the whole directory is
  // skipped with it, not just the file that happened to come first.
  final skippedIds = <String>{};
  final restoredIds = <String>{};
  // Written after everything else — see the comment at the deferral below.
  final deferredMeta = <(File, List<int>)>[];

  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final parts = _restorableSegments(entry.name);
    if (parts == null) continue;

    // The kid list is never written over the live one — this device already
    // has profiles (the first launch creates one), and the ids inside the
    // backup are what the restored pictures are stamped with. It lands
    // beside it under [kRestoredProfilesFile] for ProfileStore to merge, so
    // the pictures end up under the kid who painted them.
    final isProfileList = parts.length == 1 && parts.first == 'profiles.json';

    // Built from the *validated* segments, never from the raw entry name —
    // so what was checked and what gets written can never drift apart.
    final target = File(_under(
        rootPath, isProfileList ? [kRestoredProfilesFile] : parts));
    if (!_isInside(rootPath, target.absolute.path)) continue;

    final artworkId =
        parts.length >= 3 && parts.first == 'artworks' ? parts[1] : null;
    if (artworkId != null) {
      if (skippedIds.contains(artworkId)) continue;
      if (!restoredIds.contains(artworkId) &&
          Directory(_under(rootPath, ['artworks', artworkId])).existsSync()) {
        skippedIds.add(artworkId);
        continue;
      }
      restoredIds.add(artworkId);
    } else if (!isProfileList && target.existsSync()) {
      // progress_<id>.json: this device's own reward progress wins. A file
      // for a kid it has never seen carries no collision, so it lands.
      continue;
    }

    final bytes = entry.readBytes();
    if (bytes == null) continue;
    // meta.json is what makes an artwork visible to the gallery, so it goes
    // down last — exactly as ArtworkStore.save does it. A restore that dies
    // halfway then leaves directories the gallery simply ignores, rather
    // than half-copied pictures a kid would find broken.
    if (parts.length >= 3 && parts.last == 'meta.json') {
      deferredMeta.add((target, bytes));
      continue;
    }
    if (!_writeAtomicSync(target, bytes)) continue;
  }

  for (final (target, bytes) in deferredMeta) {
    _writeAtomicSync(target, bytes);
  }

  return RestoreResult(
    restored: restoredIds.length,
    skipped: skippedIds.length,
  );
}

/// Writes [bytes] to [target] via a temp file and a rename, the sync twin
/// of [atomicWriteBytes] — this runs inside an isolate where the async
/// helpers cannot be awaited. Returns false when the write failed; a
/// partially restored file must never be left behind.
bool _writeAtomicSync(File target, List<int> bytes) {
  final tmp = File('${target.path}.tmp');
  try {
    target.parent.createSync(recursive: true);
    tmp.writeAsBytesSync(bytes, flush: true);
    tmp.renameSync(target.path);
    return true;
  } catch (_) {
    try {
      if (tmp.existsSync()) tmp.deleteSync();
    } catch (_) {}
    return false;
  }
}

/// Splits an entry name into path segments, or returns null when the entry
/// is not one of the shapes [writeBackupZip] produces — an absolute path,
/// anything containing `..`, a drive letter, or a stray file someone added
/// to the ZIP by hand.
List<String>? _restorableSegments(String name) {
  if (name.isEmpty) return null;
  if (name.startsWith('/') || name.startsWith(r'\')) return null;
  if (name.contains(':')) return null;
  final parts = name.split(RegExp(r'[/\\]'));
  if (parts.any((s) => s == '..' || s == '.' || s.isEmpty)) return null;
  if (parts.first == 'artworks') return parts.length >= 3 ? parts : null;
  if (parts.first == 'stickers') return parts.length == 2 ? parts : null;
  if (parts.length != 1) return null;
  final file = parts.first;
  final known = file == 'profiles.json' ||
      file == 'progress.json' ||
      (file.startsWith('progress_') && file.endsWith('.json'));
  return known ? parts : null;
}

String _under(String root, List<String> segments) =>
    [root, ...segments].join(Platform.pathSeparator);

/// True when [path] sits genuinely below [root] — the last line of defence
/// against a crafted entry name (zip slip).
bool _isInside(String root, String path) {
  final normalizedRoot = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  return path.startsWith(normalizedRoot);
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
