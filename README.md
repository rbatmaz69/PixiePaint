# 🎨 PixiePaint

Ein liebevolles Malbuch für Kinder ab 3 Jahren — komplett offline, ohne Werbung, ohne Datensammlung. Gebaut mit Flutter für Android und iOS.

[![CI](https://github.com/rbatmaz69/PixiePaint/actions/workflows/ci.yml/badge.svg)](https://github.com/rbatmaz69/PixiePaint/actions/workflows/ci.yml)

**Aktuelle Version:** 8.4.0+35 · **Design-Sprache:** „Sticker-Buch" (bunte Sticker auf warmem Papier)

---

## Inhalt

- [Features](#features)
- [Voraussetzungen](#voraussetzungen)
- [Projekt einrichten](#projekt-einrichten)
- [App auf dem Gerät installieren](#app-auf-dem-gerät-installieren) ← Debug- & Release-Builds
- [Entwicklung](#entwicklung)
- [Tests & Codequalität](#tests--codequalität)
- [Übersetzungen (l10n)](#übersetzungen-l10n)
- [Projektstruktur](#projektstruktur)
- [Architektur-Notizen](#architektur-notizen)
- [Inhalte erweitern](#inhalte-erweitern)
- [Veröffentlichen](#veröffentlichen)
- [Datenschutz](#datenschutz)

---

## Features

**Malen**
- 68 Ausmalbilder in 9 Kategorien (Tiere, Fahrzeuge, Fantasie, Natur, Leckereien, Weltraum, Bauernhof, Zahlen, Jahreszeiten) — jedes Motiv in allen neun Sprachen benannt, mit Herz als **Lieblingsbild** je Kind (eigener Reiter ganz vorne)
- Freies Zeichnen auf leerer Leinwand
- Eigene Fotos anmalen — oder per Kantenerkennung in ein Ausmalbild verwandeln
- 9 Stifte: Pinsel, Filzstift, Buntstift, Regenbogen, Glitzer, Neon, Herzchen-Spur, Punkte-Stift, Doppellinie
- Füllen mit 8 Mustern (einfarbig, Punkte, Streifen, Regenbogen, Herzen, Sterne, Karo, Seifenblasen), läuft in einem Isolate
- Formen aufziehen: Kreis, Quadrat, Herz, Stern, Regenbogen — mit Live-Vorschau
- Zauber-Spiegel: 2-, 4- und 6-fache Symmetrie
- 20 Emoji-Sticker in 8 Paketen, davon mehrere freischaltbar, plus eigene Sticker aus eigenen Bildern
- Pipette: Farbe direkt vom Bild aufnehmen
- Stufenlose Pinselgröße (8–90), Radierer, Undo/Redo — **Rückgängig und Wiederholen stehen fest neben der Werkzeugleiste** und scrollen nie mit weg
- Zwei-Finger-Zoom, Stift-Unterstützung mit Druckstärke, Handballen-Erkennung
- Jedes angetippte Werkzeug hüpft an, die Farbplakette am Werkzeug bestätigt die Farbwahl vom anderen Ende des Bildschirms, und Rückgängig antwortet auf jeden angenommenen Tipp

**Weitere Spielarten**
- **Malen nach Zahlen** — 8 Bilder mit nummerierten Flächen und eigener Palette
- **Nachspuren** — 44 Vorlagen (A–Z inkl. Umlaute, 0–9, 5 Formen), komplett ohne Assets aus der Schrift erzeugt
- **Sticker-Welt** — 8 Szenen als Bühne zum Bekleben
- **Zu zweit malen** — zwei unabhängige Malflächen auf einem Tablet (ab 600 dp)
- **Zeitraffer** — jeder Strich wird protokolliert und lässt sich als Film abspielen
- **Erststart** — eine kurze, jederzeit überspringbare Begrüßung, die direkt in die Bildauswahl führt
- **Tagesaufgabe** — 45 wechselnde Mal-Impulse, einer pro Tag, mit Serien-Zähler
- **Jahreszeiten** — 12 Bilder zu Weihnachten, Ostern, Sommer, Herbst und Halloween; die Kategorie rutscht im Picker automatisch nach vorne, wenn ihr Anlass ansteht
- **Erfolge-Album** — alle Belohnungs-Sticker und die Tagesaufgaben-Serie auf einen Blick

**Galerie**
- Automatisches Speichern (alle 30 s und beim Verlassen)
- **Weitermalen** — die Startseite bietet das zuletzt gemalte Bild des aktiven Kindes mit Vorschaubild an
- Favoriten, Umbenennen, Filter
- Diashow über alle Bilder
- Das angetippte Bild fliegt in die Leinwand, statt dass der Bildschirm einfach ausgetauscht wird — aus der Galerie, aus der Bildauswahl, von der Weitermalen-Karte und aus der Szenenauswahl
- Teilen, Drucken (PDF) oder „In Fotos speichern" (alles hinter der Elternschranke)

**Belohnungen**
- 13 Sticker freimalen: Bilder fertigstellen, Werkzeuge ausprobieren, nachspuren, Zahlenbilder lösen, Tagesaufgaben schaffen, ein Bild teilen
- Konfetti in zwei Stärken: ein Nicken fürs Teilen, eine Party fürs fertige Bild
- Gesperrte Sticker als wackelnde Mystery-Boxen mit kindgerechter Fortschrittsanzeige
- Rein lokal — keine Käufe, keine Accounts

**Für Eltern**
- Elternschranke (Rechenaufgabe) vor Foto-Import, Teilen, Drucken, Einstellungen, Speicherverwaltung und optional Löschen
- Bis zu 4 Kinder-Profile mit getrennten Bildern und getrenntem Fortschritt — je Kind umschaltbar auf **einfache Werkzeuge** (nur Pinsel, Füllen, Sticker, Radierer, dafür größer)
- Backup aller Bilder als ZIP — und Wiederherstellen daraus
- Speicherplatz einsehen und alte Bilder gezielt aufräumen
- Problembericht: was die App zuletzt an Fehlern mitbekommen hat — lesbar, teilbar, löschbar, und bis dahin nur auf dem Gerät
- Linkshänder-Modus, „nur mit Stift malen", Töne, **Vibration** und Musik einzeln abschaltbar
- Malzeit-Pause: nach 20, 30 oder 45 Minuten ein freundlicher Pausen-Vorhang (standardmäßig aus)
- Keine Internetverbindung, keine Tracking-IDs, keine Datensammlung
- Neun Sprachen: Deutsch, Englisch, Französisch, Italienisch, Niederländisch, Polnisch, Portugiesisch, Spanisch, Türkisch

**Barrierefreiheit**
- Alle Bedienelemente sind für TalkBack und VoiceOver benannt, inklusive Auswahlzustand der Werkzeuge und Namen aller 16 Malfarben
- Systemschriftgröße wird bis Faktor 1,6 mitgemacht
- „Bewegung reduzieren" wird respektiert: die Hintergrund-Blobs stehen still, Knöpfe federn nicht, Konfetti bleibt aus — die Belohnung selbst bleibt
- Vibration ist ein eigener Schalter, unabhängig vom Ton
- Mindestgröße aller Tap-Ziele: 48 px

---

## Voraussetzungen

| | Version |
|---|---|
| Flutter | 3.44.6 (stable) |
| Dart SDK | ^3.12.2 |
| Android | minSdk 24 (Android 7.0), Java 17 |
| iOS | Xcode mit gültigem Signing-Profil |

Prüfen, ob alles bereit ist:

```bash
flutter doctor -v
```

## Projekt einrichten

```bash
git clone https://github.com/rbatmaz69/PixiePaint.git
cd PixiePaint
flutter pub get
```

Das war's — die Lokalisierungs-Dateien (`lib/l10n/app_localizations*.dart`) sind eingecheckt und werden bei jedem Build ohnehin neu generiert (`generate: true` in der `pubspec.yaml`).

---

## App auf dem Gerät installieren

### Gerät finden

```bash
flutter devices
```

Ausgabe z. B. `SM_G990B (mobile) • R5CT30XXXXX • android-arm64 • Android 14 (API 34)`. Die mittlere Spalte ist die Geräte-ID für `-d`.

### Android

**Debug (mit Hot Reload — zum Entwickeln)**

```bash
flutter run -d R5CT30XXXXX
```

Läuft direkt auf dem Gerät und bleibt mit dem Terminal verbunden: `r` = Hot Reload, `R` = Hot Restart, `q` = beenden.

Voraussetzung am Gerät: Entwickleroptionen aktiv (7× auf „Buildnummer" in den Telefon-Einstellungen tippen) und **USB-Debugging** an.

**Release (optimiert — zum echten Ausprobieren)**

```bash
# Baut und installiert in einem Rutsch
flutter run --release -d R5CT30XXXXX
```

**Release-APK bauen und dauerhaft installieren**

```bash
flutter build apk --release
flutter install --release -d R5CT30XXXXX
```

Die fertige Datei liegt unter `build/app/outputs/flutter-apk/app-release.apk` und lässt sich auch direkt per `adb` installieren oder aufs Gerät kopieren:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Kleinere APKs (eine pro CPU-Architektur, rund ein Drittel der Größe):

```bash
flutter build apk --release --split-per-abi
# ergibt u. a. app-arm64-v8a-release.apk — das braucht fast jedes moderne Gerät
```

> **Signierung:** Ohne die Datei `android/key.properties` wird der Release-Build mit dem Debug-Schlüssel signiert. Zum lokalen Testen ist das völlig in Ordnung — für den Play Store **nicht**. Details in [`docs/play-store-release.md`](docs/play-store-release.md).

> **Wechsel zwischen Debug und Release:** Beide Varianten sind unterschiedlich signiert, deshalb verweigert Android die Installation über die jeweils andere („INSTALL_FAILED_UPDATE_INCOMPATIBLE"). Vorher deinstallieren:
> ```bash
> adb uninstall dev.rb.pixiepaint
> ```
> Damit sind allerdings auch alle gemalten Bilder weg.

### iOS

**Debug auf einem angeschlossenen iPhone/iPad**

```bash
open ios/Runner.xcworkspace   # einmalig: Signing-Team unter „Runner → Signing & Capabilities" setzen
flutter run -d <geräte-id>
```

**Release**

```bash
flutter run --release -d <geräte-id>
```

**IPA für TestFlight/App Store**

```bash
flutter build ipa --release
# Ergebnis: build/ios/ipa/*.ipa — Upload über Xcode Organizer oder Transporter
```

> Mit einer kostenlosen Apple-ID (ohne Developer-Programm) läuft die App nur 7 Tage auf dem Gerät und muss danach neu installiert werden.

### Simulator / Emulator

```bash
open -a Simulator                          # iOS-Simulator starten
flutter emulators --launch <emulator-id>   # Android-Emulator starten
flutter run
```

---

## Entwicklung

```bash
flutter run                        # erstes verfügbares Gerät, Debug-Modus
flutter run --profile              # Performance-Messungen (DevTools)
flutter clean && flutter pub get   # wenn der Build sich seltsam verhält
```

Nützlich im laufenden `flutter run`:

| Taste | Wirkung |
|---|---|
| `r` | Hot Reload |
| `R` | Hot Restart (State geht verloren) |
| `p` | Layout-Hilfslinien ein/aus |
| `o` | Zwischen Android- und iOS-Optik umschalten |
| `q` | Beenden |

## Tests & Codequalität

```bash
flutter analyze     # Linter — muss fehlerfrei sein
flutter test        # alle Unit-Tests
flutter test test/shape_renderer_test.dart   # einzelne Datei
```

**Rauchtest auf echtem Gerät** (seit v7.9):

```bash
flutter test integration_test/app_test.dart -d <geräte-id>
```

Startet die echte App, malt ein Bild an und prüft, dass es hinterher auf der Platte liegt (`paint.png` und `meta.json`) — die mechanische Spitze von [`docs/geraetetest.md`](docs/geraetetest.md). Er läuft gegen die echten App-Daten des Geräts, legt deshalb genau ein Bild an und räumt es wieder weg. Die Beschriftungen holt er sich aus dem laufenden Baum, er funktioniert also auch auf einem türkischen Gerät. **Nicht in der CI** — dafür bräuchte es einen Emulator im Workflow; das ist ein eigener Schritt, wenn sich der Test bewährt hat.

**CI** (seit v7.8, [`.github/workflows/ci.yml`](.github/workflows/ci.yml)): Jeder Push nach `main` und jeder Pull Request laufen durch drei Jobs — `flutter analyze` + Tests auf Ubuntu, die Golden-Bilder getrennt auf macOS, und ein `flutter build appbundle --release`. Der Android-Build ist keine Auslieferung (er ist nicht mit dem Upload-Schlüssel signiert), sondern die Wache für die Gradle-Seite: er wird die KGP-Warnung melden, sobald sie ein Fehler wird.

Der Analyzer läuft über `flutter_lints` hinaus mit `strict-casts`, `strict-raw-types` und acht zusätzlichen Regeln (`analysis_options.yaml`). Die wichtigste ist **`unawaited_futures`**: Ein fallengelassener Future heißt hier im Zweifel, dass ein Speichervorgang nie abgewartet wurde. Absichtliche Fälle sind mit `unawaited(...)` markiert und damit lesbar.

Die Test-Suite umfasst 551 Tests in 53 Dateien:

- `test/*.dart` — **pure Logik**: Flood Fill, Undo-Stack, Formen-Geometrie, Farb-Utils, Kantenerkennung, Belohnungs-Regeln, Wackel-Mathematik, Viewport-Berechnung, Persistenz (Artworks, Einstellungen, Profile, Fortschritt), Backup-Roundtrip inklusive Zip-Slip-Abwehr, Speicherberechnung, Fehlerlog (Deckel, Entprellung, Pfad-Redaktion)
- `test/widget/*.dart` — **Widget-Tests** für Elternschranke, Werkzeugleiste, Einstellungen, Galerie, Profil-Verwaltung, Erststart, Problembericht und die Screenreader-Beschriftungen. Schwerpunkt sind die zerstörenden Wege: dass die Elternschranke im Löschpfad davorsteht und „Behalten" nichts löscht. Dazu seit v8.0 `canvas_reach_test.dart` — die Frage, ob ein Kind die Knöpfe überhaupt *erreicht*: Rückgängig muss auf einem 360-dp-Telefon ohne Wischen auf dem Schirm stehen.
- `test/golden/renderers_test.dart` — **visuelle Regression** der 10 Stift-Charaktere, 5 Formen und 8 Füllmuster

Zu den Golden Tests: Sie decken bewusst **nur** die Zeichen-Renderer ab. Ganze Bildschirme wären hier zwecklos — die Oberfläche besteht großenteils aus Emoji, und die rendern auf jedem System anders. Die Renderer dagegen sind reine Vektoren ohne Text und aus festen Seeds deterministisch. Nach einer bewussten Designänderung neu erzeugen:

```bash
flutter test --update-goldens test/golden/
```

> Schlagen nach einem Flutter-Update **alle** 24 Bilder gleichzeitig fehl, liegt das fast immer an geänderter Kantenglättung im SDK und nicht an der App.

> **Warum die Goldens in der CI einen eigenen Job auf macOS haben:** Linux glättet Kanten anders, die Referenzbilder sind hier auf macOS entstanden. Sie tragen deshalb das Tag `golden` (`dart_test.yaml`), der Ubuntu-Job läuft mit `--exclude-tags golden`, der macOS-Job mit `--tags golden`. Ein roter Golden-Job ist damit ein echter Befund. Er wird **nicht** mit `--update-goldens` beantwortet, ohne vorher zu wissen, was sich geändert hat.

> **Drei Fallstricke bei Widget-Tests in diesem Projekt** (alle im Code kommentiert, siehe `test/widget/harness.dart`):
> 1. `testWidgets` läuft in einer Fake-Async-Zone — echte Datei-I/O löst dort **nie** ein und der Test hängt, statt zu scheitern. Setup deshalb in `tester.runAsync(...)`.
> 2. Ein autofokussiertes `TextField` (Elternschranke) lässt seinen Cursor blinken und plant dauerhaft Frames; `pumpAndSettle()` läuft dann ins Timeout. Stattdessen begrenzt pumpen.
> 3. `Progress` und `ProfileStore` schreiben fire-and-forget. Vor dem Löschen des Temp-Verzeichnisses im `tearDown` immer `await store.flush()`, sonst schlägt das Löschen sporadisch fehl.

## Übersetzungen (l10n)

Neun Sprachen: **Deutsch** (Ausgangssprache und Fallback), Englisch, Französisch, Italienisch, Niederländisch, Polnisch, Portugiesisch, Spanisch, Türkisch.

1. Neuen Text in `lib/l10n/app_de.arb` eintragen — und in **allen** anderen `app_*.arb` unter demselben Key
2. Generieren:
   ```bash
   flutter gen-l10n
   ```
3. Im Code verwenden: `context.l10n.meinNeuerKey` (Helfer aus `lib/l10n/l10n.dart`)
4. `flutter test test/l10n_test.dart` — der Test schlägt fehl, sobald einer Sprache ein Key fehlt oder ein Platzhalter verlorengegangen ist

Platzhalter und Pluralformen folgen dem ICU-Format — Beispiele stehen bei `gateQuestion` und `rewardRulePaintings` in den ARB-Dateien.

> **Pluralformen sind nicht überall zwei.** Die zehn Plural-Texte brauchen im Polnischen vier Formen (`=1` / `few` / `many` / `other`), weil sich die Endung zwischen 2–4 und 5+ ändert: mit nur `one`/`other` steht dort „5 obrazek" statt „5 obrazków". Das Türkische kommt umgekehrt mit einer Form aus. `test/l10n_test.dart` prüft, dass die polnischen Formen vorhanden sind.

> **Zum Ton:** Die Übersetzungen stammen nicht von Muttersprachlern. Sie sind idiomatisch und kindgerecht formuliert, aber bevor die App in einem dieser Märkte tatsächlich veröffentlicht wird, lohnt sich ein Blick von jemandem, der die Sprache spricht — gerade bei einer Kinder-App trägt der Ton viel.

**Namen von Inhalten liegen nicht in den ARB-Dateien** (seit v7.6). Motive, Kategorien, Szenen und Tagesaufgaben sind Daten, nicht Oberfläche — ihre Namen stehen direkt beim Inhalt, damit ein neues Bild eine Änderung bleibt und nicht neun:

| Was | Wo | Deutsch | Englisch | Die anderen sieben |
|---|---|---|---|---|
| Bildtitel | `assets/coloring_pages/pages.json` | `title` | `titleEn` | `titles` |
| Kategorien | `kCategoryNames` in `lib/models/coloring_page.dart` | der Schlüssel selbst | `categoryEn` in pages.json | dort im Eintrag |
| Szenen | `assets/scenes/scenes.json` | `title` | `titleEn` | `titles` |
| Tagesaufgaben | `kDailyTasks` in `lib/models/daily_task.dart` | `title` | `titleEn` | `titles` |

Die Auswahl macht überall `localizedName` (`lib/models/localized_name.dart`): exakte Sprache → Englisch → Deutsch. `flutter test test/page_names_test.dart` schlägt fehl, sobald irgendwo eine der neun Sprachen fehlt — bis v7.6 kannte das Modell nur Deutsch und Englisch, ein türkisches Kind las also „Schmetterling" unter dem Schmetterling.

## Projektstruktur

```
lib/
├── main.dart              App-Start: System-UI, Settings/Profile/Fortschritt laden, Sfx & Musik init
├── app.dart               MaterialApp, Theme, RouteObserver, Textskalierungs-Klemme
├── canvas/                Der Malbereich
│   ├── canvas_screen.dart     Bildschirm: Layouts, Autosave, Teilen, Belohnungs-Feier
│   ├── canvas_controller.dart Zentraler State: Ebenen, Zeiger, Werkzeuge, Undo
│   ├── canvas_painter.dart    Zeichnet Ebenen + Vorschauen
│   ├── stroke_renderer.dart   Die 9 Stift-Charaktere
│   ├── shape_renderer.dart    Formen-Geometrie
│   ├── symmetry.dart          Zauber-Spiegel (2/4/6-fach)
│   ├── flood_fill.dart        Füll-Algorithmus (läuft im Isolate)
│   ├── op_apply.dart          Wiedergabe des Op-Logs (Zeitraffer)
│   ├── cbn_session.dart       Malen nach Zahlen: Zustand einer Sitzung
│   ├── two_painter_screen.dart Zwei-Maler-Modus (nur Tablet)
│   └── *_burst.dart           Füll- und Stempel-Effekte
├── gallery/               Startseite, Bild-/Szenenauswahl, Galerie, Diashow, Speicher
├── trace/                 Nachspur-Modus (Vorlagen aus der Schrift, Deckungsprüfung)
├── replay/                Zeitraffer-Wiedergabe
├── stickers/              Eigene Sticker: Ausschnitt aufnehmen und ablegen
├── photo/                 Foto → Ausmalbild (Kantenerkennung)
├── settings/              Einstellungen, Speicherplatz-Verwaltung, Problembericht
├── models/                Werkzeuge, Sticker, Belohnungen, Artwork, Ausmalbilder,
│                          Profile, Szenen, Tagesaufgaben, Zeichen-Ops,
│                          Inhalts-Namen in neun Sprachen (localized_name.dart)
├── ui/                    Design-System (siehe unten) — inkl. entrance.dart,
│                          paper_doodles.dart und hero_tags.dart
├── util/                  Settings, Fortschritt, Profile, Sfx, Musik, Bild-IO,
│                          Teilen, Speichern, PDF, Backup/Restore, JsonStore,
│                          Fehlerlog
├── widgets/               Werkzeugleiste, Farbpalette, Picker, Elternschranke, Profil-Sheet
└── l10n/                  ARB-Dateien + generierte Übersetzungen

assets/
├── coloring_pages/        68 SVGs + pages.json (Katalog, Namen in 9 Sprachen)
│   └── cbn/               Sidecar-JSON für „Malen nach Zahlen"
├── scenes/                8 Szenen-SVGs + scenes.json
├── fonts/                 Fredoka (Medium/SemiBold/Bold)
├── sounds/                pop, tick, tada + music/ (3 Loops)
└── icon/                  App-Icon & Splash

docs/                      Release-Anleitungen (Play Store, App Store),
                           Gerätetest-Checkliste, Datenschutzerklärung

tool/                      make_music.py — erzeugt die Musik-Loops
                           make_store_graphics.py — Icon & Feature-Grafik
```

## Architektur-Notizen

**Design-System** (`lib/ui/`) — die Sticker-Buch-Sprache:
- `pixie_palette.dart` — **die eine** Farbquelle. Jeder UI-Ton leitet sich hiervon ab. (Die Malfarben in `widgets/color_palette.dart` sind bewusst getrennt: das ist Inhalt, keine Oberfläche.)
- `app_theme.dart` — Tokens (Radien, `softShadow`, `stickerTilt`), Gradients, Typo-Skala, Component-Themes
- `sticker.dart` — `StickerCard` (inkl. Aufkleber-Glanz), `StickerCircleButton`, `StickerEmoji`, `stickerSelectionDecoration`
- `pixie_header.dart` — einheitlicher Screen-Kopf (ersetzt AppBars), mit Akzent-Unterstrich je Bildschirm
- `bouncy.dart`, `pop_in.dart` — Bewegungs-Primitive (Press-Feder, Entrance-Pop, Puls)
- `entrance.dart` — **die eine** Staffel-Animation aller Screens (siehe unten)
- `blob_background.dart` + `paper_doodles.dart` — driftende Blobs + Doodles auf **einem** 28-s-Ticker, der sich automatisch pausiert, sobald die Route verdeckt oder die App im Hintergrund ist. Der Malbildschirm nimmt denselben Doodle-Painter, aber ohne Ticker und blasser
- `hero_tags.dart` — die Tags der Flüge in die Leinwand, an einer Stelle vergeben
- `kid_dialog.dart`, `kid_sheet.dart`, `reward_reveal.dart` — Dialoge, Sheets, Belohnungs-Moment

**Erreichbarkeit der Werkzeugleiste** (seit v8.0): `ToolBarRail` scrollt, `ToolActionCluster` nicht. Rückgängig und Wiederholen lagen bis dahin am Ende eines rund 1000 px breiten Streifens — auf einem 360-dp-Telefon außerhalb des Bildes, hinter einer Wischgeste, die nichts ankündigte. Die beiden Knöpfe platziert seither der Bildschirm selbst (in `_buildPortrait` und `_LeftRail`), gespiegelt für Linkshänder. Der Streifen daneben blendet seine Ränder weich aus, sobald dort wirklich mehr steht, und holt ein über ein Auswahl-Blatt gewähltes Werkzeug per `Scrollable.ensureVisible` zurück in den Blick. **Was neu in die Leiste kommt, gehört in den scrollenden Teil** — der feste Cluster ist für das reserviert, was ein Kind im Zweifel *sofort* braucht.

**Eine Bewegung, eine Stelle** (seit v8.4): Startseite, Bildauswahl, Galerie und Einstellungen trugen dieselbe Staffel-Animation in je eigener Fassung, fünf weitere Bildschirme hatten gar keine. `lib/ui/entrance.dart` ist diese Bewegung genau einmal, mit zwei Zugängen: `EntranceMixin` für Screens, die ohnehin einen `State` haben (setzt nichts Zusätzliches in den Widget-Baum), und `EntranceGroup` + `Entrance` für Raster aus zustandslosen Widgets. Beide rufen dasselbe `buildEntrance`. **Die Gruppe gehört in den geladenen Zweig** eines `FutureBuilder`, nicht darüber — sonst läuft die Staffelung ab, während der Bildschirm noch von der Platte liest. Bei „Bewegung reduzieren" bleibt die Einblendung, der Weg dorthin fällt weg.

**Canvas-Performance:** Der `CanvasController` trennt zwei Signale — `repaint` (ValueNotifier, feuert bei jedem Zeichen-Sample und lässt nur den Painter neu malen) und `notifyListeners()` (nur für Werkzeugleisten-State). Der `CustomPaint` liegt in einer eigenen `RepaintBoundary`. **Neue Effekte im Malbereich gehören als Geschwister-Overlay daneben, niemals hinein** — Vorbild: `fill_burst.dart` und `stamp_burst.dart`.

**Persistenz:** Alles lokal, keine Datenbank.
- Bilder: ein Ordner je Werk unter `<appDocuments>/artworks/<uuid>/` mit `paint.png`, `thumb.png`, `meta.json` (plus optional Foto-Hintergrund, Linienart und `ops.json` für den Zeitraffer)
- Eigene Sticker: `<appDocuments>/stickers/*.png` (max. 24)
- Einstellungen: `settings.json` · Kinder-Profile: `profiles.json` · Belohnungs-Fortschritt: `progress_<profil-id>.json`

**Wenn etwas schiefgeht** (seit v7.5) — die App hat kein Analytics und keinen Crash-Reporter, und das bleibt so. Sie hatte aber auch keinen Ersatz dafür: ein Absturz auf einem echten Gerät hinterließ nichts, was man später noch ansehen konnte. Genau das füllt `lib/util/error_log.dart`:

- **Aufgezeichnet wird:** Zeitpunkt, App-Version, Betriebssystem, wo der Fehler gefangen wurde (`flutter` / `platform` / `zone` / `save`), die erste Zeile der Meldung und ein auf 12 Frames gekürzter Stack.
- **Nicht aufgezeichnet wird:** keine Geräte-IDs, keine Bildinhalte, keine Kindernamen, keine absoluten Pfade — das Dokumentenverzeichnis wird durch `<docs>` ersetzt, weil es auf iOS eine Installations-UUID enthält und darunter die Artwork-IDs stehen.
- **Deckel:** 30 Einträge *und* 32 KB, der jeweils älteste fällt heraus. Eine identische Meldung innerhalb von 60 s erhöht einen Zähler statt einen Eintrag anzuhängen — ein Fehler im Painter feuert sonst pro Frame.
- **Wo es sichtbar wird:** Einstellungen → „Problembericht" (hinter der Elternschranke, `lib/settings/error_log_screen.dart`). Teilen fragt die Rechenaufgabe noch einmal, weil dabei eine Datei das Gerät verlässt. Die Datenschutz-Antworten in beiden Stores bleiben unverändert: erhoben wird weiterhin nichts.
- **Der wichtigste Eintragstyp ist `save`.** `atomicWrite*` und `JsonStore` schlucken jeden Schreibfehler absichtlich (die alte Datei bleibt dadurch intakt) — sie melden ihn jetzt über den Hook `onPersistFailure` in `json_store.dart`. „Speicher voll" ist damit belegbar, statt nur als „ein Bild war weg" erinnerbar.
- Ein fehlgeschlagener Build zeigt in Release die `OopsCard` statt des grauen Kastens (`lib/ui/oops_card.dart`); in Debug bleiben die roten Streifen. Aufgezeichnet wird nur einmal — `FlutterError.onError` sieht die Ausnahme schon, `ErrorWidget.builder` schreibt bewusst nichts mehr dazu.

**Vier Regeln, die dieses Projekt gelernt hat** — jede steht für einen Fehler, der schon einmal passiert ist:

1. **Neue Persistenz immer über `JsonStore` bzw. `atomicWrite*`** (`lib/util/json_store.dart`), nie über nacktes `writeAsString`. Der Store serialisiert die Schreibvorgänge und ersetzt die Zieldatei atomar per Rename. Wo mehrere Dateien zusammen ein Ganzes bilden (ein Artwork-Ordner), wird die *identifizierende* Datei zuletzt geschrieben — `meta.json` ist der Commit-Marker.
2. **Neue Effekte im Malbereich gehören als Geschwister-Overlay neben den Painter**, niemals hinein (siehe Canvas-Performance oben).
3. **`ZipFileEncoder` in `archive` 4.x nur in den Sync-Varianten benutzen** (`addFileSync`, `closeSync`) — die asynchronen Methoden geben Futures zurück, die im Isolate leicht übersehen werden.
4. **Ein `late final` AnimationController darf nicht in `dispose()` erstmalig entstehen.** Wird ein Screen verlassen, bevor sein `build` das Feld je gelesen hat, erzeugt `dispose()` den Controller zum ersten Mal — im bereits abgebauten Element-Baum — und die App stürzt ab. Muster dagegen: **nullable Backing-Feld plus Getter**, `dispose` fasst nur das Feld an (`lib/gallery/gallery_screen.dart`).

   Betroffen war das viermal, jedes Mal mit einem eigenen Weg dorthin: Galerie und Bildauswahl (Lade-Pixie während des Lesens von der Platte), Diashow (erstes Bild wird mit 1400 px gerendert) und der Sticker-Picker (kein einziger gesperrter Sticker mehr, also keine wackelnde Kachel, die den Ticker anfasst). `test/widget/early_exit_test.dart` baut die betroffenen Screens auf und verlässt sie nach einem einzigen Frame wieder — genau das Szenario.

   **Verwandt:** Jedes `setState` nach einem `await` braucht einen `mounted`-Wächter (oder ein eigenes `_disposed`-Flag wie in `slideshow_screen.dart`). Der Analyzer prüft das nur für `BuildContext`, nicht für `setState`.

5. **Ein Dialog besitzt seinen eigenen `TextEditingController`.** Ihn direkt nach `showKidDialog(...)` freizugeben sieht richtig aus, ist es aber nicht: Der Dialog animiert noch heraus und baut das Textfeld dabei mehrfach neu — auf einem freigegebenen Controller wirft jeder dieser Frames. Vorbild: `_RenameField` in `lib/gallery/gallery_screen.dart`.

6. **Der Undo-Stack budgetiert Speicher, nicht Schritte** (`lib/canvas/undo_stack.dart`). Ein Schnappschuss der Malebene ist 12 MB; eine feste Schrittzahl reserviert damit schnell dreistellige Megabyte. Wer dort etwas ändert, prüft `bytesInUse` — `test/undo_stack_test.dart` hält die Obergrenze für beide Canvas-Größen fest.

7. **`Curves.easeOutBack` überschwingt über beide Tween-Enden hinaus.** In einer `AnimatedContainer`-Dekoration darf deshalb kein `boxShadow` gegen `null` animiert werden: der Blur-Radius wird dabei negativ und `dart:ui` bricht ab. Stattdessen den Radius konstant lassen und nur die Deckkraft bewegen (`_selectionShadow` in `lib/widgets/tool_bar.dart`).

## Inhalte erweitern

**Neues Ausmalbild hinzufügen**

1. SVG nach `assets/coloring_pages/` legen — geschlossene Konturen, schwarze Linien auf transparentem Grund, sonst „läuft" die Füllung aus
2. Eintrag in `assets/coloring_pages/pages.json` ergänzen:
   ```json
   {
     "id": "cat",
     "title": "Katze",
     "titleEn": "Cat",
     "titles": {"es": "Gato", "fr": "Chat", "it": "Gatto", "nl": "Kat",
                "pl": "Kot", "pt": "Gato", "tr": "Kedi"},
     "file": "cat.svg",
     "category": "Tiere",
     "categoryEn": "Animals"
   }
   ```
   Die deutsche `category` ist der stabile Schlüssel — an ihr hängen die Pastell-Tints im Picker (`_categoryTint` in `lib/gallery/page_picker_screen.dart`) und die Namen in `kCategoryNames`. Bei einer **neuen Kategorie** also beides ergänzen; beides ist ein Einzeiler, und `test/page_names_test.dart` sagt es sonst.
3. `flutter test test/page_artwork_test.dart test/page_names_test.dart` — die Abnahme: rastert das Bild, prüft geschlossene füllbare Flächen und die neun Namen. **Das ist die Prüfung, nicht das Auge** — eine Kontur mit einer Lücke sieht perfekt aus und flutet beim ersten Tippen das ganze Bild.
4. `flutter run` — Assets werden über den Ordner-Eintrag in der `pubspec.yaml` automatisch mitgenommen

**Neuen Sticker** in `lib/models/stamp.dart` (`kStamps`) eintragen, **neue Belohnung** in `lib/models/reward.dart` (`kRewards`). Dort steht auch der Hinweis, welche Emoji plattformübergreifend farbig rendern.

**Neue Szene** (Sticker-Welt): SVG nach `assets/scenes/` plus Eintrag in `scenes.json`, inklusive `titles`.

**Neues Zahlenbild** („Malen nach Zahlen"): SVG wie ein normales Ausmalbild plus `"mode": "cbn"`, dazu ein Sidecar `assets/coloring_pages/cbn/<id>.json` mit Palette und Beschriftungen (Koordinaten in 2048 × 1536, also das Doppelte der SVG-Maße). `test/cbn_pages_test.dart` prüft das Authoring end-to-end — jede Beschriftung muss in einer gültigen, einheitlich nummerierten Fläche liegen; die Seitenliste leitet der Test aus `pages.json` ab, ein neues Bild ist also automatisch mit drin.

**Neue Tagesaufgabe** in `lib/models/daily_task.dart` (`kDailyTasks`) — **immer anhängen, nie einsortieren:** die Liste wird zyklisch über das Datum adressiert, ein Einschub verschiebt die Aufgabe jedes folgenden Tages.

**Neues Jahreszeiten-Bild:** wie ein normales Ausmalbild, zusätzlich `"season"` im `pages.json`-Eintrag (einer der Schlüssel aus `kSeasonWindows` in `lib/models/coloring_page.dart`).

**Store-Grafiken** (Icon 512, Feature-Grafik 1024 × 500, Apple-Icon 1024): `python3 tool/make_store_graphics.py`, Ergebnis in `build/store/`. Braucht `brew install librsvg` und Pillow. Die Grafik baut auf den echten Ausmalbildern und der Fredoka-Schrift auf — ändert sich das Icon oder die Palette, ist derselbe Befehl die Aktualisierung.

**Neues Musikstück:** `tool/make_music.py` erweitern (eine Funktion plus ein Eintrag in `TRACKS`), Datei nach `assets/sounds/music/` erzeugen und in `Music.tracks` eintragen. Die WAVs sind synthetisiert — nahtlos, weil `ReleaseMode.loop` jeden Klick am Übergang alle paar Minuten wiederholt; das Skript prüft selbst, dass ein Stück in Stille endet.

## Veröffentlichen

Die kompletten Schritt-für-Schritt-Anleitungen stehen in:

- **[`docs/play-store-release.md`](docs/play-store-release.md)** — Google Play (Keystore, App-Bundle, Formulare, Store-Texte)
- **[`docs/app-store-release.md`](docs/app-store-release.md)** — Apple App Store (Signing, TestFlight, Datenschutz-Labels, Kids-Kategorie)
- **[`docs/geraetetest.md`](docs/geraetetest.md)** — Checkliste für die Testsession vor dem Upload

Kurzfassung:

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Die Versionsnummer wird in der `pubspec.yaml` gepflegt: `version: 7.4.2+24` bedeutet Versionsname 7.4.2 und versionCode 24. Beide müssen bei jedem Store-Upload erhöht werden.

## Datenschutz

PixiePaint sammelt **keine** Daten. Alles bleibt auf dem Gerät: keine Internetverbindung, keine Analytics, keine Werbe-IDs, keine Accounts. Fotos werden ausschließlich lokal verarbeitet. Die vollständige Erklärung: [`docs/privacy-policy.md`](docs/privacy-policy.md) — sie zählt einzeln auf, was auf dem Gerät liegt (Bilder, Profil-Namen, Einstellungen, Fortschritt, eigene Sticker, Fehlerlog) und über welche drei Wege überhaupt etwas das Gerät verlassen kann.

Der Ordner `docs/` ist zugleich die öffentliche Seite (GitHub Pages, Quelle `main` / `/docs`): Startseite `docs/index.md`, Datenschutzerklärung unter `/privacy-policy/`. Die drei internen Anleitungen sind in `docs/_config.yml` von der Auslieferung ausgenommen. **Jede neue Seite braucht YAML-Front-Matter** — ohne verarbeitet Jekyll sie nicht und die Adresse liefert eine 404.

| | |
|---|---|
| Android applicationId | `dev.rb.pixiepaint` |
| iOS Bundle Identifier | `dev.rb.pixiepaint.pixiepaint` |
| Berechtigungen | Fotobibliothek — nur beim Foto-Import bzw. -Export, jeweils hinter der Elternschranke |
| Internet | nein |
