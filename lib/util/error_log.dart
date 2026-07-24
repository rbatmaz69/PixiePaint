import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_version.dart';
import 'json_store.dart';

/// Where an error was caught. Not a severity — every entry here is something
/// that should not have happened; the origin tells whoever reads the report
/// which door it came through.
enum ErrorOrigin {
  /// `FlutterError.onError` — a build, layout or paint threw.
  flutter,

  /// `PlatformDispatcher.onError` — an async error nobody awaited.
  platform,

  /// The zone around `runApp` caught it, so neither handler above did.
  zone,

  /// A write to disk failed. The rarest and by far the most interesting one:
  /// it means a picture, a setting or a reward did not persist.
  save,
}

/// One recorded error, as it lands in the log file.
class ErrorEntry {
  ErrorEntry({
    required this.time,
    required this.origin,
    required this.message,
    this.stack = '',
    this.detail,
    this.count = 1,
  });

  /// When the error was *first* seen. Repeats within [ErrorLog.dedupWindow]
  /// raise [count] instead of adding an entry, so the timestamp stays the
  /// one that matters for reproducing it.
  final DateTime time;
  final ErrorOrigin origin;
  final String message;
  final String stack;

  /// Extra context that is not part of the message — the (redacted) path for
  /// a failed write, for instance.
  final String? detail;

  int count;

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'o': origin.name,
        'm': message,
        if (stack.isNotEmpty) 's': stack,
        if (detail != null) 'd': detail,
        if (count > 1) 'n': count,
      };

  /// Returns null for anything that is not a well-formed entry — a truncated
  /// last line must cost that line, not the whole log.
  static ErrorEntry? fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['t'] as String? ?? '');
    final message = json['m'] as String?;
    if (time == null || message == null || message.isEmpty) return null;
    return ErrorEntry(
      time: time,
      origin: ErrorOrigin.values.firstWhere(
        (o) => o.name == json['o'],
        orElse: () => ErrorOrigin.zone,
      ),
      message: message,
      stack: json['s'] as String? ?? '',
      detail: json['d'] as String?,
      count: (json['n'] as int?) ?? 1,
    );
  }
}

/// The app's only record of things going wrong.
///
/// PixiePaint ships no analytics and no crash reporter — that is a promise to
/// parents, not an oversight. But it left the app with *nothing at all*: a
/// crash on a real device used to be unreproducible by the time anyone talked
/// about it. This is the local substitute. It stays on the device until a
/// parent decides to share it.
///
/// What is recorded: time, app version, where it was caught, the first line
/// of the message and a shortened stack. What is not: no device identifiers,
/// no picture content, no child names, and no absolute paths — the documents
/// directory is replaced by `<docs>`, because on iOS it contains an install
/// UUID and its subpaths contain artwork ids.
class ErrorLog {
  ErrorLog._();
  static final ErrorLog instance = ErrorLog._();

  /// Two independent ceilings. The count keeps the parents' list readable,
  /// the byte cap is what actually protects the device: a single pathological
  /// stack can be larger than thirty ordinary ones.
  static const int maxEntries = 30;
  static const int maxBytes = 32 * 1024;

  /// A failing painter throws once per frame. Without this window a five
  /// second glitch would write three hundred identical entries and push
  /// everything useful out of the log.
  static const Duration dedupWindow = Duration(seconds: 60);

  /// Anything past this is not our file any more (or not one worth reading);
  /// it is moved aside rather than parsed.
  static const int _maxReadBytes = 512 * 1024;

  static const int _maxMessageChars = 200;
  static const int _maxStackFrames = 12;

  /// Oldest first — the same order the file has, so appending is the common
  /// case and trimming always takes from the front.
  final List<ErrorEntry> _entries = [];

  File? _file;
  String? _docsPath;
  DateTime? _lastRecordAt;
  Future<void> _queue = Future.value();

  /// Newest first, for the parents' list.
  List<ErrorEntry> get entries => _entries.reversed.toList(growable: false);

  int get count => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  /// Reads the existing log and starts persisting. Errors recorded before
  /// this ran are kept in memory and joined here — startup failures are the
  /// ones worth having most, and they happen before any directory is known.
  Future<void> init() async {
    try {
      await initIn(await getApplicationDocumentsDirectory());
    } catch (_) {
      // No documents directory means no log. Recording still works in
      // memory, which is all this session can offer.
    }
  }

  /// Seam for tests: use any directory instead of the documents dir.
  @visibleForTesting
  Future<void> initIn(Directory dir) async {
    _docsPath = dir.path;
    _file = File('${dir.path}/errors.log');
    final buffered = _entries.length;
    final fromDisk = await _read();
    // Whatever this session recorded before init is newer than the file.
    _entries.insertAll(0, fromDisk);
    _trim();
    // Those buffered entries have never been written — their `record` call
    // had no file to write to. Without this the most interesting errors of
    // all, the ones from startup, would live only until the app is closed.
    if (buffered > 0) await _persist();
  }

  /// Records an error. Never throws and never awaits — it is called from
  /// error handlers, and an error handler that can fail is a crash loop.
  void record(
    Object error,
    StackTrace? stack, {
    required ErrorOrigin origin,
    String? detail,
  }) {
    try {
      final message = _shortenMessage(error.toString());
      final now = DateTime.now();
      final last = _entries.isEmpty ? null : _entries.last;

      // Matched on the message alone, not on the origin: the same failure can
      // arrive through two doors in one frame (a throwing build reaches
      // `FlutterError.onError`, and its replacement widget is built right
      // after), and an alternating origin would defeat the window entirely.
      if (last != null &&
          last.message == message &&
          _lastRecordAt != null &&
          now.difference(_lastRecordAt!) < dedupWindow) {
        last.count++;
        _lastRecordAt = now;
      } else {
        _entries.add(ErrorEntry(
          time: now,
          origin: origin,
          message: message,
          stack: _shortenStack(stack),
          detail: detail == null ? null : _redact(detail),
        ));
        _lastRecordAt = now;
      }
      _trim();
      unawaited(_persist());
    } catch (_) {
      // Recording must never be the thing that takes the app down.
    }
  }

  /// Empties the log, file included.
  Future<void> clear() async {
    _entries.clear();
    _lastRecordAt = null;
    await _persist();
  }

  /// The shareable report: a plain-text file a parent can send on. Kept
  /// deliberately boring and readable — the person reading it may well be
  /// the parent themselves.
  ///
  /// [note] is the one human sentence in it and therefore comes from the
  /// caller, translated; everything below it is timestamps, origins and
  /// stacks, which no translation would improve.
  String asReport({String? note}) {
    final out = StringBuffer()
      ..writeln('PixiePaint $kAppVersion — ${_platformName()}')
      ..writeln('${_entries.length} entries');
    if (note != null) out.writeln(note);
    out.writeln();
    for (final e in entries) {
      out.writeln('— ${e.time.toIso8601String()} · ${e.origin.name}'
          '${e.count > 1 ? ' · ${e.count}×' : ''}');
      out.writeln(e.message);
      if (e.detail != null) out.writeln('(${e.detail})');
      if (e.stack.isNotEmpty) out.writeln(e.stack);
      out.writeln();
    }
    return out.toString();
  }

  /// Waits for the queued writes — used by the report export and by tests.
  Future<void> flush() => _queue;

  @visibleForTesting
  void resetForTest() {
    _entries.clear();
    _file = null;
    _docsPath = null;
    _lastRecordAt = null;
    _queue = Future.value();
  }

  // ---------------------------------------------------------------- private

  Future<List<ErrorEntry>> _read() async {
    final file = _file;
    if (file == null) return const [];
    try {
      if (!await file.exists()) return const [];
      if (await file.length() > _maxReadBytes) {
        await file.delete();
        return const [];
      }
      final entries = <ErrorEntry>[];
      for (final line in (await file.readAsString()).split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final decoded = jsonDecode(line);
          if (decoded is! Map<String, dynamic>) continue;
          final entry = ErrorEntry.fromJson(decoded);
          if (entry != null) entries.add(entry);
        } catch (_) {
          // One unreadable line, not one unreadable log.
        }
      }
      return entries;
    } catch (_) {
      return const [];
    }
  }

  /// One JSON object per line: a half-written last line costs that entry and
  /// leaves the rest readable. The write itself goes through
  /// [atomicWriteString], like every other write in this app.
  Future<void> _persist() {
    final file = _file;
    if (file == null) return _queue;
    final encoded = _encode();
    _queue = _queue.then((_) async {
      // `report: false` for the obvious reason: this *is* the error report.
      await atomicWriteString(file, encoded, report: false);
    }).catchError((_) {});
    return _queue;
  }

  String _encode() => _entries.map((e) => jsonEncode(e.toJson())).join('\n');

  /// Enforces both ceilings, oldest first. Always leaves at least one entry:
  /// a single entry too big for the cap is still the entry worth having.
  void _trim() {
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    while (_entries.length > 1 && _encode().length > maxBytes) {
      _entries.removeAt(0);
    }
  }

  String _shortenMessage(String raw) {
    final firstLine = raw.split('\n').first.trim();
    final redacted = _redact(firstLine.isEmpty ? raw.trim() : firstLine);
    return redacted.length <= _maxMessageChars
        ? redacted
        : '${redacted.substring(0, _maxMessageChars)}…';
  }

  String _shortenStack(StackTrace? stack) {
    if (stack == null) return '';
    final frames = stack
        .toString()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(_maxStackFrames)
        .map(_redact)
        .toList();
    return frames.join('\n');
  }

  /// Strips the documents path. It is the only absolute path that reaches
  /// these strings, and it is the only one that says anything about the
  /// person using the device.
  String _redact(String text) {
    final docs = _docsPath;
    if (docs == null || docs.isEmpty) return text;
    return text.replaceAll(docs, '<docs>');
  }

  String _platformName() {
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}

/// Writes the report to a throwaway file and opens the system share sheet —
/// the only way anything in the log ever leaves the device, and always by a
/// parent's deliberate tap (behind the parental gate, see the settings
/// screen).
///
/// Same reasoning as [shareArtwork] for the plain write: this is a temporary
/// file the share sheet consumes and we delete right after, so there is
/// nothing a crash could corrupt.
Future<void> shareErrorReport({String? note}) async {
  final text = ErrorLog.instance.asReport(note: note);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/pixiepaint-report.txt');
  await file.writeAsString(text, flush: true);
  try {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'text/plain')]),
    );
  } finally {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
