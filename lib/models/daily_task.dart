/// A small painting prompt shown once per day on the home screen.
///
/// Bilingual in the model (same trade-off as pages.json): keeping ~30
/// prompts out of the ARB files avoids 60 translation keys for content
/// that is really data.
class DailyTask {
  final String id;
  final String emoji;
  final String title;
  final String titleEn;

  const DailyTask({
    required this.id,
    required this.emoji,
    required this.title,
    required this.titleEn,
  });

  String titleFor(String languageCode) =>
      languageCode == 'en' ? titleEn : title;
}

const List<DailyTask> kDailyTasks = [
  DailyTask(id: 'red', emoji: '🍎', title: 'Male etwas Rotes!', titleEn: 'Paint something red!'),
  DailyTask(id: 'animals', emoji: '🐶', title: 'Stemple 5 Tiere!', titleEn: 'Stamp 5 animals!'),
  DailyTask(id: 'rainbowpen', emoji: '🌈', title: 'Male mit dem Regenbogen-Stift!', titleEn: 'Draw with the rainbow pen!'),
  DailyTask(id: 'sun', emoji: '☀️', title: 'Male eine Sonne!', titleEn: 'Paint a sun!'),
  DailyTask(id: 'butterfly', emoji: '🦋', title: 'Probiere den Zauber-Spiegel aus!', titleEn: 'Try the magic mirror!'),
  DailyTask(id: 'house', emoji: '🏠', title: 'Male dein Zuhause!', titleEn: 'Paint your home!'),
  DailyTask(id: 'glitter', emoji: '✨', title: 'Male etwas mit Glitzer!', titleEn: 'Paint something with glitter!'),
  DailyTask(id: 'blue', emoji: '💙', title: 'Male etwas Blaues!', titleEn: 'Paint something blue!'),
  DailyTask(id: 'face', emoji: '😊', title: 'Male ein fröhliches Gesicht!', titleEn: 'Paint a happy face!'),
  DailyTask(id: 'stars', emoji: '⭐', title: 'Stemple 10 Sterne!', titleEn: 'Stamp 10 stars!'),
  DailyTask(id: 'tree', emoji: '🌳', title: 'Male einen großen Baum!', titleEn: 'Paint a big tree!'),
  DailyTask(id: 'fill', emoji: '🪣', title: 'Fülle eine Fläche mit Punkten!', titleEn: 'Fill an area with dots!'),
  DailyTask(id: 'car', emoji: '🚗', title: 'Male ein Fahrzeug!', titleEn: 'Paint a vehicle!'),
  DailyTask(id: 'yellow', emoji: '💛', title: 'Male etwas Gelbes!', titleEn: 'Paint something yellow!'),
  DailyTask(id: 'letter', emoji: '✍️', title: 'Spure einen Buchstaben nach!', titleEn: 'Trace a letter!'),
  DailyTask(id: 'flower', emoji: '🌸', title: 'Male eine Blume!', titleEn: 'Paint a flower!'),
  DailyTask(id: 'heart', emoji: '❤️', title: 'Male drei Herzen!', titleEn: 'Paint three hearts!'),
  DailyTask(id: 'sea', emoji: '🌊', title: 'Male etwas unter Wasser!', titleEn: 'Paint something underwater!'),
  DailyTask(id: 'neon', emoji: '⚡', title: 'Male mit dem Neon-Stift!', titleEn: 'Draw with the neon pen!'),
  DailyTask(id: 'cat', emoji: '🐱', title: 'Male eine Katze!', titleEn: 'Paint a cat!'),
  DailyTask(id: 'green', emoji: '💚', title: 'Male etwas Grünes!', titleEn: 'Paint something green!'),
  DailyTask(id: 'shapes', emoji: '⭕', title: 'Male drei verschiedene Formen!', titleEn: 'Draw three different shapes!'),
  DailyTask(id: 'space', emoji: '🚀', title: 'Male etwas im Weltraum!', titleEn: 'Paint something in space!'),
  DailyTask(id: 'number', emoji: '🔢', title: 'Spure eine Zahl nach!', titleEn: 'Trace a number!'),
  DailyTask(id: 'cake', emoji: '🎂', title: 'Male einen Geburtstagskuchen!', titleEn: 'Paint a birthday cake!'),
  DailyTask(id: 'family', emoji: '👨‍👩‍👧', title: 'Male deine Familie!', titleEn: 'Paint your family!'),
  DailyTask(id: 'dots', emoji: '🔵', title: 'Male mit dem Punkte-Stift!', titleEn: 'Draw with the dotty pen!'),
  DailyTask(id: 'weather', emoji: '⛅', title: 'Male das Wetter von heute!', titleEn: 'Paint today\'s weather!'),
  DailyTask(id: 'dream', emoji: '💭', title: 'Male, wovon du geträumt hast!', titleEn: 'Paint what you dreamed about!'),
  DailyTask(id: 'monster', emoji: '👾', title: 'Male ein lustiges Monster!', titleEn: 'Paint a funny monster!'),
];

/// Day number since a fixed epoch — the basis for picking the day's task.
///
/// The local calendar date decides (the task flips at local midnight), but
/// the arithmetic runs in UTC: local days are 23 or 25 hours long around
/// daylight-saving switches, which would make `inDays` truncate two
/// different dates to the same number.
int dayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2026, 1, 1))
        .inDays;

/// Deterministic task of the day. The stride (7) is coprime with the
/// catalog length (30), so consecutive days never repeat and the full
/// catalog cycles before anything comes back.
DailyTask taskForDate(DateTime date) {
  final n = dayNumber(date) * 7;
  return kDailyTasks[n % kDailyTasks.length];
}

/// `yyyy-MM-dd` key used to remember whether today's task is done.
String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
