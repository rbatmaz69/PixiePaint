import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Called when a write below fails. Every failure here is swallowed on
/// purpose — the previous file stays intact, which is the right thing for the
/// data — but silence was the wrong thing for the *diagnosis*: "a picture was
/// gone" is all anyone could report. The app sets this at startup to feed
/// `ErrorLog`; it stays a hook rather than a direct call so this file keeps
/// depending on nothing (and so `ErrorLog`, which writes through it, does not
/// import itself in a circle).
void Function(Object error, StackTrace stack, String path)? onPersistFailure;

void _reportFailure(Object error, StackTrace stack, String path) {
  try {
    onPersistFailure?.call(error, stack, path);
  } catch (_) {
    // A failing reporter must not turn a survivable write failure into a
    // crash.
  }
}

/// A small, crash-safe JSON file.
///
/// The settings and progress files are written from fire-and-forget void
/// mutators — `registerToolUsed` fires on *every* stroke commit, and a
/// finished color-by-number page persists twice in the same event-loop
/// turn. Plain `writeAsString` truncates and does not serialize its
/// callers, so two overlapping writes can interleave into invalid JSON and
/// silently wipe a kid's whole reward progress.
///
/// This class removes that class of failure:
/// * writes are queued, so they can never interleave;
/// * each write goes to `<name>.tmp` and is then renamed over the target,
///   which is atomic — a crash mid-write leaves the old file intact;
/// * an unreadable file is moved aside as `<name>.corrupt.json` instead of
///   being silently overwritten with defaults, so it can be inspected.
class JsonStore {
  JsonStore(this.file);

  final File file;

  Future<void> _queue = Future.value();

  File get _tmpFile => File('${file.path}.tmp');
  File get _corruptFile => File('${file.path}.corrupt.json');

  /// Reads and decodes the file. Returns null when it does not exist yet or
  /// cannot be parsed; a corrupt file is preserved for inspection.
  Future<Map<String, dynamic>?> read() async {
    try {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      try {
        if (await file.exists()) await file.rename(_corruptFile.path);
      } catch (_) {}
      return null;
    }
  }

  /// Queues an atomic write. Awaiting the returned future is optional —
  /// ordering is guaranteed either way.
  Future<void> write(Map<String, dynamic> json) {
    final encoded = jsonEncode(json);
    _queue = _queue.then((_) => _writeAtomic(encoded)).catchError((_) {});
    return _queue;
  }

  Future<void> _writeAtomic(String encoded) async {
    try {
      await _tmpFile.writeAsString(encoded, flush: true);
      await _tmpFile.rename(file.path);
    } catch (e, s) {
      // Storage full or permissions — keep the previous file untouched, and
      // say so in the error log.
      _reportFailure(e, s, file.path);
      try {
        if (await _tmpFile.exists()) await _tmpFile.delete();
      } catch (_) {}
    }
  }

  /// Waits for all queued writes — used before the app expects the file to
  /// be on disk (tests, backup export).
  Future<void> flush() => _queue;
}

/// Writes [bytes] to [file] without ever leaving a half-written file behind:
/// the data goes to `<path>.tmp` and is then renamed over the target, which
/// the filesystem performs atomically.
///
/// Returns false when the write failed (storage full, no permission) — the
/// previous version of [file] is then still intact and readable. Callers that
/// write several files as one unit should write the file that *identifies*
/// the unit last, so a failure leaves the older, consistent state.
///
/// This is the free-standing sibling of [JsonStore], for callers that write
/// many different paths (one directory per artwork) rather than one file
/// over and over.
/// Pass `report: false` only for the error log itself — see [_atomic].
Future<bool> atomicWriteBytes(File file, List<int> bytes,
        {bool report = true}) =>
    _atomic(file, (tmp) => tmp.writeAsBytes(bytes, flush: true), report);

/// String variant of [atomicWriteBytes].
Future<bool> atomicWriteString(File file, String contents,
        {bool report = true}) =>
    _atomic(file, (tmp) => tmp.writeAsString(contents, flush: true), report);

/// [report] exists for exactly one caller: the error log writes through here
/// too, and reporting *its* failure would record an entry, which persists,
/// which fails, which records — a loop that ends in a hung queue rather than
/// a useful log.
Future<bool> _atomic(
  File file,
  Future<void> Function(File tmp) write, [
  bool report = true,
]) async {
  final tmp = File('${file.path}.tmp');
  try {
    await write(tmp);
    await tmp.rename(file.path);
    return true;
  } catch (e, s) {
    if (report) _reportFailure(e, s, file.path);
    try {
      if (await tmp.exists()) await tmp.delete();
    } catch (_) {}
    return false;
  }
}
