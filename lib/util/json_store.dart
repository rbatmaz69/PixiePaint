import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    } catch (_) {
      // Storage full or permissions — keep the previous file untouched.
      try {
        if (await _tmpFile.exists()) await _tmpFile.delete();
      } catch (_) {}
    }
  }

  /// Waits for all queued writes — used before the app expects the file to
  /// be on disk (tests, backup export).
  Future<void> flush() => _queue;
}
