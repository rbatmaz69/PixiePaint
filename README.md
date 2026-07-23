# 🎨 PixiePaint

Ein liebevolles Malbuch für Kinder ab 3 Jahren — komplett offline, ohne Werbung, ohne Datensammlung. Gebaut mit Flutter für Android und iOS.

**Aktuelle Version:** 7.1.0+19 · **Design-Sprache:** „Sticker-Buch" (bunte Sticker auf warmem Papier)

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
- 54 Ausmalbilder in 8 Kategorien (Tiere, Fahrzeuge, Fantasie, Natur, Leckereien, Weltraum, Zahlen, Jahreszeiten)
- Freies Zeichnen auf leerer Leinwand
- Eigene Fotos anmalen — oder per Kantenerkennung in ein Ausmalbild verwandeln
- 9 Stifte: Pinsel, Filzstift, Buntstift, Regenbogen, Glitzer, Neon, Herzchen-Spur, Punkte-Stift, Doppellinie
- Füllen mit 8 Mustern (einfarbig, Punkte, Streifen, Regenbogen, Herzen, Sterne, Karo, Seifenblasen), läuft in einem Isolate
- Formen aufziehen: Kreis, Quadrat, Herz, Stern, Regenbogen — mit Live-Vorschau
- Zauber-Spiegel: 2-, 4- und 6-fache Symmetrie
- 20 Emoji-Sticker in 8 Paketen, davon mehrere freischaltbar, plus eigene Sticker aus eigenen Bildern
- Pipette: Farbe direkt vom Bild aufnehmen
- Stufenlose Pinselgröße (8–90), Radierer, Undo/Redo
- Zwei-Finger-Zoom, Stift-Unterstützung mit Druckstärke, Handballen-Erkennung

**Weitere Spielarten**
- **Malen nach Zahlen** — 4 Bilder mit nummerierten Flächen und eigener Palette
- **Nachspuren** — 44 Vorlagen (A–Z inkl. Umlaute, 0–9, 5 Formen), komplett ohne Assets aus der Schrift erzeugt
- **Sticker-Welt** — 6 Szenen als Bühne zum Bekleben
- **Zu zweit malen** — zwei unabhängige Malflächen auf einem Tablet (ab 600 dp)
- **Zeitraffer** — jeder Strich wird protokolliert und lässt sich als Film abspielen
- **Tagesaufgabe** — 30 wechselnde Mal-Impulse, einer pro Tag, mit Serien-Zähler
- **Jahreszeiten** — 12 Bilder zu Weihnachten, Ostern, Sommer, Herbst und Halloween; die Kategorie rutscht im Picker automatisch nach vorne, wenn ihr Anlass ansteht
- **Erfolge-Album** — alle Belohnungs-Sticker und die Tagesaufgaben-Serie auf einen Blick

**Galerie**
- Automatisches Speichern (alle 30 s und beim Verlassen)
- Favoriten, Umbenennen, Filter
- Diashow über alle Bilder
- Teilen, Drucken (PDF) oder „In Fotos speichern" (alles hinter der Elternschranke)

**Belohnungen**
- 12 Sticker freimalen: Bilder fertigstellen, Werkzeuge ausprobieren, nachspuren, Zahlenbilder lösen, Tagesaufgaben schaffen, ein Bild teilen
- Gesperrte Sticker als wackelnde Mystery-Boxen mit kindgerechter Fortschrittsanzeige
- Rein lokal — keine Käufe, keine Accounts

**Für Eltern**
- Elternschranke (Rechenaufgabe) vor Foto-Import, Teilen, Drucken, Einstellungen, Speicherverwaltung und optional Löschen
- Bis zu 4 Kinder-Profile mit getrennten Bildern und getrenntem Fortschritt
- Backup aller Bilder als ZIP — und Wiederherstellen daraus
- Speicherplatz einsehen und alte Bilder gezielt aufräumen
- Linkshänder-Modus, „nur mit Stift malen", Töne und Musik abschaltbar
- Malzeit-Pause: nach 20, 30 oder 45 Minuten ein freundlicher Pausen-Vorhang (standardmäßig aus)
- Keine Internetverbindung, keine Tracking-IDs, keine Datensammlung
- Neun Sprachen: Deutsch, Englisch, Französisch, Italienisch, Niederländisch, Polnisch, Portugiesisch, Spanisch, Türkisch

**Barrierefreiheit**
- Alle Bedienelemente sind für TalkBack und VoiceOver benannt, inklusive Auswahlzustand der Werkzeuge und Namen aller 16 Malfarben
- Systemschriftgröße wird bis Faktor 1,3 mitgemacht
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
flutter analyze     # Linter (flutter_lints) — muss fehlerfrei sein
flutter test        # alle Unit-Tests
flutter test test/shape_renderer_test.dart   # einzelne Datei
```

Die Test-Suite umfasst 328 Tests in 35 Dateien:

- `test/*.dart` — **pure Logik**: Flood Fill, Undo-Stack, Formen-Geometrie, Farb-Utils, Kantenerkennung, Belohnungs-Regeln, Wackel-Mathematik, Viewport-Berechnung, Persistenz (Artworks, Einstellungen, Profile, Fortschritt), Backup-Roundtrip inklusive Zip-Slip-Abwehr, Speicherberechnung
- `test/widget/*.dart` — **Widget-Tests** für Elternschranke, Werkzeugleiste, Einstellungen und die Screenreader-Beschriftungen

Golden Tests gibt es nicht; Optik und Animationen werden am Gerät geprüft.

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
├── settings/              Einstellungen, Speicherplatz-Verwaltung
├── models/                Werkzeuge, Sticker, Belohnungen, Artwork, Ausmalbilder,
│                          Profile, Szenen, Tagesaufgaben, Zeichen-Ops
├── ui/                    Design-System (siehe unten)
├── util/                  Settings, Fortschritt, Profile, Sfx, Musik, Bild-IO,
│                          Teilen, Speichern, PDF, Backup/Restore, JsonStore
├── widgets/               Werkzeugleiste, Farbpalette, Picker, Elternschranke, Profil-Sheet
└── l10n/                  ARB-Dateien + generierte Übersetzungen

assets/
├── coloring_pages/        54 SVGs + pages.json (Katalog)
│   └── cbn/               Sidecar-JSON für „Malen nach Zahlen"
├── scenes/                6 Szenen-SVGs + scenes.json
├── fonts/                 Fredoka (Medium/SemiBold/Bold)
├── sounds/                pop, tick, tada + music/ (2 Loops)
└── icon/                  App-Icon & Splash

docs/                      Release-Anleitungen (Play Store, App Store),
                           Gerätetest-Checkliste, Datenschutzerklärung
```

## Architektur-Notizen

**Design-System** (`lib/ui/`) — die Sticker-Buch-Sprache:
- `pixie_palette.dart` — **die eine** Farbquelle. Jeder UI-Ton leitet sich hiervon ab. (Die Malfarben in `widgets/color_palette.dart` sind bewusst getrennt: das ist Inhalt, keine Oberfläche.)
- `app_theme.dart` — Tokens (Radien, `softShadow`, `stickerTilt`), Gradients, Typo-Skala, Component-Themes
- `sticker.dart` — `StickerCard`, `StickerCircleButton`, `StickerEmoji`, `stickerSelectionDecoration`
- `pixie_header.dart` — einheitlicher Screen-Kopf (ersetzt AppBars)
- `bouncy.dart`, `pop_in.dart` — Bewegungs-Primitive (Press-Feder, Entrance-Pop, Puls)
- `blob_background.dart` — driftende Blobs + Doodles auf **einem** 28-s-Ticker, der sich automatisch pausiert, sobald die Route verdeckt oder die App im Hintergrund ist
- `kid_dialog.dart`, `kid_sheet.dart`, `reward_reveal.dart` — Dialoge, Sheets, Belohnungs-Moment

**Canvas-Performance:** Der `CanvasController` trennt zwei Signale — `repaint` (ValueNotifier, feuert bei jedem Zeichen-Sample und lässt nur den Painter neu malen) und `notifyListeners()` (nur für Werkzeugleisten-State). Der `CustomPaint` liegt in einer eigenen `RepaintBoundary`. **Neue Effekte im Malbereich gehören als Geschwister-Overlay daneben, niemals hinein** — Vorbild: `fill_burst.dart` und `stamp_burst.dart`.

**Persistenz:** Alles lokal, keine Datenbank.
- Bilder: ein Ordner je Werk unter `<appDocuments>/artworks/<uuid>/` mit `paint.png`, `thumb.png`, `meta.json` (plus optional Foto-Hintergrund, Linienart und `ops.json` für den Zeitraffer)
- Eigene Sticker: `<appDocuments>/stickers/*.png` (max. 24)
- Einstellungen: `settings.json` · Kinder-Profile: `profiles.json` · Belohnungs-Fortschritt: `progress_<profil-id>.json`

**Vier Regeln, die dieses Projekt gelernt hat** — jede steht für einen Fehler, der schon einmal passiert ist:

1. **Neue Persistenz immer über `JsonStore` bzw. `atomicWrite*`** (`lib/util/json_store.dart`), nie über nacktes `writeAsString`. Der Store serialisiert die Schreibvorgänge und ersetzt die Zieldatei atomar per Rename. Wo mehrere Dateien zusammen ein Ganzes bilden (ein Artwork-Ordner), wird die *identifizierende* Datei zuletzt geschrieben — `meta.json` ist der Commit-Marker.
2. **Neue Effekte im Malbereich gehören als Geschwister-Overlay neben den Painter**, niemals hinein (siehe Canvas-Performance oben).
3. **`ZipFileEncoder` in `archive` 4.x nur in den Sync-Varianten benutzen** (`addFileSync`, `closeSync`) — die asynchronen Methoden geben Futures zurück, die im Isolate leicht übersehen werden.
4. **Der Undo-Stack budgetiert Speicher, nicht Schritte** (`lib/canvas/undo_stack.dart`). Ein Schnappschuss der Malebene ist 12 MB; eine feste Schrittzahl reserviert damit schnell dreistellige Megabyte. Wer dort etwas ändert, prüft `bytesInUse` — `test/undo_stack_test.dart` hält die Obergrenze für beide Canvas-Größen fest.

5. **`Curves.easeOutBack` überschwingt über beide Tween-Enden hinaus.** In einer `AnimatedContainer`-Dekoration darf deshalb kein `boxShadow` gegen `null` animiert werden: der Blur-Radius wird dabei negativ und `dart:ui` bricht ab. Stattdessen den Radius konstant lassen und nur die Deckkraft bewegen (`_selectionShadow` in `lib/widgets/tool_bar.dart`).

## Inhalte erweitern

**Neues Ausmalbild hinzufügen**

1. SVG nach `assets/coloring_pages/` legen — geschlossene Konturen, schwarze Linien auf transparentem Grund, sonst „läuft" die Füllung aus
2. Eintrag in `assets/coloring_pages/pages.json` ergänzen:
   ```json
   {
     "id": "cat",
     "title": "Katze",
     "titleEn": "Cat",
     "file": "cat.svg",
     "category": "Tiere",
     "categoryEn": "Animals"
   }
   ```
   Die deutsche `category` ist der stabile Schlüssel — an ihr hängen die Pastell-Tints im Picker (`_categoryTint` in `lib/gallery/page_picker_screen.dart`).
3. `flutter run` — Assets werden über den Ordner-Eintrag in der `pubspec.yaml` automatisch mitgenommen

**Neuen Sticker** in `lib/models/stamp.dart` (`kStamps`) eintragen, **neue Belohnung** in `lib/models/reward.dart` (`kRewards`). Dort steht auch der Hinweis, welche Emoji plattformübergreifend farbig rendern.

**Neue Szene** (Sticker-Welt): SVG nach `assets/scenes/` plus Eintrag in `scenes.json`.

**Neues Zahlenbild** („Malen nach Zahlen"): SVG wie ein normales Ausmalbild, dazu ein Sidecar `assets/coloring_pages/cbn/<id>.json` mit Palette und Beschriftungen. `test/cbn_pages_test.dart` prüft das Authoring end-to-end — jede Beschriftung muss in einer gültigen, einheitlich nummerierten Fläche liegen; der Test ist die Abnahme, nicht das Auge.

**Neue Tagesaufgabe** in `lib/models/daily_task.dart` (`kDailyTasks`) — die Liste wird zyklisch über das Datum adressiert, neue Einträge verschieben also die Zuordnung für alle folgenden Tage.

**Neues Jahreszeiten-Bild:** wie ein normales Ausmalbild, zusätzlich `"season"` im `pages.json`-Eintrag (einer der Schlüssel aus `kSeasonWindows` in `lib/models/coloring_page.dart`). `test/seasonal_pages_test.dart` prüft danach automatisch mit, dass die Datei existiert, rastert und geschlossene, füllbare Flächen hat.

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

Die Versionsnummer wird in der `pubspec.yaml` gepflegt: `version: 7.1.0+19` bedeutet Versionsname 7.1.0 und versionCode 19. Beide müssen bei jedem Store-Upload erhöht werden.

## Datenschutz

PixiePaint sammelt **keine** Daten. Alles bleibt auf dem Gerät: keine Internetverbindung, keine Analytics, keine Werbe-IDs, keine Accounts. Fotos werden ausschließlich lokal verarbeitet. Die vollständige Erklärung: [`docs/privacy-policy.md`](docs/privacy-policy.md).

| | |
|---|---|
| Android applicationId | `dev.rb.pixiepaint` |
| iOS Bundle Identifier | `dev.rb.pixiepaint.pixiepaint` |
| Berechtigungen | Fotobibliothek — nur beim Foto-Import bzw. -Export, jeweils hinter der Elternschranke |
| Internet | nein |
