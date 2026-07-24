/// Picks the name of a *piece of content* — a picture, a scene, a daily task
/// — for [languageCode].
///
/// The app's own texts live in the ARB files; these do not. A motif name
/// belongs to the thing it names, right next to the file in `pages.json` or
/// the entry in `kDailyTasks`, so adding a picture stays one edit instead of
/// nine. Until v7.6 the model only knew German and English, which meant a
/// Turkish child got a translated interface around a German picture name.
///
/// Order: the map for the exact language, then English, then German. The
/// German fallback is the last resort rather than the default, because an
/// unsupported system language resolves to German anyway (see
/// `supportedLocales` in `app.dart`).
String localizedName(
  String languageCode, {
  required String de,
  String? en,
  Map<String, String>? more,
}) {
  if (languageCode == 'de') return de;
  final translated = more?[languageCode];
  if (translated != null && translated.isNotEmpty) return translated;
  return en ?? de;
}

/// Reads the `titles`/`categories`-style map off a decoded JSON entry.
/// Returns null when the key is absent, so an entry without translations
/// keeps working exactly as before.
Map<String, String>? namesFromJson(Object? raw) {
  if (raw is! Map) return null;
  final out = <String, String>{};
  raw.forEach((key, value) {
    if (key is String && value is String) out[key] = value;
  });
  return out.isEmpty ? null : out;
}
